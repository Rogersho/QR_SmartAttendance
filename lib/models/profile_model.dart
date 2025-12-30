enum UserRole {
  teacher,
  student;

  String get name => toString().split('.').last;

  static UserRole fromString(String role) {
    return UserRole.values.firstWhere(
      (e) => e.name == role.toLowerCase(),
      orElse: () => UserRole.student,
    );
  }
}

class ProfileModel {
  final String id;
  final String email;
  final String fullName;
  final UserRole role;
  final String? title;
  final String institution;
  final DateTime createdAt;

  ProfileModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.title,
    required this.institution,
    required this.createdAt,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'],
      email: json['email'],
      fullName: json['full_name'],
      role: UserRole.fromString(json['role']),
      title: json['title'],
      institution: json['institution'] ?? 'University of Rwanda',
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'role': role.name,
      'title': title,
      'institution': institution,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
