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
    // 띄어쓰기/공백 차이로 인한 무의미한 차이 강조 방지를 위해 연속 공백 정규화
    final normalizedOfficial = officialAnswer.replaceAll(RegExp(r'[ \t]+'), ' ').trim();
    final normalizedUser = userAnswer.replaceAll(RegExp(r'[ \t]+'), ' ').trim();

    final List<Diff> diffs = diff(normalizedOfficial, normalizedUser);
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
        // 공백 단독인 경우는 굳이 하이라이트 박스로 보여주지 않음
        if (diff.text.trim().isEmpty) {
          spans.add(
            TextSpan(
              text: diff.text,
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
          );
          continue;
        }
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
        if (diff.text.trim().isEmpty) continue; // 순수 공백 추가는 생략
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

  /// 띄어쓰기(공백/줄바꿈)를 무시한 일치율 계산 (0 ~ 100%)
  static int calculateMatchScore(String officialAnswer, String userAnswer) {
    // 띄어쓰기 및 모든 공백문자(\s+) 완전 제거
    final cleanOfficial = officialAnswer.replaceAll(RegExp(r'\s+'), '');
    final cleanUser = userAnswer.replaceAll(RegExp(r'\s+'), '');

    if (cleanOfficial.isEmpty) return 0;
    if (cleanUser.isEmpty) return 0;

    final diffs = diff(cleanOfficial, cleanUser);
    cleanupSemantic(diffs);

    int matchChars = 0;
    for (final diff in diffs) {
      if (diff.operation == DIFF_EQUAL) {
        matchChars += diff.text.length;
      }
    }

    final totalChars = cleanOfficial.length;
    if (totalChars == 0) return 0;

    final ratio = (matchChars / totalChars * 100).round();
    return ratio > 100 ? 100 : ratio;
  }
}
