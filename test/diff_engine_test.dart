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
}
