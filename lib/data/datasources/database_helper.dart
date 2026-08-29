import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:ncs_work/core/utils/question_pdf_service.dart';
import 'package:ncs_work/data/models/question_model.dart';
import 'package:ncs_work/data/models/subject_model.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

/// 오프라인 SQLite 데이터베이스 제어 헬퍼
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('vocational_counselor2_v32.db'); // DB 버전을 32로 강제 승격하여 다시 파싱
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
          final keywordData = q['keywords'];
          final parsedKeywords = keywordData is List ? keywordData.join(',') : (keywordData ?? '');

          batch.insert('questions', {
            'id': q['id'],
            'subject_id': q['subject_id'],
            'subject_name': q['subject_name'],
            'type': q['type'],
            'question_num': q['question_num'],
            'question': q['question'],
            'answer': q['answer'] ?? '',
            'keywords': parsedKeywords,
            'explanation': q['explanation'] ?? '',
            'user_answer': null,
            'last_score': null,
            'question_type': q['question_type'],
            'dynamic_options': q['dynamic_options'] != null ? json.encode(q['dynamic_options']) : null,
            'cloze_text': q['cloze_text'],
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }

      await _parsePdfsAndInsert(batch);

      await batch.commit(noResult: true);
    } catch (e) {
      // 로깅
    }
  }

  /// PDF 폴더의 문서를 자체 분석하여 자동으로 문제 데이터베이스를 추출해 쌓아두는 완전 자동화 엔진
  Future<void> _parsePdfsAndInsert(Batch batch) async {
    final Map<int, String> subjectNames = {
      1: '1직업상담 초기면담', 2: '2직업상담진단', 3: '3직업훈련상담', 4: '4직업상담행정',
      5: '5진로상담', 6: '6직업정보수집', 7: '7취업상담', 8: '8직업정보제공',
      9: '9직업복귀상담', 10: '10집단상담프로그램 운영', 11: '11취업지원 행사운영', 12: '12직업상담서비스 협업체계구축'
    };

    for (int subjectId = 1; subjectId <= 12; subjectId++) {
      for (String type in ['internal', 'external']) {
        final pdfAssets = await QuestionPdfService.getPdfAssets(subjectId: subjectId, type: type);
        for (String pdfPath in pdfAssets) {
          try {
            final ByteData data = await rootBundle.load(pdfPath);
            final PdfDocument document = PdfDocument(inputBytes: data.buffer.asUint8List());
            final String text = PdfTextExtractor(document).extractText();
            document.dispose();

            // 파일 텍스트 전문에서 정답 분리 추적
            // Q01. ... 정답: ... 키워드: ... 구조로 쪼갬
            final qMatches = RegExp(r'(Q\d+\..*?)(?=Q\d+\.|$)', dotAll: true).allMatches(text);
            for (var match in qMatches) {
               String chunk = match.group(1) ?? '';
               
               // 띄어쓰기나 괄호 대응을 위한 지능형 정규식 적용 (예: [정 답], 정답 :, 정답)
               final ansMatch = RegExp(r'\[?\s*정\s*답\s*\]?\s*:?').firstMatch(chunk);
               String questionText = '';
               String answerText = '';
               String keywordText = '';

               if (ansMatch != null) {
                 int ansIdx = ansMatch.start; // 지문이 끝나는 지점
                 questionText = chunk.substring(0, ansIdx).trim();
                 
                 final kwdMatch = RegExp(r'\[?\s*키\s*워\s*드\s*\]?\s*:?').firstMatch(chunk);
                 if (kwdMatch != null && kwdMatch.start > ansMatch.end) {
                    answerText = chunk.substring(ansMatch.end, kwdMatch.start).trim();
                    keywordText = chunk.substring(kwdMatch.end).trim();
                 } else {
                    answerText = chunk.substring(ansMatch.end).trim();
                 }
               } else {
                 questionText = chunk.trim();
               }

               final numMatch = RegExp(r'Q(\d+)\.').firstMatch(questionText);
               int qNum = numMatch != null ? int.tryParse(numMatch.group(1)!) ?? 0 : 0;
               if (qNum == 0) continue;

               final questionId = '${subjectId}_${type}_$qNum';
               batch.insert('questions', {
                 'id': questionId,
                 'subject_id': subjectId,
                 'subject_name': subjectNames[subjectId] ?? '$subjectId과목',
                 'type': type,
                 'question_num': qNum,
                 'question': questionText,
                 'answer': answerText,
                 'keywords': keywordText,
                 'explanation': '',
                 'user_answer': null,
                 'last_score': null,
                 'question_type': 'subjective',
                 'dynamic_options': null,
                 'cloze_text': null,
               }, conflictAlgorithm: ConflictAlgorithm.replace);
            }
          } catch (e) {
            // PDF 읽기 오류 무시 후 계속 진행
          }
        }
      }
    }
  }

  /// 전체 과목 목록 조회 (문제 수 집계 포함)
  Future<List<SubjectModel>> getSubjects() async {
    final db = await instance.database;
    final result = await db.rawQuery('''
      SELECT s.id, s.name, 
        SUM(CASE WHEN q.type = 'internal' THEN 1 ELSE 0 END) as internal_count,
        SUM(CASE WHEN q.type = 'external' THEN 1 ELSE 0 END) as external_count
      FROM subjects s
      LEFT JOIN questions q ON s.id = q.subject_id
      GROUP BY s.id
      ORDER BY s.id ASC
    ''');
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
