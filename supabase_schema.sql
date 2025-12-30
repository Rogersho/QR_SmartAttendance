-- Supabase Schema for QR Attendance App

-- Drop existing tables (Reversed order for FKs)
DROP TABLE IF EXISTS attendance_records;
DROP TABLE IF EXISTS attendance_sessions;
DROP TABLE IF EXISTS enrollments;
DROP TABLE IF EXISTS courses;
DROP TABLE IF EXISTS classes;
DROP TABLE IF EXISTS profiles;

-- Profiles table
CREATE TABLE IF NOT EXISTS profiles (
  id UUID REFERENCES auth.users ON DELETE CASCADE PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  full_name TEXT NOT NULL,
  role TEXT NOT NULL CHECK (role IN ('teacher', 'student')),
  title TEXT, 
  institution TEXT DEFAULT 'University of Rwanda',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Classes table
CREATE TABLE IF NOT EXISTS classes (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  teacher_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  name TEXT NOT NULL,
  description TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Courses table
CREATE TABLE IF NOT EXISTS courses (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  class_id UUID REFERENCES classes(id) ON DELETE CASCADE NOT NULL,
  name TEXT NOT NULL,
  code TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enrollments table
CREATE TABLE IF NOT EXISTS enrollments (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  student_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  class_id UUID REFERENCES classes(id) ON DELETE CASCADE NOT NULL,
  enrolled_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(student_id, class_id)
);

-- Attendance Sessions (Replaces Firebase Sessions)
-- Real-time rotation happens here
CREATE TABLE IF NOT EXISTS attendance_sessions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  course_id UUID REFERENCES courses(id) ON DELETE CASCADE NOT NULL,
  qr_code TEXT NOT NULL,
  backup_code TEXT NOT NULL,
  teacher_lat DOUBLE PRECISION NOT NULL,
  teacher_lng DOUBLE PRECISION NOT NULL,
  attendance_date DATE DEFAULT CURRENT_DATE,
  expires_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Attendance Records (Replaces Firebase Attendance)
CREATE TABLE IF NOT EXISTS attendance_records (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  course_id UUID REFERENCES courses(id) ON DELETE CASCADE NOT NULL,
  student_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  session_id UUID REFERENCES attendance_sessions(id) ON DELETE SET NULL,
  lat DOUBLE PRECISION NOT NULL,
  lng DOUBLE PRECISION NOT NULL,
  status TEXT DEFAULT 'present',
  attendance_date DATE DEFAULT CURRENT_DATE,
  marked_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(student_id, session_id) -- One entry per student per session
);

-- Enable RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE classes ENABLE ROW LEVEL SECURITY;
ALTER TABLE courses ENABLE ROW LEVEL SECURITY;
ALTER TABLE enrollments ENABLE ROW LEVEL SECURITY;
ALTER TABLE attendance_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE attendance_records ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Public profiles are viewable by everyone" ON profiles FOR SELECT USING (true);
CREATE POLICY "Users can update their own profile" ON profiles FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Classes viewable by everyone" ON classes FOR SELECT USING (true);
CREATE POLICY "Teachers can manage classes" ON classes FOR ALL USING (teacher_id = auth.uid());

CREATE POLICY "Courses viewable by everyone" ON courses FOR SELECT USING (true);
CREATE POLICY "Teachers can manage courses" ON courses FOR ALL USING (
    EXISTS (SELECT 1 FROM classes WHERE classes.id = courses.class_id AND classes.teacher_id = auth.uid())
);

CREATE POLICY "Enrollments viewable by everyone" ON enrollments FOR SELECT USING (true);
CREATE POLICY "Students can self-enroll" ON enrollments FOR INSERT WITH CHECK (auth.uid() = student_id);
CREATE POLICY "Teachers can view class enrollments" ON enrollments FOR SELECT USING (
    EXISTS (SELECT 1 FROM classes WHERE classes.id = enrollments.class_id AND classes.teacher_id = auth.uid())
);

-- Sessions Policies
CREATE POLICY "Sessions viewable by everyone" ON attendance_sessions FOR SELECT USING (true);
CREATE POLICY "Teachers can manage sessions" ON attendance_sessions FOR ALL USING (
  EXISTS (
    SELECT 1 FROM courses 
    JOIN classes ON classes.id = courses.class_id 
    WHERE courses.id = attendance_sessions.course_id AND classes.teacher_id = auth.uid()
  )
);

-- Records Policies
CREATE POLICY "Students can view their own records" ON attendance_records FOR SELECT USING (student_id = auth.uid());
CREATE POLICY "Teachers can view records for their courses" ON attendance_records FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM courses 
    JOIN classes ON classes.id = courses.class_id 
    WHERE courses.id = attendance_records.course_id AND classes.teacher_id = auth.uid()
  )
);
CREATE POLICY "Students can insert records" ON attendance_records FOR INSERT WITH CHECK (auth.uid() = student_id);
CREATE POLICY "Teachers can insert records" ON attendance_records FOR INSERT WITH CHECK (
  EXISTS (
    SELECT 1 FROM courses 
    JOIN classes ON classes.id = courses.class_id 
    WHERE courses.id = attendance_records.course_id AND classes.teacher_id = auth.uid()
  )
);

-- Enable Realtime for specific tables
-- Note: This requires the supabase_realtime publication to exist (default in Supabase)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_publication WHERE pubname = 'supabase_realtime') THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE attendance_sessions;
    ALTER PUBLICATION supabase_realtime ADD TABLE attendance_records;
  END IF;
END $$;

-- Profile trigger to automatically create a profile after signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, full_name, role, title, institution)
  VALUES (
    new.id,
    new.email,
    new.raw_user_meta_data->>'full_name',
    new.raw_user_meta_data->>'role',
    new.raw_user_meta_data->>'title',
    COALESCE(new.raw_user_meta_data->>'institution', 'University of Rwanda')
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger execution
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();
