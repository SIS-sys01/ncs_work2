import 'package:flutter/material.dart';
import 'package:ncs_work/core/constants/app_colors.dart';
import 'package:ncs_work/data/models/question_model.dart';

/// 주관식 문제 정보 헤더 위젯 (Stateless)
class QuestionHeader extends StatelessWidget {
  final QuestionModel question;
  final int currentIndex;
  final int totalCount;

  const QuestionHeader({
    super.key,
    required this.question,
    required this.currentIndex,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primary, width: 1),
              ),
              child: Text(
                '문제 ${currentIndex + 1} / $totalCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                question.type == 'internal' ? '내부평가' : '외부평가 요약',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textMutedDark,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          question.formattedQuestion,
          style: theme.textTheme.titleLarge?.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            height: 1.4,
          ),
        ),
        if (question.questionType == 'cloze' && question.clozeDisplayText != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
            ),
            child: Text(
              question.clozeDisplayText!,
              style: const TextStyle(fontSize: 16, height: 1.6),
            ),
          ),
        ],
      ],
    );
  }
}
