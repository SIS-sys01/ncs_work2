import 'package:diff_match_patch/diff_match_patch.dart';
import 'package:flutter/material.dart';
import 'package:ncs_work/core/constants/app_colors.dart';

/// 사용자의 주관식 답안과 모범 답안을 실시간/제출 시 대조하여
/// 일치 부분(녹색)과 차이/누락 부분(붉은색)으로 하이라이팅해 주는 스마트 채점 엔진
class DiffEngine {
  DiffEngine._();

  /// 모범 답안(officialAnswer)과 사용자 입력 답안(userAnswer)을 비교하여 TextSpan 목록으로 렌더링
  static List<TextSpan> buildHighlightedDiffSpans({
    required String officialAnswer,
    required String userAnswer,
    required bool isDarkMode,
  }) {
    final List<Diff> diffs = diff(officialAnswer.trim(), userAnswer.trim());
    cleanupSemantic(diffs);

    final List<TextSpan> spans = [];

    for (final diff in diffs) {
      if (diff.operation == DIFF_EQUAL) {
        // 모범 답안과 정확히 일치하는 부분 (에메랄드 그린)
        spans.add(
          TextSpan(
            text: diff.text,
            style: const TextStyle(
              color: AppColors.emeraldGreen,
              fontWeight: FontWeight.bold,
              fontSize: 16,
              height: 1.5,
            ),
          ),
        );
      } else if (diff.operation == DIFF_DELETE) {
        // 모범 답안에 수록된 핵심 표현 (보완할 텍스트 및 대조 포인트: 앰버/오렌지 하이라이트)
        spans.add(
          TextSpan(
            text: diff.text,
            style: TextStyle(
              color: isDarkMode ? Colors.orangeAccent : Colors.deepOrange,
              fontWeight: FontWeight.w700,
              backgroundColor: isDarkMode
                  ? Colors.amber.withValues(alpha: 0.2)
                  : Colors.amber.withValues(alpha: 0.25),
              fontSize: 16,
              height: 1.5,
            ),
          ),
        );
      } else if (diff.operation == DIFF_INSERT) {
        // 사용자가 자유롭게 추가 입력한 구문 (파스텔 블루/인디고)
        spans.add(
          TextSpan(
            text: '[내 입력: ${diff.text}]',
            style: TextStyle(
              color: isDarkMode ? Colors.cyanAccent : Colors.indigo,
              fontStyle: FontStyle.italic,
              fontSize: 14,
              height: 1.5,
              backgroundColor: isDarkMode
                  ? Colors.blue.withValues(alpha: 0.15)
                  : Colors.blue.withValues(alpha: 0.1),
            ),
          ),
        );
      }
    }

    return spans;
  }

  /// 간단한 일치율 계산 (0 ~ 100%)
  static int calculateMatchScore(String officialAnswer, String userAnswer) {
    if (officialAnswer.trim().isEmpty) return 0;
    if (userAnswer.trim().isEmpty) return 0;

    final diffs = diff(officialAnswer.trim(), userAnswer.trim());
    cleanupSemantic(diffs);

    int matchChars = 0;
    for (final diff in diffs) {
      if (diff.operation == DIFF_EQUAL) {
        matchChars += diff.text.length;
      }
    }

    final totalChars = officialAnswer.trim().length;
    if (totalChars == 0) return 0;

    final ratio = (matchChars / totalChars * 100).round();
    return ratio > 100 ? 100 : ratio;
  }
}
