import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ncs_work/core/constants/app_colors.dart';
import 'package:ncs_work/viewmodels/quiz_viewmodel.dart';
import 'package:ncs_work/viewmodels/theme_viewmodel.dart';
import 'package:ncs_work/views/quiz/widgets/diff_result_widget.dart';
import 'package:ncs_work/views/quiz/widgets/question_header.dart';

/// 주관식 풀이 & 채점 화면 (ConsumerStatefulWidget)
class QuizScreen extends ConsumerStatefulWidget {
  final String title;

  const QuizScreen({
    super.key,
    required this.title,
  });

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  late TextEditingController _inputController;

  @override
  void initState() {
    super.initState();
    _inputController = TextEditingController();
  }

  @override
  void dispose() {
    // 메모리 누수 방지를 위한 컨트롤러 해제
    _inputController.dispose();
    super.dispose();
  }

  void _syncControllerWithState(String text) {
    if (_inputController.text != text) {
      _inputController.text = text;
    }
  }

  @override
  Widget build(BuildContext context) {
    final quizState = ref.watch(quizProvider);
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;

    if (quizState.isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final currentQuestion = quizState.currentQuestion;

    if (currentQuestion == null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: const Center(
          child: Text('주관식 문항이 존재하지 않습니다.'),
        ),
      );
    }

    _syncControllerWithState(quizState.currentInputText);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            tooltip: '새 10문제 무작위 리셋',
            icon: const Icon(Icons.refresh_rounded, color: Colors.tealAccent),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('10문제 무작위 리셋'),
                  content: const Text('새로운 10문제를 무작위로 추출하여 새로 풀어보시겠습니까?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('취소'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('새로 시작'),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                ref.read(quizProvider.notifier).resetSession();
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              QuestionHeader(
                question: currentQuestion,
                currentIndex: quizState.currentIndex,
                totalCount: quizState.questions.length,
              ),
              const SizedBox(height: 24),
              Text(
                '답안 입력 (주관식 서술형)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _inputController,
                maxLines: 5,
                enabled: !quizState.isSubmitted,
                onChanged: (val) {
                  ref.read(quizProvider.notifier).updateInputText(val);
                },
                decoration: InputDecoration(
                  hintText: '문제에 대한 서술/기술형 답안을 직접 타이핑하여 작성하세요...',
                  hintStyle: TextStyle(
                    color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                  ),
                  filled: true,
                  fillColor: isDark ? AppColors.darkCard : AppColors.lightCard,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (!quizState.isSubmitted)
                ElevatedButton(
                  onPressed: quizState.currentInputText.trim().isEmpty
                      ? null
                      : () {
                          ref.read(quizProvider.notifier).submitAnswer();
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    '제출 및 스마트 채점',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              if (quizState.isSubmitted) ...[
                DiffResultWidget(
                  officialAnswer: currentQuestion.answer,
                  userAnswer: quizState.currentInputText,
                  matchScore: quizState.matchScore,
                  keywords: currentQuestion.keywords,
                  isDarkMode: isDark,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    if (quizState.currentIndex > 0)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            ref.read(quizProvider.notifier).previousQuestion();
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text('이전 문제'),
                        ),
                      ),
                    if (quizState.currentIndex > 0 && !quizState.isLastQuestion)
                      const SizedBox(width: 12),
                    if (!quizState.isLastQuestion)
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            ref.read(quizProvider.notifier).nextQuestion();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text('다음 문제'),
                        ),
                      ),
                  ],
                ),
                if (quizState.isLastQuestion) ...[
                  const SizedBox(height: 24),
                  const Divider(height: 30, thickness: 1),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      ref.read(quizProvider.notifier).resetSession();
                    },
                    icon: const Icon(Icons.autorenew_rounded),
                    label: const Text(
                      '새 10문제 무작위 리셋하여 다시 풀기',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.popUntil(context, (route) => route.isFirst);
                    },
                    icon: const Icon(Icons.check_circle_outline_rounded),
                    label: const Text(
                      '평가 완료 및 메인 홈으로 돌아가기',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.indigoAccent,
                      side: const BorderSide(color: Colors.indigoAccent, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
