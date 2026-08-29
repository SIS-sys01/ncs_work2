import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:ncs_work/core/services/notice_service.dart';
import 'package:ncs_work/core/services/update_checker_service.dart';
import 'package:ncs_work/data/datasources/database_helper.dart';
import 'package:ncs_work/data/models/subject_model.dart';
import 'package:ncs_work/viewmodels/theme_viewmodel.dart';
import 'package:ncs_work/views/home/widgets/comprehensive_evaluation_button.dart';
import 'package:ncs_work/views/home/widgets/subject_card.dart';
import 'package:ncs_work/views/subject_detail/subject_detail_screen.dart';

/// 메인 홈 화면 (ConsumerStatefulWidget)
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
    // 화면 시작 직후 업데이트 공지 팝업 및 깃허브 최신 버전 체크 실행
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await NoticeService.checkVersionNotice(context);
      if (mounted) {
        UpdateCheckerService.checkForUpdates(context);
      }
    });
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _appVersion = 'v${info.version} (Build ${info.buildNumber})';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await SystemNavigator.pop();
        exit(0);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            '직업상담사2급 과정평가형',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          actions: [
            IconButton(
              tooltip: isDark ? '라이트 모드로 전환' : '다크 모드로 전환',
              icon: Icon(
                isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                color: isDark ? Colors.amber : Colors.indigo,
              ),
              onPressed: () {
                ref.read(themeProvider.notifier).toggleTheme();
              },
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: SafeArea(
          child: FutureBuilder<List<SubjectModel>>(
            future: DatabaseHelper.instance.getSubjects(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final subjects = snapshot.data ?? [];

              return Column(
                children: [
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.all(16.0),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.1,
                      ),
                      itemCount: subjects.length,
                      itemBuilder: (context, index) {
                        final subject = subjects[index];
                        return SubjectCard(
                          subjectId: subject.id,
                          subjectName: subject.name,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SubjectDetailScreen(subject: subject),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  ComprehensiveEvaluationButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('각 과목 카드를 터치하여 해당 과목의 PDF 문제지를 확인하세요!'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                  if (_appVersion.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      child: Text(
                        '앱 시스템 구동 버전: $_appVersion',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
