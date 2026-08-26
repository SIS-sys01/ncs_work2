import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:ncs_work/data/models/question_model.dart';
import 'package:ncs_work/data/models/subject_model.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// 오프라인 SQLite 데이터베이스 제어 헬퍼
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('vocational_counselor2_v24.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // 1~12 과목 테이블
    await db.execute('''
      CREATE TABLE subjects (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL
      )
    ''');

    // 주관식 문제 테이블
    await db.execute('''
      CREATE TABLE questions (
        id TEXT PRIMARY KEY,
        subject_id INTEGER NOT NULL,
        subject_name TEXT NOT NULL,
        type TEXT NOT NULL,
        question_num INTEGER NOT NULL,
        question TEXT NOT NULL,
        answer TEXT NOT NULL,
        keywords TEXT,
        explanation TEXT,
        user_answer TEXT,
        last_score INTEGER,
        question_type TEXT,
        dynamic_options TEXT,
        cloze_text TEXT,
        FOREIGN KEY (subject_id) REFERENCES subjects (id)
      )
    ''');

    // 에셋 JSON 데이터 오프라인 마이그레이션
    await _migrateInitialData(db);
  }

  /// 에셋 JSON 파일에서 기본 주관식 데이터를 불러와 SQLite DB에 저장
  Future<void> _migrateInitialData(Database db) async {
    try {
      final String jsonString = await rootBundle.loadString('assets/data/subject3_questions.json');
      final data = json.decode(jsonString);

      final Batch batch = db.batch();

      // 과목 목록 저장
      if (data['subjects'] != null) {
        for (var s in data['subjects']) {
          batch.insert('subjects', {
            'id': s['id'],
            'name': s['name'],
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }

      // 주관식 문제 저장
      if (data['questions'] != null) {
        for (var q in data['questions']) {
          batch.insert('questions', {
            'id': q['id'],
            'subject_id': q['subject_id'],
            'subject_name': q['subject_name'],
            'type': q['type'],
            'question_num': q['question_num'],
            'question': q['question'],
            'answer': q['answer'] ?? '',
            'keywords': q['keywords'] ?? '',
            'explanation': q['explanation'] ?? '',
            'user_answer': null,
            'last_score': null,
            'question_type': q['question_type'],
            'dynamic_options': q['dynamic_options'] != null ? json.encode(q['dynamic_options']) : null,
            'cloze_text': q['cloze_text'],
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }

      await batch.commit(noResult: true);
    } catch (e) {
      // 로깅
    }
  }

  /// 전체 과목 목록 조회 (1~12과목)
  Future<List<SubjectModel>> getSubjects() async {
    final db = await instance.database;
    final result = await db.query('subjects', orderBy: 'id ASC');
    return result.map((json) => SubjectModel.fromMap(json)).toList();
  }

  /// 특정 과목 & 유형(internal/external) 주관식 문제 랜덤 셔플 10문항 조회
  Future<List<QuestionModel>> getQuestionsBySubjectAndType({
    required int subjectId,
    required String type,
    int limit = 10,
  }) async {
    final db = await instance.database;
    final result = await db.query(
      'questions',
      where: 'subject_id = ? AND type = ?',
      whereArgs: [subjectId, type],
      orderBy: 'RANDOM()', // 랜덤 셔플 출제
      limit: limit, // 요청대로 10문항 제한 출제
    );
    return result.map((json) => QuestionModel.fromMap(json)).toList();
  }

  /// 전 과목 통합 종합평가 주관식 문제 조회 (랜덤 셔플 10문항)
  Future<List<QuestionModel>> getRandomQuestions({int limit = 10}) async {
    final db = await instance.database;
    final result = await db.query(
      'questions',
      orderBy: 'RANDOM()',
      limit: limit,
    );
    return result.map((json) => QuestionModel.fromMap(json)).toList();
  }

  /// 사용자가 답안 작성 후 채점한 결과 업데이트
  Future<void> updateQuestionUserAnswer({
    required String questionId,
    required String userAnswer,
    required int lastScore,
  }) async {
    final db = await instance.database;
    await db.update(
      'questions',
      {
        'user_answer': userAnswer,
        'last_score': lastScore,
      },
      where: 'id = ?',
      whereArgs: [questionId],
    );
  }
}
