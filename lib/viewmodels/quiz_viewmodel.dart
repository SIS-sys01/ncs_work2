import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ncs_work/core/utils/diff_engine.dart';
import 'package:ncs_work/data/datasources/database_helper.dart';
import 'package:ncs_work/data/models/question_model.dart';

/// 주관식 풀이 화면의 상태 클래스
class QuizState {
  final List<QuestionModel> questions;
  final int currentIndex;
  final String currentInputText;
  final bool isSubmitted;
  final int matchScore;
  final bool isLoading;
  final int? currentSubjectId;
  final String? currentType;

  const QuizState({
    this.questions = const [],
    this.currentIndex = 0,
    this.currentInputText = '',
    this.isSubmitted = false,
    this.matchScore = 0,
    this.isLoading = false,
    this.currentSubjectId,
    this.currentType,
  });

  QuestionModel? get currentQuestion =>
      questions.isNotEmpty && currentIndex < questions.length ? questions[currentIndex] : null;

  bool get isLastQuestion => currentIndex == questions.length - 1;

  QuizState copyWith({
    List<QuestionModel>? questions,
    int? currentIndex,
    String? currentInputText,
    bool? isSubmitted,
    int? matchScore,
    bool? isLoading,
    int? currentSubjectId,
    String? currentType,
  }) {
    return QuizState(
      questions: questions ?? this.questions,
      currentIndex: currentIndex ?? this.currentIndex,
      currentInputText: currentInputText ?? this.currentInputText,
      isSubmitted: isSubmitted ?? this.isSubmitted,
      matchScore: matchScore ?? this.matchScore,
      isLoading: isLoading ?? this.isLoading,
      currentSubjectId: currentSubjectId ?? this.currentSubjectId,
      currentType: currentType ?? this.currentType,
    );
  }
}

/// 주관식 퀴즈 상태 관리자 (MVVM ViewModel)
class QuizNotifier extends Notifier<QuizState> {
  @override
  QuizState build() {
    return const QuizState();
  }

  /// 특정 과목 및 평가 유형(내부/외부) 주관식 문제 로드 (항상 깨끗하게 세션 리셋)
  Future<void> loadQuestions({
    required int subjectId,
    required String type,
  }) async {
    state = state.copyWith(isLoading: true);

    final rawQuestions = await DatabaseHelper.instance.getQuestionsBySubjectAndType(
      subjectId: subjectId,
      type: type,
      limit: 10,
    );

    // 이전 작성 답변 초기화 처리 (새 세션 리셋)
    final freshQuestions = rawQuestions.map((q) => q.copyWith(userAnswer: '')).toList();

    state = QuizState(
      questions: freshQuestions,
      currentIndex: 0,
      currentInputText: '',
      isSubmitted: false,
      matchScore: 0,
      isLoading: false,
      currentSubjectId: subjectId,
      currentType: type,
    );
  }

  /// 현재 과목/유형 문제지를 새로운 10문제 무작위 셔플로 리셋하여 새로 시작
  Future<void> resetSession() async {
    final sId = state.currentSubjectId;
    final type = state.currentType;

    if (sId != null && type != null) {
      await loadQuestions(subjectId: sId, type: type);
    } else {
      await loadRandomQuestions();
    }
  }

  /// 전 과목 종합평가 문제 로드 (항상 깨끗하게 세션 리셋)
  Future<void> loadRandomQuestions() async {
    state = state.copyWith(isLoading: true);

    final rawQuestions = await DatabaseHelper.instance.getRandomQuestions();
    final freshQuestions = rawQuestions.map((q) => q.copyWith(userAnswer: '')).toList();

    state = QuizState(
      questions: freshQuestions,
      currentIndex: 0,
      currentInputText: '',
      isSubmitted: false,
      matchScore: 0,
      isLoading: false,
      currentSubjectId: null,
      currentType: null,
    );
  }

  /// 사용자 입력값 업데이트
  void updateInputText(String text) {
    state = state.copyWith(currentInputText: text);
  }

  /// 채점 실행 및 결과 저장
  Future<void> submitAnswer() async {
    final currentQ = state.currentQuestion;
    if (currentQ == null) return;

    final score = DiffEngine.calculateMatchScore(currentQ.answer, state.currentInputText);

    // DB에 사용자 답변 및 점수 업데이트
    await DatabaseHelper.instance.updateQuestionUserAnswer(
      questionId: currentQ.id,
      userAnswer: state.currentInputText,
      lastScore: score,
    );

    // 현재 목록의 모델에도 동기화
    final updatedList = List<QuestionModel>.from(state.questions);
    updatedList[state.currentIndex] = currentQ.copyWith(
      userAnswer: state.currentInputText,
      lastScore: score,
    );

    state = state.copyWith(
      questions: updatedList,
      isSubmitted: true,
      matchScore: score,
    );
  }

  /// 다음 문제로 이동
  void nextQuestion() {
    if (state.isLastQuestion) return;

    final nextIndex = state.currentIndex + 1;
    final nextQ = state.questions[nextIndex];

    state = state.copyWith(
      currentIndex: nextIndex,
      currentInputText: nextQ.userAnswer ?? '',
      isSubmitted: nextQ.userAnswer?.isNotEmpty ?? false,
      matchScore: nextQ.userAnswer?.isNotEmpty ?? false
          ? DiffEngine.calculateMatchScore(nextQ.answer, nextQ.userAnswer!)
          : 0,
    );
  }

  /// 이전 문제로 이동
  void previousQuestion() {
    if (state.currentIndex <= 0) return;

    final prevIndex = state.currentIndex - 1;
    final prevQ = state.questions[prevIndex];

    state = state.copyWith(
      currentIndex: prevIndex,
      currentInputText: prevQ.userAnswer ?? '',
      isSubmitted: prevQ.userAnswer?.isNotEmpty ?? false,
      matchScore: prevQ.userAnswer?.isNotEmpty ?? false
          ? DiffEngine.calculateMatchScore(prevQ.answer, prevQ.userAnswer!)
          : 0,
    );
  }
}

final quizProvider = NotifierProvider<QuizNotifier, QuizState>(() {
  return QuizNotifier();
});
