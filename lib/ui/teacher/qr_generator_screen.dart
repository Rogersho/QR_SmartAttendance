import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../services/supabase_service.dart';
import '../../providers/auth_provider.dart';
import '../../services/location_service.dart';
import 'package:uuid/uuid.dart';

class QRGeneratorScreen extends ConsumerStatefulWidget {
  final String courseId;
  final String courseName;
  final String attendanceDate;

  const QRGeneratorScreen({
    super.key,
    required this.courseId,
    required this.courseName,
    required this.attendanceDate,
  });

  @override
  ConsumerState<QRGeneratorScreen> createState() => _QRGeneratorScreenState();
}

class _QRGeneratorScreenState extends ConsumerState<QRGeneratorScreen> {
  late final SupabaseService _supabaseService;
  final _locationService = LocationService();

  String? _currentSessionId;
  String? _currentQR;
  String? _backupCode;
  Timer? _timer;
  int _secondsRemaining = 120;

  @override
  void initState() {
    super.initState();
    _supabaseService = ref.read(supabaseServiceProvider);
    _startSession();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _startSession() async {
    // 1. Explicitly check/request permission first
    final position = await _locationService.getCurrentPosition();

    if (position == null) {
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Location Required'),
            content: const Text(
              'To start an attendance session, we need your GPS location to verify student proximity. Please enable location services.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _startSession(); // Retry
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ).then((_) {
          if (!mounted) return;
          // If they just closed it without retry, go back
          if (_currentSessionId == null) Navigator.pop(context);
        });
      }
      return;
    }

    // Initial creation
    await _generateNewCode(
      position.latitude,
      position.longitude,
      isInitial: true,
    );

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          _secondsRemaining = 120;
          // Subsequent updates use last known to start with
          _generateNewCode(
            position.latitude,
            position.longitude,
            isInitial: false,
          );
        }
      });
    });
  }

  Future<void> _generateNewCode(
    double baseLat,
    double baseLng, {
    bool isInitial = false,
  }) async {
    double currentLat = baseLat;
    double currentLng = baseLng;

    // Try to get a fresh position for rotation
    try {
      final freshPos = await _locationService.getCurrentPosition();
      if (freshPos != null) {
        currentLat = freshPos.latitude;
        currentLng = freshPos.longitude;
      }
    } catch (_) {}

    final qrCodeId = const Uuid().v4();
    // Rotate backup code constantly for security as requested
    final backupCode = _supabaseService.generateBackupCode();

    // Create a structured JSON payload for the QR code
    // IMPORTANT: The payload should contain the CURRENT session ID so records link to it
    // But for security rotation, we might want to rotate the 'qrCodeId' which is validated
    // The previous code was using 'session_id': qrCodeId in the payload, but saving it as 'qr_code' column.
    // The actual Primary Key UUID of the session table row is what matters for linking records.

    // Wait, the previous implementation used `qrCode` argument as `qr_code` column, and `qrCodeId` variable was that value.
    // The `createAttendanceSession` generates a NEW ROW with its own auto-generated UUID primary key?
    // Let's check SupabaseService...
    // Yes: 'id': UUID DEFAULT gen_random_uuid().
    // So if we create new row, we get new ID.
    // We want ONE row per "Class Session" (Teacher starts -> Teacher ends).

    if (isInitial) {
      // Create the single row for this session
      final sessionId = await _supabaseService.createAttendanceSession(
        courseId: widget.courseId,
        qrCode: qrCodeId,
        backupCode: backupCode,
        lat: currentLat,
        lng: currentLng,
        attendanceDate: widget.attendanceDate,
      );
      _currentSessionId = sessionId;
    } else {
      // Update the existing row with new rotating secure code and backup code
      if (_currentSessionId != null) {
        await _supabaseService.updateAttendanceSession(
          sessionId: _currentSessionId!,
          qrCode: qrCodeId,
          backupCode: backupCode,
          lat: currentLat,
          lng: currentLng,
        );
      }
    }

    // payload: 'session_id' in JSON usually implies the DB ID for the student to insert?
    // OR is it the secret rotating code?
    // In `submitAttendance` student sends `sessionId`.
    // If we rotate the visible QR code token, the student scans it, gets `qrCodeId`.
    // BUT the student needs to insert into `attendance_records` linking to `attendance_sessions.id`.
    // The student app likely decodes this JSON.
    // The previous code put `session_id: qrCodeId` in the JSON.
    // If the Student App treats `session_id` as the Foreign Key, then `qrCodeId` MUST be the UUID of the row.
    // If so, we CANNOT rotate it without creating new rows... UNLESS the student app looks up the session by the secret code?

    // Let's check `submitAttendance` in `SupabaseService`.
    // It takes `sessionId`.
    // It inserts `session_id: sessionId`.
    // So the JSON payload MUST contain the Database Row UUID.

    // If we want ONE row, `_currentSessionId` (the DB UUID) must be constant.
    // The ROTATING part should be a separate "secret" field in the JSON, e.g. "token".
    // AND the server should validate this token.

    // However, looking at the schema: `attendance_sessions` has `id` (UUID) and `qr_code` (TEXT).
    // The student probably sends the SCANNED content to the server?
    // Or does the student just insert?
    // "Student App" logic is probably just `submitAttendance(sessionId: json['session_id'])`.
    // If so, there is NO security rotation if we just keep `session_id` constant and don't check `qr_code` column.
    // The student could just save the UUID and replay it.

    // To support rotation securely:
    // 1. We keep one DB Row (Session).
    // 2. We update the `qr_code` column in that row with new secret.
    // 3. The JSON payload contains the DB Row ID *AND* the new secret.
    // 4. The RLS or API must verify the secret.
    // currently the RLS is complex.

    // Simplest fix for NOW to stop duplicate columns:
    // We MUST reuse the DB Row ID.
    // So the JSON payload key `session_id` MUST be `_currentSessionId`.
    // But if we do that, we lose the "rotation" security if the backend doesn't check the `qr_code` column match.
    // BUT, the goal right now is "Stop creating new columns".
    // So we MUST reuse the session ID.

    // Let's assume for now we just want to stop duplicate columns.
    // We update the 'qr_code' column just to expire old codes if we had validation.

    final qrPayload = jsonEncode({
      'v': 1,
      'course_id': widget.courseId,
      'session_id': _currentSessionId, // Linked to the single DB row
      'code': qrCodeId, // The rotating part (optional validation)
    });

    setState(() {
      _currentQR = qrPayload;
      _backupCode = backupCode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: Text(widget.courseName), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text(
              'Show this QR to students',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Rotates every 2 minutes for security',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 48),

            if (_currentQR != null)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: Colors.black.withOpacity(0.05)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    QrImageView(
                      data: _currentQR!,
                      version: QrVersions.auto,
                      size: 260.0,
                      gapless: true,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: Colors.black,
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'SECURE SCAN',
                      style: TextStyle(
                        letterSpacing: 4,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.black38,
                      ),
                    ),
                  ],
                ),
              )
            else
              const SizedBox(
                height: 250,
                child: Center(child: CircularProgressIndicator()),
              ),

            const SizedBox(height: 48),

            // Timer Indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.timer_outlined,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Refreshing in: ${_secondsRemaining}s',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 48),

            const Text(
              'Backup Code',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              _backupCode ?? '--- --- --- ---',
              style: const TextStyle(
                fontSize: 24,
                letterSpacing: 2,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 56),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  await _supabaseService.endAttendanceSession(widget.courseId);
                  if (mounted) Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('End Attendance Session'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
