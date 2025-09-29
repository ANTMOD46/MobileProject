import 'package:pocketbase/pocketbase.dart';

class Subject {
  final String id;
  final String name;
  final String code;
  final String? description;
  final int credits;
  final String? teacher;
  final String? image; // ใช้ file field จาก PocketBase โดยตรง

  Subject({
    required this.id,
    required this.name,
    required this.code,
    this.description,
    this.credits = 3,
    this.teacher,
    this.image,
  });

  factory Subject.fromRecord(RecordModel record) {
    return Subject(
      id: record.id,
      name: record.data['name'] as String,
      code: record.data['code'] as String,
      description: record.data['description'] as String?,
      credits: (record.data['credits'] as num?)?.toInt() ?? 3,
      teacher: record.data['teacher'] as String?,
      image: record.data['image'] as String?, // ใช้ field image
    );
  }
}
