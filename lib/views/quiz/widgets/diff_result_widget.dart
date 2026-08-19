import 'package:flutter/material.dart';
import 'package:ncs_work/core/constants/app_colors.dart';
import 'package:ncs_work/core/utils/diff_engine.dart';

/// 채점 피드백 스마트 하이라이팅 결과 표시 위젯 (Stateless)
class DiffResultWidget extends StatelessWidget {
  final String officialAnswer;
  final String userAnswer;
  final int matchScore;
  final String keywords;
  final bool isDarkMode;

  const DiffResultWidget({
    super.key,
    required this.officialAnswer,
    required this.userAnswer,
    required this.matchScore,
    required this.keywords,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spans = DiffEngine.buildHighlightedDiffSpans(
      officialAnswer: officialAnswer,
      userAnswer: userAnswer,
      isDarkMode: isDarkMode,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: matchScore >= 80
              ? AppColors.emeraldGreen
              : matchScore >= 50
                  ? Colors.amber
                  : AppColors.desaturatedRed,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.analytics_rounded, color: AppColors.primary, size: 22),
                  SizedBox(width: 8),
                  Text(
                    '스마트 채점 결과 대조',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: (matchScore >= 80
                          ? AppColors.emeraldGreen
                          : matchScore >= 50
                              ? Colors.amber
                              : AppColors.desaturatedRed)
                      .withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '일치율 $matchScore%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: matchScore >= 80
                        ? AppColors.emeraldGreen
                        : matchScore >= 50
                            ? Colors.amber
                            : AppColors.desaturatedRed,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: AppColors.emeraldGreen, size: 16),
              SizedBox(width: 4),
              Text(
                '일치/정답',
                style: TextStyle(color: AppColors.emeraldGreen, fontSize: 12, fontWeight: FontWeight.bold),
              ),
              SizedBox(width: 16),
              Icon(Icons.cancel_rounded, color: AppColors.desaturatedRed, size: 16),
              SizedBox(width: 4),
              Text(
                '누락/차이',
                style: TextStyle(color: AppColors.desaturatedRed, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          RichText(
            text: TextSpan(
              children: spans,
              style: theme.textTheme.bodyLarge,
            ),
          ),
          if (keywords.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.key_rounded, size: 18, color: Colors.amber),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '핵심 키워드: $keywords',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.amber,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
