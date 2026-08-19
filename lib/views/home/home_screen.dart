import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ncs_work/data/datasources/database_helper.dart';
import 'package:ncs_work/data/models/subject_model.dart';
import 'package:ncs_work/viewmodels/quiz_viewmodel.dart';
import 'package:ncs_work/viewmodels/theme_viewmodel.dart';
import 'package:ncs_work/views/home/widgets/comprehensive_evaluation_button.dart';
import 'package:ncs_work/views/home/widgets/subject_card.dart';
import 'package:ncs_work/views/quiz/quiz_screen.dart';
import 'package:ncs_work/views/subject_detail/subject_detail_screen.dart';

/// 메인 홈 화면 (ConsumerWidget)
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Riverpod select로 테마 모드만 정확히 구독
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '직업상담사2급 과정평가형',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            tooltip: isDark ? '라이트 모드로 전환' : '다크 모드로 전환',
            icon: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              color: isDark ? Colors.amber : Colors.indigo,
            ),
            onPressed: () {
              ref.read(themeProvider.notifier).toggleTheme();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<List<SubjectModel>>(
          future: DatabaseHelper.instance.getSubjects(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final subjects = snapshot.data ?? [];

            return Column(
              children: [
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16.0),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.1,
                    ),
                    itemCount: subjects.length,
                    itemBuilder: (context, index) {
                      final subject = subjects[index];
                      return SubjectCard(
                        subjectId: subject.id,
                        subjectName: subject.name,
                        onTap: () {
                          if (subject.id == 1 || subject.id == 3) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SubjectDetailScreen(subject: subject),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${subject.name} 과목은 추후 업데이트 예정입니다.'),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                      );
                    },
                  ),
                ),
                ComprehensiveEvaluationButton(
                  onPressed: () {
                    ref.read(quizProvider.notifier).loadRandomQuestions();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const QuizScreen(title: '전 과목 통합 종합평가'),
                      ),
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
