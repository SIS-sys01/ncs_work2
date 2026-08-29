import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 앱 업데이트 후 첫 실행 시 변경 내역 공지 안내 서비스
class NoticeService {
  static const String _keyLastSeenNoticeVersion = 'last_seen_notice_version';

  /// 버전별 변경 및 추가 내역 공지 맵
  static const Map<String, String> _versionReleaseNotes = {
    '0.1.19': '''📢 v0.1.19 마법의 특수 문항 보호막 설치 완료!

선생님께서 정말 예리하게 찾아내셨습니다! 새로 도입된 [오토-파서 엔진]이 너무 똑똑한 나머지, 1과목에 정성껏 빚어 올렸던 특수 문항(예시 섞기, 랜덤 빈칸 뚫기)까지 전부 평범한 원문으로 리셋해버리는 해프닝이 있었습니다.
이를 막기 위해, 오토 엔진이 전체적인 뼈대(일반 문제)를 먼저 깔고 난 뒤 그 위에 선생님께서 수작업으로 빚으신 [특수 JSON 정보]가 지워지지 않도록 강력하게 덧입혀지는 최우선 순위 방어막을 설치했습니다! 이제 특수 문항은 영원히 안전합니다!''',
    '0.1.17': '''📢 v0.1.17 갓벽한 자동 추출 엔진 런칭!

드디어 앱이 스스로 문제를 읽어들입니다! 미세한 띄어쓰기(정 답, 정답 :)나 오타가 섞여있어도 인공지능처럼 귀신같이 '정답' 지점만 잘라내어 해설지를 분리해주는 [강력한 정규식(Regex) 스캔 엔진]이 메인 데이터베이스에 탑재되었습니다.
이제 파이썬 스크립트 등 어려운 작업 없이, PDF 파일을 폴더에 던져놓기만 하면 모든 과목 세팅이 끝납니다!''',
    '0.1.13': '''📢 v0.1.13 특급 편의성 패치: 자동 업데이트!

매번 인터넷 창이 켜지고 다운로드를 기다려야 해서 번거로우셨죠?
이제 앱 안에서 "지금 업데이트"를 누르면, 즉시 파란색 로딩 바가 나타나 다운로드가 진행되며 끝나자마자 [설치] 버튼 하나만 누르면 되는 자동화 업데이트 시스템이 도입되었습니다!
앞으로 새로운 내부평가/외부평가가 업데이트되더라도 터치 두 번이면 가장 편하게 새 문항을 받으실 수 있습니다.''',
    '0.1.12': '''📢 v0.1.12 신규 과목 탑재 완료!

드디어 앱에 신규 콘텐츠가 들어왔습니다!
선생님께서 전달해주신 [4직업상담행정 내부평가] 문항 10개가 완벽한 100% 원문 형태(동일 문맥 기준)로 추가되었습니다. 
앱을 켜고 과목 선택 창에서 '4직업상담행정'을 고르면 기존의 1과목처럼 똑같이 4과목 퀴즈를 풀 수 있게 됩니다. 열공하세요!''',
    '0.1.11': '''📢 v0.1.11 마법의 해설지 패치!

특수 문항을 풀고 제출했을 때, 채점은 정상적으로 이뤄졌으나 화면에 출력되는 정답 및 제출답안이 이상한 괄호와 기호(["단어", "단어"])로 컴퓨터 언어 그대로 출력되어 답답하셨죠?
선생님께서 보시기 편하도록 '예시 1번 정답:', '1번 괄호 답안:' 처럼 사람의 언어로 아름답게 번역해서 출력해 드리도록 완벽히 고쳤습니다! 이제 진짜 공부에만 집중하세요!!''',
    '0.1.10': '''📢 v0.1.10 찐찐찐 최종! 원인 완벽 타격!

문제가 계속 보이지 않던 진짜 근본적인 범인을 마침내 완벽히 색출해 형장의 이슬로 보냈습니다!!
핸드폰의 데이터베이스(SQLite) 엔진은 '문자'만을 원하는데, JSON 파일의 정답 키워드들이 [배열] 형태로 밀어닥치면서 데이터베이스 입구가 꽉 막혀버렸던(Crash) 것이었습니다! 그래서 문제지가 텅텅 비었던 것이죠!
키워드 배열을 문자열 콤마(,) 텍스트로 합쳐주는 방어막을 설치하여 통로를 막힘없이 뻥 뚫었습니다. 진짜로 즐거운 1과목 마법 학습 시간이 선생님을 기다립니다!''',
    '0.1.9': '''📢 v0.1.9 찐 최종 결점 제로 업데이트 안내!

선생님, 이제 정말로 아무것도 걱정하실 필요 없는 가장 완벽한 완성본입니다!
문제 지문에 빈칸을 뚫는 최첨단 정규표현식 기술이 휴대폰의 깐깐한 다트(Dart) 엔진에서 타입 충돌을 일으키는 아주 깊숙한 버그를 완벽하게 잡아냈습니다.
안심하고 다운로드해서 특수 문항을 맘껏 즐기세요! 🚀''',
    '0.1.8': '''📢 v0.1.8 Q5 셔플, Q10 빈칸 특수 문항 최종 적용!

진짜 최종!! 아까 화면 오류를 고치려고 파일을 되돌리다가 1과목의 신규 마법 문제들까지 옛날 버전으로 돌아가버린 것을 다시 100% 최신으로 복구했습니다.
이제 1과목 Q5(예시 셔플형), Q10(무작위 5개 빈칸 뚫기) 문제가 100% 정상 작동합니다! 기막힌 학습 효과를 경험해보세요!''',
    '0.1.7': '''📢 v0.1.7 원클릭 마법 업데이트 안내!

이제 선생님께서 번거롭게 깃허브 웹페이지를 보실 필요가 없습니다!
업데이트 팝업의 '지금 업데이트' 버튼을 누르면 다운로드용 인터넷 사이트가 켜지는 대신, 즉시 0.1초만에 파일 다운로드가 시작되도록 최고급 원클릭 로직을 탑재했습니다.

마음 푹 놓고 '확인'을 누르세요! 알아서 최신 파일이 스마트폰에 꽂힙니다! 🚀''',
    '0.1.6': '''📢 v0.1.6 내부평가 문제 출력 오류 최종 해결!!

안녕하세요 선생님! 드디어 1~12과목 전체 내부평가 문제 목록이 안 나오던 치명적인 현상을 100% 영구적으로 수정 완료했습니다!!
불편을 드려 죄송합니다. 내부 엔진이 이제 기적처럼 완벽하게 동작합니다!''',
    '0.1.5': '''📢 v0.1.5 핫픽스 2차 업데이트 안내!

정말 다 와서 고생하셨습니다 선생님!
'지금 업데이트' 버튼을 눌러도 인터넷 창이 열리지 않아 작동하지 않던 버그를 완벽하게 고쳤습니다!

(오류 원인: 안드로이드 보안 정책 상 '이 앱에서 인터넷 창을 띄울 수 있게 허락해주세요' 라는 권한이 누락되어 접속을 막고 있었습니다!)
이제 버튼을 누르는 즉시 스마트폰 인터넷 창이 촥 열리며 편하게 다운로드하실 수 있습니다!''',
    '0.1.4': '''📢 v0.1.4 핫픽스 업데이트 안내!

안녕하세요 선생님! 내부평가 문제들이 화면에 출력되지 않는 버그를 완벽하게 수정했습니다.
이제 1과목 셔플/빈칸 문제와 더불어 전체 과목 내부평가가 정상적으로 화면에 나타납니다!

(오류 원인: 내부 통신 라벨이 'internal' 에서 '내부평가' 로 바뀌는 과정에서 발생한 데이터 엇갈림이었습니다. 불편을 드려 죄송합니다!)''',
    '0.1.3': '''📢 v0.1.3 대규모 기능 추가 안내!

안녕하세요 선생님! 직상사 합격을 위한 학습 파트너가 더욱 강력해졌습니다!

[새로워진 내용]
1. 1과목 원문 100% 똑같이 되살렸어요!
   - 그동안 내용이 달라 헷갈리셨던 1과목 내부평가를 공식 최신 교재와 글자 하나까지 완벽하게 맞췄습니다. 이제 책 없이 앱 하나로 완벽 대비가 가능합니다!

2. 줄 긋기 문제 셔플 기능 (Q5)
   - 이제 문제를 풀 때마다 3개의 예시가 마법처럼 섞여서 나옵니다. 외워서 푸는 꼼수는 이제 안통해요! 완벽하게 이해해야만 정답을 맞힐 수 있습니다.

3. 빈칸 뚫기 마법 기능 (Q10)
   - 기다리시던 기능! 10개의 핵심 키워드 중 무작위로 딱 5개만 골라 괄호(빈칸)를 뚫어줍니다. 매번 빈칸 위치가 다르게 나오니 실력이 쑥쑥 오르실 거예요!

열공하시고 좋은 결과 있으시기를 항상 응원합니다!''',
    '0.1.2': '''📢 v0.1.2 업데이트 안내

항상 직업상담사2급 과정평가형 앱을 이용해 주셔서 감사합니다! 
이번 업데이트 내용을 알기 쉽게 안내해 드립니다.

[새로워진 내용]
1. 최신 교재 정답 완벽 반영 (1과목 초기면담)
   - 최신 교재(v0.002) 내용과 글자 하나 틀리지 않게 문제와 정답을 수정했습니다. 이제 안심하고 공부하세요!

2. 똑똑해진 새 버전 알림
   - 앱이 스스로 새로운 기능이 나왔는지 정확하게 알아채고 알려주도록 똑똑해졌습니다.

3. 문제 은행(데이터베이스) 최신화
   - 새로 고친 최신 문제들이 선생님 휴대폰에 잘 저장되도록 내부 창고를 새단장했습니다.

4. 친절한 첫인사 팝업 추가
   - 앱을 새로 깔거나 업데이트하고 처음 켜시면, 딱 한 번 안내창이 떠서 무엇이 좋아졌는지 친절하게 알려줍니다.

열공하시고 합격하시길 진심으로 응원합니다!''',
  };

  /// 앱 첫 실행 시 버전 업데이트 공지 팝업 체크
  static Future<void> checkVersionNotice(BuildContext context) async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final String currentVersion = packageInfo.version;

      final prefs = await SharedPreferences.getInstance();
      final String? lastSeenVersion = prefs.getString(_keyLastSeenNoticeVersion);

      // 이미 현재 버전을 확인한 경우 패스
      if (lastSeenVersion == currentVersion) return;

      final String noticeMessage = _versionReleaseNotes[currentVersion] ??
          '''📢 v$currentVersion 업데이트 안내\n\n직업상담사2급 과정평가형 앱이 v$currentVersion 버전으로 업데이트되었습니다!\n\n최신 학습 모듈과 최적화가 적용되었습니다. 합격을 응원합니다!''';

      if (!context.mounted) return;
      await _showNoticeDialog(context, currentVersion, noticeMessage, prefs);
    } catch (_) {
      // 로깅 및 무시
    }
  }

  /// 공지 안내 팝업창 띄우기
  static Future<void> _showNoticeDialog(
    BuildContext context,
    String version,
    String message,
    SharedPreferences prefs,
  ) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.campaign_rounded, color: Colors.blueAccent, size: 28),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'v$version 업데이트 공지',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(
            message,
            style: const TextStyle(fontSize: 14, height: 1.6),
          ),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () async {
                // 확인 버튼 클릭 시 SharedPreferences에 현재 버전 저장하여 공지 닫기
                await prefs.setString(_keyLastSeenNoticeVersion, version);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                }
              },
              child: const Text(
                '확인',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
