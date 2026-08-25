import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

/// 깃허브 Releases 기반 자동 업데이트 체크 서비스
class UpdateCheckerService {
  static const String githubRepo = 'SIS-sys01/ncs_work2';
  static const String latestReleaseUrl =
      'https://api.github.com/repos/$githubRepo/releases/latest';

  /// 앱 시작 시 최신 버전 확인 및 팝업 띄우기
  static Future<void> checkForUpdates(BuildContext context) async {
    try {
      final response = await http.get(Uri.parse(latestReleaseUrl)).timeout(
        const Duration(seconds: 5),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final String latestVersion = (data['tag_name'] as String? ?? '').replaceAll('v', '');
        final String downloadUrl = data['html_url'] as String? ?? 'https://github.com/$githubRepo/releases';

        // 현재 앱의 설치 버전 (pubspec.yaml 버전 0.1.1 기준)
        const currentVersion = '0.1.1';

        if (_isNewerVersion(currentVersion, latestVersion)) {
          if (!context.mounted) return;
          _showUpdateDialog(context, latestVersion, downloadUrl);
        }
      }
    } catch (_) {
      // 인터넷 미연결 시 사용자 경험에 방해되지 않도록 무시
    }
  }

  /// 버전 숫자 비교 (예: '0.1.0' > '0.0.9')
  static bool _isNewerVersion(String current, String latest) {
    if (latest.isEmpty) return false;
    final currentParts = current.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final latestParts = latest.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    for (int i = 0; i < latestParts.length; i++) {
      final cur = i < currentParts.length ? currentParts[i] : 0;
      final lat = latestParts[i];
      if (lat > cur) return true;
      if (lat < cur) return false;
    }
    return false;
  }

  /// 업데이트 안내 팝업창
  static void _showUpdateDialog(BuildContext context, String latestVersion, String downloadUrl) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.system_update_rounded, color: Colors.blueAccent),
            SizedBox(width: 8),
            Text('새 버전 업데이트 안내', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          '새로운 버전(v$latestVersion)이 출시되었습니다!\n지금 최신 버전으로 업데이트하시겠습니까?',
          style: const TextStyle(fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('나중에', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final uri = Uri.parse(downloadUrl);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
            child: const Text('지금 업데이트'),
          ),
        ],
      ),
    );
  }
}
