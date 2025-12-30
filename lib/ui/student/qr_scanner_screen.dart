import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../services/supabase_service.dart';
import '../../services/location_service.dart';
import '../../providers/auth_provider.dart';

class QRScannerScreen extends ConsumerStatefulWidget {
  final String courseId;
  final String courseName;

  const QRScannerScreen({
    super.key,
    required this.courseId,
    required this.courseName,
  });

  @override
  ConsumerState<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends ConsumerState<QRScannerScreen> {
  late final SupabaseService _supabaseService;
  final _locationService = LocationService();
  bool _isProcessing = false;
  final _backupCodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _supabaseService = ref.read(supabaseServiceProvider);
  }

  Future<void> _processAttendance(String code, {bool isBackup = false}) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      String qrSessionId; // This will hold the actual DB Row ID
      String? rotatingCode; // This is the secret code

      // 1. If it's a QR (not backup), parse the JSON payload
      if (!isBackup) {
        try {
          final payload = jsonDecode(code);
          if (payload['course_id'] != widget.courseId) {
            throw 'This QR code belongs to a different course';
          }
          // Use the static session_id (DB Row ID) if available
          qrSessionId = payload['session_id'];
          rotatingCode = payload['code'];
        } catch (e) {
          if (e is String) rethrow;
          throw 'Invalid QR code format';
        }
      } else {
        // for backup code, we don't know the sessionId from the code itself usually
        // but wait, we need the sessionId to submit attendance.
        // If we are using backup code, we assume the student is entering it for the CURRENT active session.
        // So we will look it up from Supabase active session below.
        qrSessionId = ''; // placeholder, will fill from response
      }

      // 2. Get current session from Supabase
      final response = await _supabaseService
          .watchSession(widget.courseId)
          .first;

      if (response.isEmpty) {
        throw 'No active session found for this course';
      }

      final sessionData = response.first;
      final serverQrCode =
          sessionData['qr_code']; // The active secret qr code in DB
      final serverBackupCode =
          sessionData['backup_code']; // The active backup code
      final expiresAt = DateTime.parse(sessionData['expires_at']);
      final teacherLat = sessionData['teacher_lat'] as double;
      final teacherLng = sessionData['teacher_lng'] as double;
      final sessionId = sessionData['id']; // correct DB Row ID

      // If we parsed a session ID from QR, verify it matches the active one
      if (!isBackup && qrSessionId != sessionId) {
        // This implies the QR is from a different (maybe old/expired) session row, or just wrong.
        throw 'Invalid session (ID mismatch)';
      }

      // 3. Validate Code & Expiry
      if (isBackup) {
        if (code != serverBackupCode) {
          throw 'Invalid backup code';
        }
      } else {
        // Validate the rotating secret
        if (rotatingCode != serverQrCode) {
          throw 'Invalid QR code (Expired or rotated)';
        }
      }

      if (DateTime.now().isAfter(expiresAt)) {
        throw 'Code has expired';
      }

      // 4. Verify Proximity
      final position = await _locationService.getCurrentPosition();
      if (position == null) {
        throw 'Location access required for verification';
      }

      final distance = _locationService.calculateDistance(
        position.latitude,
        position.longitude,
        teacherLat,
        teacherLng,
      );

      if (distance > AppConstants.maxDistanceInMeters) {
        throw 'Too far from teacher.\nDetected distance: ${distance.toStringAsFixed(1)}m\nLimit is: ${AppConstants.maxDistanceInMeters}m';
      }

      // 5. Submit Attendance
      final profile = ref.read(profileProvider).value;

      await _supabaseService.submitAttendance(
        courseId: widget.courseId,
        studentId: profile!.id,
        sessionId: sessionId,
        lat: position.latitude,
        lng: position.longitude,
      );

      if (mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Icon(
          Icons.check_circle,
          color: AppColors.success,
          size: 60,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Attendance Marked!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Successfully registered for ${widget.courseName}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Great!'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Scan QR - ${widget.courseName}')),
      body: Stack(
        children: [
          MobileScanner(
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  _processAttendance(barcode.rawValue!);
                  break;
                }
              }
            },
          ),

          // Overlay UI
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),

          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Column(
              children: [
                const Text(
                  'Facing issues with scanning?',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                TextButton(
                  onPressed: _showBackupCodeDialog,
                  style: TextButton.styleFrom(foregroundColor: Colors.white),
                  child: const Text('Enter Backup Code'),
                ),
              ],
            ),
          ),

          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  void _showBackupCodeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Backup Code'),
        content: TextField(
          controller: _backupCodeController,
          decoration: const InputDecoration(
            hintText: 'XXX-XXX-XXX-XXX',
            counterText: '',
          ),
          maxLength: 15, // Including dashes
          textCapitalization: TextCapitalization.characters,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final code = _backupCodeController.text.trim();
              if (code.isNotEmpty) {
                Navigator.pop(context);
                _processAttendance(code, isBackup: true);
              }
            },
            child: const Text('Verify'),
          ),
        ],
      ),
    );
  }
}
