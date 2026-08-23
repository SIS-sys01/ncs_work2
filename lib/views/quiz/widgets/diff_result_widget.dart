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
      keywords: keywords,
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
          if (keywords.isNotEmpty) ...[
            const SizedBox(height: 10),
            _buildKeywordCheckSection(
              context: context,
              keywords: keywords,
              officialAnswer: officialAnswer,
              userAnswer: userAnswer,
              isDarkMode: isDarkMode,
            ),
          ],
        ],
      ),
    );
  }

  /// 키워드별 맞춤 보완 가이드 위젯 (맞은 키워드 vs 틀린/누락된 키워드 개별 구분)
  Widget _buildKeywordCheckSection({
    required BuildContext context,
    required String keywords,
    required String officialAnswer,
    required String userAnswer,
    required bool isDarkMode,
  }) {
    final theme = Theme.of(context);

    // 1. 키워드 목록 추출
    final kwList = DiffEngine.extractKeywordList(keywords);
    if (kwList.isEmpty) return const SizedBox.shrink();

    final compactUser = DiffEngine.compactText(userAnswer);

    final List<String> matched = [];
    final List<String> missing = [];

    for (final kw in kwList) {
      if (DiffEngine.isKeywordMatched(kw, compactUser)) {
        matched.add(kw);
      } else {
        missing.add(kw);
      }
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode ? Colors.white12 : Colors.black12,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.fact_check_rounded, size: 20, color: Colors.tealAccent),
              const SizedBox(width: 8),
              Text(
                '🔍 핵심 키워드 체크 & 보완 가이드',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...matched.map(
                (kw) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.emeraldGreen.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.emeraldGreen, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle_rounded, size: 15, color: AppColors.emeraldGreen),
                      const SizedBox(width: 5),
                      Text(
                        kw,
                        style: const TextStyle(
                          color: AppColors.emeraldGreen,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              ...missing.map(
                (kw) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: (isDarkMode ? Colors.orangeAccent : Colors.deepOrange).withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDarkMode ? Colors.orangeAccent : Colors.deepOrange,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.cancel_rounded,
                        size: 15,
                        color: isDarkMode ? Colors.orangeAccent : Colors.deepOrange,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '$kw (보완 필요)',
                        style: TextStyle(
                          color: isDarkMode ? Colors.orangeAccent : Colors.deepOrange,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (missing.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (isDarkMode ? Colors.amber : Colors.orange).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 18,
                        color: isDarkMode ? Colors.orangeAccent : Colors.deepOrange,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '틀리거나 누락된 단어/키워드',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: isDarkMode ? Colors.orangeAccent : Colors.deepOrange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '• 보완할 키워드: ${missing.join(", ")}',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white70 : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '• 내가 작성한 답: "${userAnswer.isEmpty ? "(미입력)" : userAnswer}"',
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.stars_rounded, color: AppColors.emeraldGreen, size: 18),
                const SizedBox(width: 6),
                const Text(
                  '모든 암기 필수 키워드가 완벽하게 작성되었습니다!',
                  style: TextStyle(
                    color: AppColors.emeraldGreen,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
