import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ncs_work/core/constants/app_colors.dart';
import 'package:ncs_work/core/utils/question_pdf_service.dart';
import 'package:ncs_work/data/models/subject_model.dart';
import 'package:ncs_work/viewmodels/quiz_viewmodel.dart';
import 'package:ncs_work/views/quiz/quiz_screen.dart';

/// 과목 상세 선택 화면 (내부평가 / 외부평가 2개 직관적 버튼 제공)
class SubjectDetailScreen extends ConsumerWidget {
  final SubjectModel subject;

  const SubjectDetailScreen({
    super.key,
    required this.subject,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          subject.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),
              Text(
                '학습할 주관식 평가 유형을 선택하세요.',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                '100% 주관식 서술형 문제로 인출(Active Recall) 암기를 진행합니다.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textMutedDark,
                    ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _PdfHelperButton(
                      title: '내부평가 PDF',
                      icon: Icons.picture_as_pdf_rounded,
                      color: Colors.tealAccent,
                      onTap: () => _showPdfDialog(context, subject.id, 'internal', subject.name),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _PdfHelperButton(
                      title: '외부평가 PDF',
                      icon: Icons.picture_as_pdf_rounded,
                      color: Colors.indigoAccent,
                      onTap: () => _showPdfDialog(context, subject.id, 'external', subject.name),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: _EvaluationOptionCard(
                  title: '내부평가 연습 시작',
                  subtitle: subject.id == 1
                      ? '${subject.name} 내부평가 100% 주관식 (16문항)'
                      : '${subject.name} 내부평가 주관식 문제 (랜덤 10문항)',
                  icon: Icons.assignment_rounded,
                  accentColor: Colors.tealAccent,
                  isAvailable: true,
                  onTap: () {
                    ref.read(quizProvider.notifier).loadQuestions(
                          subjectId: subject.id,
                          type: 'internal',
                        );
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => QuizScreen(title: '${subject.name} - 내부평가'),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: _EvaluationOptionCard(
                  title: '외부평가 연습 시작',
                  subtitle: (subject.id == 1 || subject.id == 3)
                      ? '기술/서술/정의/개념/종류나열 핵심 주관식 (랜덤 10문항)'
                      : '외부평가 문제는 현재 미탑재 상태입니다.',
                  icon: Icons.menu_book_rounded,
                  accentColor: (subject.id == 1 || subject.id == 3) ? Colors.indigoAccent : Colors.grey,
                  isAvailable: subject.id == 1 || subject.id == 3,
                  badgeText: (subject.id == 1 || subject.id == 3) ? null : '미탑재',
                  onTap: () {
                    if (subject.id == 1 || subject.id == 3) {
                      ref.read(quizProvider.notifier).loadQuestions(
                            subjectId: subject.id,
                            type: 'external',
                          );
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => QuizScreen(title: '${subject.name} - 외부평가'),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${subject.name} 외부평가 문제는 현재 미탑재 상태입니다.'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  /// PDF 문제지 안내 및 목록 팝업
  void _showPdfDialog(BuildContext context, int subjectId, String type, String subjectName) async {
    final evalName = type == 'internal' ? '내부평가' : '외부평가';
    final pdfAssets = await QuestionPdfService.getPdfAssets(subjectId: subjectId, type: type);
    final absPath = QuestionPdfService.getAbsoluteFolderPath(subjectId: subjectId, type: type);

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.picture_as_pdf_rounded, color: Colors.redAccent, size: 28),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '$subjectName - $evalName PDF 문제지',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24, color: Colors.white24),
              if (pdfAssets.isEmpty) ...[
                const Text(
                  '📂 폴더에 아직 등록된 PDF 문제지 파일이 없습니다.',
                  style: TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 12),
                const Text(
                  '컴퓨터 아래 위치 폴더에 PDF 파일을 넣으시면 앱에서 자동으로 연동됩니다:',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black38,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: SelectableText(
                    absPath,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: Colors.cyanAccent,
                    ),
                  ),
                ),
              ] else ...[
                Text(
                  '총 ${pdfAssets.length}개의 PDF 문제지 파일이 등록되어 있습니다.',
                  style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: pdfAssets.length,
                    itemBuilder: (context, index) {
                      final fileName = pdfAssets[index].split('/').last;
                      return ListTile(
                        leading: const Icon(Icons.picture_as_pdf, color: Colors.redAccent),
                        title: Text(fileName, style: const TextStyle(color: Colors.white)),
                        subtitle: Text(pdfAssets[index], style: const TextStyle(color: Colors.white38, fontSize: 11)),
                        onTap: () {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('📄 [$fileName] 문제지를 선택하셨습니다.'),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey.shade700,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('닫기', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// PDF 보조 안내 버튼
class _PdfHelperButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _PdfHelperButton({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withValues(alpha: 0.6)),
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: Icon(icon, size: 20),
      label: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
      ),
    );
  }
}


/// 평가 선택 직관적 카드 위젯 (Stateless)
class _EvaluationOptionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final bool isAvailable;
  final String? badgeText;
  final VoidCallback onTap;

  const _EvaluationOptionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    this.isAvailable = true,
    this.badgeText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isAvailable ? accentColor.withValues(alpha: 0.5) : Colors.grey.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Stack(
            children: [
              if (badgeText != null)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade700,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      badgeText!,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: isAvailable
                          ? accentColor.withValues(alpha: 0.2)
                          : Colors.grey.withValues(alpha: 0.15),
                      child: Icon(
                        icon,
                        size: 36,
                        color: isAvailable ? accentColor : Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isAvailable ? null : theme.disabledColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isAvailable ? AppColors.textMutedDark : theme.disabledColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
