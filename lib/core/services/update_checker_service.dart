import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:permission_handler/permission_handler.dart';

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
        
        String downloadUrl = data['html_url'] as String? ?? 'https://github.com/$githubRepo/releases';
        
        // assets 배열에서 apk 파일의 직접 다운로드 링크(browser_download_url) 우선 탐색
        final List<dynamic>? assets = data['assets'] as List<dynamic>?;
        if (assets != null && assets.isNotEmpty) {
          for (final asset in assets) {
            final String? name = asset['name'] as String?;
            if (name != null && name.toLowerCase().endsWith('.apk')) {
              downloadUrl = asset['browser_download_url'] as String? ?? downloadUrl;
              break;
            }
          }
        }

        // 현재 앱의 설치 버전 (package_info_plus를 통해 동적 로드)
        final packageInfo = await PackageInfo.fromPlatform();
        final String currentVersion = packageInfo.version;

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

  /// 업데이트 안내 팝업창 (다운로드 게이지바 포함)
  static void _showUpdateDialog(BuildContext context, String latestVersion, String downloadUrl) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _UpdateDialog(latestVersion: latestVersion, downloadUrl: downloadUrl),
    );
  }
}

class _UpdateDialog extends StatefulWidget {
  final String latestVersion;
  final String downloadUrl;

  const _UpdateDialog({required this.latestVersion, required this.downloadUrl});

  @override
  State<_UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<_UpdateDialog> {
  bool _isDownloading = false;
  double _progress = 0.0;
  String _statusText = '';

  Future<void> _startDownload() async {
    setState(() {
      _isDownloading = true;
      _statusText = '다운로드 준비 중...';
    });

    try {
      if (Platform.isAndroid) {
        // 알 수 없는 앱 설치 권한 요청
        await Permission.requestInstallPackages.request();
      }

      final tempDir = await getTemporaryDirectory();
      final savePath = '${tempDir.path}/update_latest.apk';

      final existingFile = File(savePath);
      if (await existingFile.exists()) {
        await existingFile.delete();
      }

      final dio = Dio();
      await dio.download(
        widget.downloadUrl,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            setState(() {
              _progress = received / total;
              _statusText = '다운로드 중... ${(_progress * 100).toStringAsFixed(1)}%';
            });
          }
        },
      );

      setState(() {
        _statusText = '다운로드 완료! 설치를 시작합니다.';
      });

      if (mounted) {
        Navigator.pop(context); // 팝업 닫기
        final result = await OpenFilex.open(savePath); // 자동 설치 창 호출
        if (result.type != ResultType.done) {
          // 호출 실패 시 안전망으로 브라우저 열기 시도
          final uri = Uri.parse(widget.downloadUrl);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusText = '오류가 발생했습니다: $e\n(재시도하거나 나중에 다시 시도해주세요.)';
          _isDownloading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.system_update_rounded, color: Colors.blueAccent),
          SizedBox(width: 8),
          Text('새 버전 업데이트 안내', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
      content: _isDownloading
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LinearProgressIndicator(
                  value: _progress,
                  backgroundColor: Colors.grey.shade200,
                  color: Colors.blueAccent,
                  minHeight: 10,
                  borderRadius: BorderRadius.circular(5),
                ),
                const SizedBox(height: 16),
                Text(
                  _statusText,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                ),
              ],
            )
          : Text(
              '새로운 버전(v\${widget.latestVersion})이 출시되었습니다!\\n지금 최신 버전으로 업데이트하시겠습니까?',
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
      actions: _isDownloading
          ? []
          : [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('나중에', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: _startDownload,
                child: const Text('지금 업데이트'),
              ),
            ],
    );
  }
}
