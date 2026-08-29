import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

void main() {
  test('PDF 파싱 원문 분석기', () {
    final dir = Directory('d:/cskwork/ncs_work/Question');
    final pFiles = dir.listSync(recursive: true).where((f) => f.path.endsWith('.pdf')).toList();
    
    if (pFiles.isEmpty) {
        print('PDF 파일이 없습니다!');
        return;
    }

    for (var f in pFiles) {
        if (f.path.contains('03_직업훈련상담') || f.path.contains('3직업훈련상담')) {
            print('\\n\\n================================\\n스캔 대상: \${f.path}');
            final document = PdfDocument(inputBytes: File(f.path).readAsBytesSync());
            final text = PdfTextExtractor(document).extractText();
            document.dispose();
            
            print('--- 뽑아낸 날것의 원문(RAW) 모형 앞부분 1500자 ---');
            print(text.substring(0, text.length > 1500 ? 1500 : text.length));
            print('-----------------------------------------');

            final qMatches = RegExp(r'(Q\d+\..*?)(?=Q\d+\.|$)', dotAll: true).allMatches(text);
            for (var match in qMatches) {
               String chunk = match.group(1) ?? '';
               print('==== 문항 매치 본문 조각 ====');
               print(chunk.substring(0, chunk.length > 100 ? 100 : chunk.length));
            }
        }
    }
  });
}
