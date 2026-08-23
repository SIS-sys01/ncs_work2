import 'package:flutter_test/flutter_test.dart';
import 'package:ncs_work/core/utils/diff_engine.dart';

void main() {
  test('Holland 5 concepts with particles and commas should score 100%', () {
    const official = '1. 일관성\n2. 차별성\n3. 정체성\n4. 일치성\n5. 계측성';
    const user = '일관성을, 차별성, 정체성, 일치성, 계측성';
    const keywords = '일관성, 차별성, 정체성, 일치성, 계측성';

    final score = DiffEngine.calculateMatchScore(official, user, keywords: keywords);
    expect(score, 100);

    final spans = DiffEngine.buildHighlightedDiffSpans(
      officialAnswer: official,
      userAnswer: user,
      isDarkMode: true,
      keywords: keywords,
    );
    expect(spans.isNotEmpty, isTrue);
  });

  test('Spacing difference (e.g. 집체 훈련 vs 집체훈련) should score 100%', () {
    const official = '1. 집체훈련\n2. 현장훈련';
    const user = '집체 훈련, 현장 훈련';
    const keywords = '집체훈련, 현장훈련';

    final score = DiffEngine.calculateMatchScore(official, user, keywords: keywords);
    expect(score, 100);

    final spans = DiffEngine.buildHighlightedDiffSpans(
      officialAnswer: official,
      userAnswer: user,
      isDarkMode: true,
      keywords: keywords,
    );
    expect(spans.isNotEmpty, isTrue);
  });

  test('Concept-only answer should NOT match unwritten analysis process keywords', () {
    const official = '''직업요구도의 개념은 근로자나 구직자가 현재 보유한 역량과 직무 수행에 필요한 역량 간의 차이를 말한다.
1. 환경 분석
2. 직무 분석
3. 개인 역량 분석
4. 요구도 도출
5. 훈련 프로그램 설계
6. 평가 및 피드백''';
    const user = '현재 보유한 역량과 직무 수행에 필요한 역량 간의 차이를 말한다.';
    const keywords = '보유 역량, 필요 역량, Gap, 환경 분석, 직무 분석, 개인 역량 분석, 요구도 도출, 훈련 프로그램 설계, 평가 및 피드백';

    final compactUser = DiffEngine.compactText(user);

    // 보유 역량, 필요 역량은 작성함 -> 매칭
    expect(DiffEngine.isKeywordMatched('보유 역량', compactUser), isTrue);
    expect(DiffEngine.isKeywordMatched('필요 역량', compactUser), isTrue);

    // 작성하지 않은 분석 과정 6가지는 미포함이어야 함
    expect(DiffEngine.isKeywordMatched('환경 분석', compactUser), isFalse);
    expect(DiffEngine.isKeywordMatched('직무 분석', compactUser), isFalse);
    expect(DiffEngine.isKeywordMatched('개인 역량 분석', compactUser), isFalse);
    expect(DiffEngine.isKeywordMatched('요구도 도출', compactUser), isFalse);
    expect(DiffEngine.isKeywordMatched('훈련 프로그램 설계', compactUser), isFalse);
    expect(DiffEngine.isKeywordMatched('평가 및 피드백', compactUser), isFalse);

    // 디프 렌더링 확인 (공식 답안 전달)
    final spans = DiffEngine.buildHighlightedDiffSpans(
      officialAnswer: official,
      userAnswer: user,
      isDarkMode: true,
      keywords: keywords,
    );
    expect(spans.isNotEmpty, isTrue);
  });
}
