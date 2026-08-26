import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 앱 업데이트 후 첫 실행 시 변경 내역 공지 안내 서비스
class NoticeService {
  static const String _keyLastSeenNoticeVersion = 'last_seen_notice_version';

  /// 버전별 변경 및 추가 내역 공지 맵
  static const Map<String, String> _versionReleaseNotes = {
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
