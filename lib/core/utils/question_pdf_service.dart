import 'package:flutter/services.dart';

/// Question 폴더 내 각 과목/평가별 PDF 문제지 탐색 및 연동 서비스
class QuestionPdfService {
  static const Map<int, String> subjectFolders = {
    1: '01_직업상담 초기면담',
    2: '02_직업상담진단',
    3: '03_직업훈련상담',
    4: '04_직업상담행정',
    5: '05_진로상담',
    6: '06_직업정보수집',
    7: '07_취업상담',
    8: '08_직업정보제공',
    9: '09_직업복귀상담',
    10: '10_집단상담프로그램 운영',
    11: '11_취업지원 행사운영',
    12: '12_직업상담서비스 협업체계구축',
  };

  /// 특정 과목 및 평가 유형(internal / external)에 대응하는 상대 경로 가져오기
  static String getFolderPath({
    required int subjectId,
    required String type, // 'internal' 또는 'external'
  }) {
    final folderName = subjectFolders[subjectId] ?? '';
    final evalFolder = type == 'internal' ? '내부평가' : '외부평가';
    return 'Question/$folderName/$evalFolder';
  }

  /// 컴퓨터 절대 경로 안내 문자열 가져오기
  static String getAbsoluteFolderPath({
    required int subjectId,
    required String type,
  }) {
    final relPath = getFolderPath(subjectId: subjectId, type: type);
    return 'd:\\cskwork\\ncs_work\\${relPath.replaceAll('/', '\\')}';
  }

  /// 특정 과목 & 평가 유형(internal / external)에 등록된 PDF 에셋 리스트 조회
  static Future<List<String>> getPdfAssets({
    required int subjectId,
    required String type,
  }) async {
    final targetPrefix = '${getFolderPath(subjectId: subjectId, type: type)}/';

    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final assets = manifest.listAssets();
      return assets.where((path) {
        return path.startsWith(targetPrefix) && path.toLowerCase().endsWith('.pdf');
      }).toList();
    } catch (e) {
      return [];
    }
  }
}
