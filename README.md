# 🎯 SmartAttend: Real-Time QR Attendance System

SmartAttend is a sophisticated, mobile-first attendance management solution designed to eliminate proxy attendance and automate the recording process using **Dynamic QR Codes**, **GPS Verification**, and **Real-Time Data Streaming**.

Built with **Flutter** and **Supabase**, it provides a seamless and secure experience for both educators and students.

---

## ✨ Key Features

### 🛡️ For Teachers
*   **Dynamic QR Generation**: Secure QR codes that rotate every 2 minutes to prevent remote sharing.
*   **Real-Time Analytics**: Live dashboard showing student arrivals as they scan—no page refreshes needed.
*   **Proximity Enforcement**: Automatically verifies that students are physically present in the classroom via GPS.
*   **Manual Overrides**: Ability to mark students present/absent manually or delete entire sessions.
*   **Professional Reports**: Generate and export attendance data as clean, colored PDF reports.

### 📱 For Students
*   **Fast Scanning**: Quick QR code scanning for instant attendance registration.
*   **Personal Stats**: Real-time view of attendance percentages and total classes attended.
*   **Backup Entry**: Support for secure backup codes if the camera has issues.

---

## 🚀 Technology Stack

*   **Frontend**: [Flutter](https://flutter.dev) (Multi-platform support)
*   **Backend**: [Supabase](https://supabase.com) (PostgreSQL Database, Auth, and Real-time)
*   **State Management**: [Riverpod](https://riverpod.dev)
*   **Location Services**: [Geolocator](https://pub.dev/packages/geolocator)
*   **PDF Generation**: [pdf](https://pub.dev/packages/pdf) & [printing](https://pub.dev/packages/printing)

---

## 🛠️ Getting Started

### Prerequisites
*   Flutter SDK (Stable channel)
*   A Supabase Project

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/Rogersho/QR_SmartAttendance.git
   cd QR_SmartAttendance
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Database Setup**
   *   Go to your Supabase SQL Editor.
   *   Copy the contents of `supabase_schema.sql` (found in the root directory).
   *   Paste and run the script to create all tables, triggers, and RLS policies.

4. **Configuration**
   *   Update your Supabase credentials in `lib/core/constants/app_constants.dart`.

5. **Run the app**
   ```bash
   flutter run
   ```

---

## 📐 Architecture & Security

### Secure Proximity Check
The system uses the Haversine formula to calculate the distance between the teacher's starting location and the student's scan location. If the distance exceeds the configurable limit (default: 500m), the transaction is rejected.

### Row Level Security (RLS)
Data integrity is maintained through PostgreSQL RLS:
*   **Students** can only view their own attendance records.
*   **Teachers** have full management rights over their respective class sessions.

---

## 📄 License
This project is for educational purposes. Feel free to use and modify it for your own institutional needs.

---
*Created with ❤️ for smarter classrooms.*
