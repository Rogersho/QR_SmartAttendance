class ClassModel {
  final String id;
  final String teacherId;
  final String name;
  final String? description;
  final DateTime createdAt;

  ClassModel({
    required this.id,
    required this.teacherId,
    required this.name,
    this.description,
    required this.createdAt,
  });

  factory ClassModel.fromJson(Map<String, dynamic> json) {
    return ClassModel(
      id: json['id'],
      teacherId: json['teacher_id'],
      name: json['name'],
      description: json['description'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'teacher_id': teacherId,
      'name': name,
      'description': description,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class CourseModel {
  final String id;
  final String classId;
  final String name;
  final String? code;
  final DateTime createdAt;

  CourseModel({
    required this.id,
    required this.classId,
    required this.name,
    this.code,
    required this.createdAt,
  });

  factory CourseModel.fromJson(Map<String, dynamic> json) {
    return CourseModel(
      id: json['id'],
      classId: json['class_id'],
      name: json['name'],
      code: json['code'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'class_id': classId,
      'name': name,
      'code': code,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
