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
  /// - 줄바꿈(\n) 및 번호 목록(1., 2., (가), ① 등) 구조를 가독성 있게 보존
  static List<TextSpan> buildHighlightedDiffSpans({
    required String officialAnswer,
    required String userAnswer,
    required bool isDarkMode,
    String keywords = '',
  }) {
    final List<TextSpan> spans = [];

    // 정제된 사용자 답안 (조사 및 구두점 정제)
    final cleanUser = sanitizeText(userAnswer);
    final normUser = normalizeParticles(cleanUser);

    // 모범 답안 줄 단위 분리
    final lines = officialAnswer.split('\n');

    final RegExp headerRegExp = RegExp(
      r'^(?:\d+[\.\)]|\([가-하0-9a-zA-Z]+\)|[①-⑩]|[가-하][\.\)]|[•\-\*\+▶▪]|\[[^\]]+\])\s*',
    );

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.trim().isEmpty) {
        if (i < lines.length - 1) {
          spans.add(const TextSpan(text: '\n'));
        }
        continue;
      }

      // 1. 번호 / 헤더 기호 분리
      final match = headerRegExp.firstMatch(line);
      String header = '';
      String body = line;

      if (match != null) {
        header = match.group(0) ?? '';
        body = line.substring(header.length);
      }

      // 번호/기호 헤더 렌더링 (가독성 높은 선명한 스타일)
      if (header.isNotEmpty) {
        spans.add(
          TextSpan(
            text: header,
            style: TextStyle(
              color: isDarkMode ? Colors.cyanAccent : Colors.indigo,
              fontWeight: FontWeight.bold,
              fontSize: 16,
              height: 1.5,
            ),
          ),
        );
      }

      // 2. 본문 내용 대조 렌더링
      if (body.trim().isNotEmpty) {
        final cleanBody = sanitizeText(body);
        final normBody = normalizeParticles(cleanBody);

        // 사용자가 본문 단어를 포함하고 있는지 검사
        bool isMatched = false;
        if (normUser.isNotEmpty && normBody.isNotEmpty) {
          if (normUser.contains(normBody) || normBody.contains(normUser)) {
            isMatched = true;
          } else {
            // 본문 단어 단위/키워드 단위 매칭 검사
            final words = normBody.split(' ').where((w) => w.length >= 2).toList();
            if (words.isNotEmpty) {
              int matchedWords = words.where((w) => normUser.contains(w)).length;
              if (matchedWords / words.length >= 0.5) {
                isMatched = true;
              }
            }
          }
        }

        if (isMatched) {
          // 일치하는 본문 (에메랄드 그린)
          spans.add(
            TextSpan(
              text: body,
              style: const TextStyle(
                color: AppColors.emeraldGreen,
                fontWeight: FontWeight.bold,
                fontSize: 16,
                height: 1.5,
              ),
            ),
          );
        } else {
          // 누락/미완성 본문 (오렌지/앰버)
          spans.add(
            TextSpan(
              text: body,
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
        }
      }

      // 줄바꿈 추가
      if (i < lines.length - 1) {
        spans.add(const TextSpan(text: '\n'));
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
