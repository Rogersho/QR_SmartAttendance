class AppConstants {
  // Supabase Config
  static const String supabaseUrl = 'https://pfinevuhqqdksssbeixb.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBmaW5ldnVocXFka3Nzc2JlaXhiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjY5OTMxNDAsImV4cCI6MjA4MjU2OTE0MH0.2sVpilJPQcFdgdkaSQoGtVQpf8SzGv7fQh3MxoqV04w';

  // App Config
  static const String appName = 'QR Attendance';
  static const String defaultInstitution = 'University of Rwanda';

  // Proximity Config
  static const double maxDistanceInMeters =
      500.0; // Students must be within 0.5KM
}
