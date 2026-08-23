/// 주관식 문제 및 답안 데이터 모델
class QuestionModel {
  final String id;
  final int subjectId;
  final String subjectName;
  final String type; // 'internal' 또는 'external'
  final int questionNum;
  final String question;
  final String answer;
  final String keywords;
  final String explanation;
  final String? userAnswer;
  final int? lastScore;

  const QuestionModel({
    required this.id,
    required this.subjectId,
    required this.subjectName,
    required this.type,
    required this.questionNum,
    required this.question,
    required this.answer,
    required this.keywords,
    required this.explanation,
    this.userAnswer,
    this.lastScore,
  });

  factory QuestionModel.fromMap(Map<String, dynamic> map) {
    return QuestionModel(
      id: map['id'] as String,
      subjectId: map['subject_id'] as int,
      subjectName: map['subject_name'] as String,
      type: map['type'] as String,
      questionNum: map['question_num'] as int,
      question: map['question'] as String,
      answer: map['answer'] as String,
      keywords: map['keywords'] as String? ?? '',
      explanation: map['explanation'] as String? ?? '',
      userAnswer: map['user_answer'] as String?,
      lastScore: map['last_score'] as int?,
    );
  }

  /// 문제 지문 앞머리의 모든 태그([요소/기술], [8가지 나열], Q1-변형1: 등)를 100% 깔끔하게 제거한 순수 지문
  String get formattedQuestion {
    return question
        .replaceAll(RegExp(r'^Q\d+\.\s*'), '')
        .replaceAll(RegExp(r'^\[[^\]]+\]\s*'), '')
        .replaceAll(RegExp(r'^Q\d+[-_]?변형\d+:\s*'), '')
        .replaceAll(RegExp(r'\[Q\d+[-_]?변형\d+:\s*'), '')
        .replaceAll(RegExp(r'^\[[^\]]+\]\s*'), '')
        .trim();
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'subject_id': subjectId,
      'subject_name': subjectName,
      'type': type,
      'question_num': questionNum,
      'question': question,
      'answer': answer,
      'keywords': keywords,
      'explanation': explanation,
      'user_answer': userAnswer,
      'last_score': lastScore,
    };
  }

  QuestionModel copyWith({
    String? userAnswer,
    int? lastScore,
  }) {
    return QuestionModel(
      id: id,
      subjectId: subjectId,
      subjectName: subjectName,
      type: type,
      questionNum: questionNum,
      question: question,
      answer: answer,
      keywords: keywords,
      explanation: explanation,
      userAnswer: userAnswer ?? this.userAnswer,
      lastScore: lastScore ?? this.lastScore,
    );
  }
}
