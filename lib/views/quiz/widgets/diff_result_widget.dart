import 'package:flutter/material.dart';
import 'package:ncs_work/core/constants/app_colors.dart';
import 'package:ncs_work/core/utils/diff_engine.dart';

/// 채점 피드백 스마트 하이라이팅 결과 및 Active Recall 암기 가이드 위젯 (Stateless)
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
      padding: const EdgeInsets.all(18.0),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: matchScore >= 80
              ? AppColors.emeraldGreen
              : matchScore >= 50
                  ? Colors.amber
                  : Colors.orangeAccent,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    color: matchScore >= 80 ? AppColors.emeraldGreen : Colors.amber,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    '🎯 답안 비교 & 암기 가이드',
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
                              : Colors.orangeAccent)
                      .withValues(alpha: 0.18),
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
                            : Colors.orangeAccent,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: AppColors.emeraldGreen, size: 16),
              const SizedBox(width: 4),
              const Text(
                '일치 핵심어',
                style: TextStyle(color: AppColors.emeraldGreen, fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 16),
              Icon(Icons.lightbulb_rounded, color: isDarkMode ? Colors.orangeAccent : Colors.deepOrange, size: 16),
              const SizedBox(width: 4),
              Text(
                '보완 키워드 (차이점 대조)',
                style: TextStyle(
                  color: isDarkMode ? Colors.orangeAccent : Colors.deepOrange,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          RichText(
            text: TextSpan(
              children: spans,
              style: theme.textTheme.bodyLarge,
            ),
          ),
          const SizedBox(height: 16),
          // 💡 Active Recall 더 잘 외워지는 암기 가이드 상자
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? Colors.amber.withValues(alpha: 0.1)
                  : Colors.amber.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.tips_and_updates_rounded, color: Colors.amber, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '💡 암기 팁 (Active Recall)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.amber,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '내 입력과 주황색 보완 표현의 차이점을 한 번 더 눈으로 대조하면 뇌에 오래 기억됩니다!',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDarkMode ? Colors.white70 : Colors.black87,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (keywords.isNotEmpty) ...[
            const SizedBox(height: 10),
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
                  const Icon(Icons.key_rounded, size: 18, color: Colors.tealAccent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '암기 필수 키워드: $keywords',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.tealAccent,
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
