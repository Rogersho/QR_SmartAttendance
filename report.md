# SmartAttend: Real-Time QR Attendance System Report

## 1. Project Overview
SmartAttend is a modern attendance management system built using **Flutter** and **Supabase**. It streamlines the process of tracking student attendance through dynamic QR code scanning and geolocation verification. The system differentiates between "Teacher" and "Student" roles, providing tailored dashboards for real-time monitoring and reporting.

**Key Objectives:**
*   Eliminate proxy attendance using secure, rotating QR codes.
*   Verify student presence using physical location (GPS).
*   Provide real-time statistics to teachers without page reloads.
*   Generate professional PDF attendance reports.

---

## 2. System Architecture

The application follows a clean architecture using **Riverpod** for state management and **Supabase** as the backend-as-a-service (BaaS).

### 2.1 Technology Stack
*   **Frontend**: Flutter (Mobile & Web)
*   **Backend & Database**: Supabase (PostgreSQL)
*   **Authentication**: Supabase Auth
*   **State Management**: Flutter Riverpod
*   **Real-time Features**: Supabase Realtime (Streams)

### 2.2 Data Flow
1.  **Teacher** initiates a session -> Supabase creates a session record.
2.  **Teacher's App** regenerates the QR code secret every 2 minutes -> Updates Supabase.
3.  **Student** scans QR -> App decodes secret, checks GPS location, and verifies with Supabase.
4.  **Supabase** confirms validity -> Inserts attendance record.
5.  **Teacher's Dashboard** listens to database changes -> Automatically updates the attendance list.

---

## 3. Database Schema

The database is designed with standard relational principles. Below is an overview of the key tables:

```sql
-- Profiles: Stores user info and roles (teacher/student)
CREATE TABLE profiles (
  id UUID REFERENCES auth.users PRIMARY KEY,
  role TEXT NOT NULL CHECK (role IN ('teacher', 'student')),
  institution TEXT DEFAULT 'University of Rwanda',
  ...
);

-- Attendance Sessions: Active class sessions with rotating security codes
CREATE TABLE attendance_sessions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  course_id UUID REFERENCES courses(id),
  qr_code TEXT NOT NULL,         -- The secret rotating key
  backup_code TEXT NOT NULL,     -- The backup manual entry key
  teacher_lat DOUBLE PRECISION,  -- Geolocation center
  teacher_lng DOUBLE PRECISION,
  expires_at TIMESTAMPTZ,        -- Code expiry time
  ...
);

-- Attendance Records: Individual student attendance entries
CREATE TABLE attendance_records (
  student_id UUID REFERENCES profiles(id),
  session_id UUID REFERENCES attendance_sessions(id),
  lat DOUBLE PRECISION,
  lng DOUBLE PRECISION,
  UNIQUE(student_id, session_id) -- Ensures one record per session
);
```

---

## 4. Key Features & Implementation

### 4.1 Secure Dynamic QR Codes
To prevent students from sharing QR codes remotely, the system uses a **Time-based Rotation** mechanism.
*   **How it works**: Every 2 minutes, the teacher's app generates a new UUID (`code`) and updates the `attendance_sessions` table.
*   **Security**: The JSON payload in the QR code contains the *Session ID* (permanent) and the *Code* (rotating). The student's scanner verifies both against the server.

**Code Snippet (Teacher Side - Rotation Logic):**
```dart
Future<void> _generateNewCode() async {
  final qrCodeId = const Uuid().v4(); // New secret
  final backupCode = _supabaseService.generateBackupCode(); // New backup

  // Update backend with new secure tokens
  await _supabaseService.updateAttendanceSession(
    sessionId: _currentSessionId!,
    qrCode: qrCodeId,
    backupCode: backupCode,
  );

  setState(() {
    _currentQR = jsonEncode({
      'v': 1,
      'session_id': _currentSessionId,
      'code': qrCodeId
    });
  });
}
```

### 4.2 Geo-Fencing Verification
Attendance is only marked if the student is physically close to the teacher.
*   **Teacher**: Captures GPS location when starting the session.
*   **Student**: Captures GPS location when scanning.
*   **Validation**: The system calculates the distance (Haversine formula). If > 50 meters, attendance is rejected.

### 4.3 Real-Time Updates (Streams)
The application avoids manual refreshes by using Supabase Streams. The UI automatically rebuilds when data changes.

**Code Snippet (Provider Definition):**
```dart
final courseSessionsProvider = StreamProvider.family<List<Map<String, dynamic>>, String>((ref, courseId) {
  // Listen to changes in 'attendance_sessions' table
  return ref.watch(supabaseServiceProvider).streamCourseSessions(courseId);
});
```

### 4.4 PDF Reporting
Teachers can generate official attendance reports. The PDF generator was customized to include visual indicators (✔ / ✖) for better readability.

**Code Snippet (PDF Cell Generation):**
```dart
pw.Text(
  isPresent ? "V" : "X",
  style: pw.TextStyle(
    color: isPresent ? PdfColors.green : PdfColors.red,
    fontWeight: pw.FontWeight.bold,
  ),
)
```

---

## 5. Security & Row Level Security (RLS)
Supabase RLS policies enforce data access at the database level:
*   **Teachers** can only manage classes and sessions they created.
*   **Students** can only view their own attendance records.
*   **Students** can only insert records for themselves (`auth.uid() = student_id`).

---

## 6. Challenges & Solutions

| Challenge | Solution |
| :--- | :--- |
| **Proxy Attendance** | Implemented dynamic QR codes that change every 2 minutes and enforce GPS distance checks. |
| **Duplicate Sessions** | Refactored logic to *update* the existing session row instead of creating new rows on every QR refresh, converting the database constraint to `UNIQUE(student_id, session_id)`. |
| **Web PDF Support** | Replaced `open_file_plus` with the `printing` package and used standard fonts/colors instead of unsupported unicode icons. |
| **Real-time Latency** | Switched from `FutureProvider` to `StreamProvider` in Riverpod to subscribe to database changes instantly. |

---

## 7. Conclusion
SmartAttend successfully demonstrates a secure, real-time, and user-friendly attendance solution. By leveraging the power of Flutter and Supabase, it provides a seamless experience for both teachers and students, automating data collection and reporting while maintaining high data integrity.
