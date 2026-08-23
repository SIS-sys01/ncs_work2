import 'package:diff_match_patch/diff_match_patch.dart';
import 'package:flutter/material.dart';
import 'package:ncs_work/core/constants/app_colors.dart';

/// 사용자의 주관식 답안과 모범 답안을 실시간/제출 시 대조하여
/// 일치 부분(녹색)과 차이/누락 부분(붉은색)으로 하이라이팅해 주는 스마트 채점 엔진
class DiffEngine {
  DiffEngine._();

  /// 텍스트 정제: 번호 목록(1., 2), (가), ① 등) 및 구두점(., ,, !, ? 등) 및 불릿 기호 제거
  static String sanitizeText(String text) {
    var cleaned = text;
    // 1. 번호 목록 및 기호 헤더 제거 (1., 2), (가), ①, •, - 등)
    cleaned = cleaned.replaceAll(
      RegExp(r'(?:^|\n|\s*)(?:\d+[\.\)]|\([가-하0-9a-zA-Z]+\)|[①-⑩]|[가-하][\.\)]|[•\-\*\+▶▪])\s*'),
      ' ',
    );
    // 2. 구두점 및 기호 제거 (마침표, 쉼표, 느낌표, 물음표, 콜론 등)
    cleaned = cleaned.replaceAll(RegExp(r'[^\w\s가-힣]'), ' ');
    // 3. 연속 공백 및 줄바꿈 정규화
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();
    return cleaned;
  }

  /// 한국어 조사(~을/를/은/는/이/가/와/과/등/의/에/으로/로) 정제
  static String normalizeParticles(String text) {
    // 단어 끝에 붙은 흔한 조사 정제
    var cleaned = text.replaceAll(RegExp(r'(?<=[가-힣]{2,})(을|를|은|는|이|가|와|과|등|의|에|으로|로)(?=\s|$)'), '');
    return cleaned;
  }

  /// 키워드 분리 헬퍼
  static List<String> extractKeywordList(String keywords) {
    if (keywords.trim().isEmpty) return [];
    return keywords
        .split(RegExp(r'[,/\n;\\]'))
        .map((k) => sanitizeText(k))
        .where((k) => k.isNotEmpty)
        .toList();
  }

  /// 모범 답안(officialAnswer)과 사용자 입력 답안(userAnswer)을 비교하여 TextSpan 목록으로 렌더링
  static List<TextSpan> buildHighlightedDiffSpans({
    required String officialAnswer,
    required String userAnswer,
    required bool isDarkMode,
    String keywords = '',
  }) {
    // 모범 답안 및 사용자 답안에서 번호/기호/구두점 정제
    final cleanOfficial = sanitizeText(officialAnswer);
    final cleanUser = sanitizeText(userAnswer);

    // 조사 정제된 텍스트로 diff 수행
    final normOfficial = normalizeParticles(cleanOfficial);
    final normUser = normalizeParticles(cleanUser);

    final List<Diff> diffs = diff(normOfficial, normUser);
    cleanupSemantic(diffs);

    final List<TextSpan> spans = [];

    for (final diff in diffs) {
      if (diff.operation == DIFF_EQUAL) {
        // 모범 답안과 일치하는 핵심 구문 (에메랄드 그린)
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
        if (diff.text.trim().isEmpty) {
          spans.add(
            TextSpan(
              text: diff.text,
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
          );
          continue;
        }
        // 모범 답안 수록 누락 키워드 (오렌지/앰버)
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
        final trimmed = diff.text.trim();
        // 기호, 구두점, 공백, 단독 조사 입력은 [추가] 하이라이트에서 제외하여 깔끔한 뷰 제공
        if (trimmed.isEmpty) continue;
        if (RegExp(r'^[^\w가-힣]+$').hasMatch(trimmed)) continue;

        spans.add(
          TextSpan(
            text: '[추가: $trimmed]',
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

  /// 스마트 일치율 계산 (0 ~ 100%) - 번호/구두점/조사 무시 & 키워드 매칭 우대
  static int calculateMatchScore(
    String officialAnswer,
    String userAnswer, {
    String keywords = '',
  }) {
    final cleanOfficial = sanitizeText(officialAnswer);
    final cleanUser = sanitizeText(userAnswer);

    if (cleanOfficial.isEmpty || cleanUser.isEmpty) return 0;

    // 1. 키워드 기반 매칭 검사
    final kwList = extractKeywordList(keywords);
    int keywordScore = 0;
    if (kwList.isNotEmpty) {
      int matchedKwCount = 0;
      final normalizedUser = normalizeParticles(cleanUser);
      for (final kw in kwList) {
        final normKw = normalizeParticles(kw);
        if (normalizedUser.contains(normKw) || cleanUser.contains(kw)) {
          matchedKwCount++;
        }
      }
      keywordScore = (matchedKwCount / kwList.length * 100).round();
      if (keywordScore > 100) keywordScore = 100;
    }

    // 2. 텍스트 문자열 기반 매칭 검사 (공백 완전 제거 후 diff)
    final noSpaceOfficial = cleanOfficial.replaceAll(RegExp(r'\s+'), '');
    final noSpaceUser = cleanUser.replaceAll(RegExp(r'\s+'), '');

    final normOfficial = normalizeParticles(noSpaceOfficial);
    final normUser = normalizeParticles(noSpaceUser);

    int textScore = 0;
    if (normOfficial.isNotEmpty && normUser.isNotEmpty) {
      final diffs = diff(normOfficial, normUser);
      cleanupSemantic(diffs);

      int matchChars = 0;
      for (final diff in diffs) {
        if (diff.operation == DIFF_EQUAL) {
          matchChars += diff.text.length;
        }
      }
      textScore = (matchChars / normOfficial.length * 100).round();
      if (textScore > 100) textScore = 100;
    }

    // 3. 키워드 점수와 텍스트 점수 중 더 높은 점수를 반영 (키워드가 모두 포함되면 100% 보장)
    if (kwList.isNotEmpty && keywordScore >= 100) {
      return 100;
    }

    final finalScore = (kwList.isNotEmpty)
        ? (keywordScore * 0.6 + textScore * 0.4).round()
        : textScore;

    return finalScore > 100 ? 100 : (finalScore < 0 ? 0 : finalScore);
  }
}
