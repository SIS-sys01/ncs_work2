/// 1~12 과목 정보 데이터 모델
class SubjectModel {
  final int id;
  final String name;

  const SubjectModel({
    required this.id,
    required this.name,
  });

  factory SubjectModel.fromMap(Map<String, dynamic> map) {
    return SubjectModel(
      id: map['id'] as int,
      name: map['name'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }
}
