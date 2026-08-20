import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ncs_work/core/constants/app_colors.dart';
import 'package:ncs_work/data/models/subject_model.dart';
import 'package:ncs_work/viewmodels/quiz_viewmodel.dart';
import 'package:ncs_work/views/quiz/quiz_screen.dart';

/// 과목 상세 선택 화면 (내부평가 / 외부평가 2개 직관적 버튼 제공)
class SubjectDetailScreen extends ConsumerWidget {
  final SubjectModel subject;

  const SubjectDetailScreen({
    super.key,
    required this.subject,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          subject.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),
              Text(
                '학습할 주관식 평가 유형을 선택하세요.',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                '100% 주관식 서술형 문제로 인출(Active Recall) 암기를 진행합니다.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textMutedDark,
                    ),
              ),
              const SizedBox(height: 30),
              const SizedBox(height: 30),
              Expanded(
                child: _EvaluationOptionCard(
                  title: '내부평가 연습 시작',
                  subtitle: subject.id == 1
                      ? '${subject.name} 내부평가 100% 주관식 (16문항)'
                      : '${subject.name} 내부평가 주관식 문제 (랜덤 10문항)',
                  icon: Icons.assignment_rounded,
                  accentColor: Colors.tealAccent,
                  isAvailable: true,
                  onTap: () {
                    ref.read(quizProvider.notifier).loadQuestions(
                          subjectId: subject.id,
                          type: 'internal',
                        );
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => QuizScreen(title: '${subject.name} - 내부평가'),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: _EvaluationOptionCard(
                  title: '외부평가 연습 시작',
                  subtitle: (subject.id == 1 || subject.id == 3)
                      ? '기술/서술/정의/개념/종류나열 핵심 주관식 (랜덤 10문항)'
                      : '외부평가 문제는 현재 미탑재 상태입니다.',
                  icon: Icons.menu_book_rounded,
                  accentColor: (subject.id == 1 || subject.id == 3) ? Colors.indigoAccent : Colors.grey,
                  isAvailable: subject.id == 1 || subject.id == 3,
                  badgeText: (subject.id == 1 || subject.id == 3) ? null : '미탑재',
                  onTap: () {
                    if (subject.id == 1 || subject.id == 3) {
                      ref.read(quizProvider.notifier).loadQuestions(
                            subjectId: subject.id,
                            type: 'external',
                          );
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => QuizScreen(title: '${subject.name} - 외부평가'),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${subject.name} 외부평가 문제는 현재 미탑재 상태입니다.'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

/// 평가 선택 직관적 카드 위젯 (Stateless)
class _EvaluationOptionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final bool isAvailable;
  final String? badgeText;
  final VoidCallback onTap;

  const _EvaluationOptionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    this.isAvailable = true,
    this.badgeText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isAvailable ? accentColor.withValues(alpha: 0.5) : Colors.grey.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Stack(
            children: [
              if (badgeText != null)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade700,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      badgeText!,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: isAvailable
                          ? accentColor.withValues(alpha: 0.2)
                          : Colors.grey.withValues(alpha: 0.15),
                      child: Icon(
                        icon,
                        size: 36,
                        color: isAvailable ? accentColor : Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isAvailable ? null : theme.disabledColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isAvailable ? AppColors.textMutedDark : theme.disabledColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
