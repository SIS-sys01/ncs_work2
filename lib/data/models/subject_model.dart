/// 1~12 과목 정보 데이터 모델
class SubjectModel {
  final int id;
  final String name;
  final int internalCount;
  final int externalCount;

  const SubjectModel({
    required this.id,
    required this.name,
    this.internalCount = 0,
    this.externalCount = 0,
  });

  factory SubjectModel.fromMap(Map<String, dynamic> map) {
    return SubjectModel(
      id: map['id'] as int,
      name: map['name'] as String,
      internalCount: map['internal_count'] as int? ?? 0,
      externalCount: map['external_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }
}
