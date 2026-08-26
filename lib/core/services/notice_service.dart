import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 앱 업데이트 후 첫 실행 시 변경 내역 공지 안내 서비스
class NoticeService {
  static const String _keyLastSeenNoticeVersion = 'last_seen_notice_version';

  /// 버전별 변경 및 추가 내역 공지 맵
  static const Map<String, String> _versionReleaseNotes = {
    '0.1.2': '''📢 v0.1.2 업데이트 안내

항상 직업상담사2급 과정평가형 앱을 이용해 주셔서 감사합니다! 이번 버전의 주요 업데이트 내역입니다.

[주요 변경 및 추가 사항]
1. 1직업상담 초기면담 내부평가 정답 동기화
   - v0.002 PDF 교재 원문과 100% 동일하게 문제, 정답, 키워드를 정동기화했습니다.

2. 자동 업데이트 확인 기능 개선
   - package_info_plus를 도입하여 앱을 실행하면 깃허브의 최신 버전을 자동으로 인식하도록 개선했습니다.

3. 오프라인 데이터베이스(v23) 최신화
   - 최신 공부 모듈 데이터가 적용되도록 데이터베이스를 최신화했습니다.

4. 업데이트 안내 공지 팝업 추가
   - 새 버전 업데이트 후 첫 실행 시 변경된 내용을 한눈에 확인할 수 있는 공지창을 추가했습니다.

열공하시고 좋은 결과 얻으시길 응원합니다!''',
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
