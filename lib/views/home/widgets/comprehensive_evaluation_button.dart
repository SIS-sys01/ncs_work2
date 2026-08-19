import 'package:flutter/material.dart';
import 'package:ncs_work/core/constants/app_colors.dart';

/// 하단 전 과목 통합 종합평가 버튼 위젯 (Stateless)
class ComprehensiveEvaluationButton extends StatelessWidget {
  final VoidCallback onPressed;

  const ComprehensiveEvaluationButton({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 56,
      margin: const EdgeInsets.all(16.0),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shuffle_rounded, color: Colors.white),
            SizedBox(width: 10),
            Text(
              '전 과목 통합 종합평가 (랜덤 셔플 풀이)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
