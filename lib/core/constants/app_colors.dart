import 'package:flutter/material.dart';

/// 직업상담사 2급 앱 핵심 컬러 팔레트 (다크 모드 중심)
class AppColors {
  AppColors._();

  // Dark Theme Base Colors
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkCard = Color(0xFF26262B);

  // Light Theme Base Colors
  static const Color lightBackground = Color(0xFFF8F9FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFEDF2F7);

  // Accent & Text Colors
  static const Color primary = Color(0xFF4F46E5); // Indigo Accent
  static const Color textOffWhite = Color(0xFFF5F5F5);
  static const Color textMutedDark = Color(0xFFA0A0AB);

  static const Color textDark = Color(0xFF1A202C);
  static const Color textMutedLight = Color(0xFF718096);

  // Text Diff Highlighting Colors
  static const Color emeraldGreen = Color(0xFF00E676); // 일치 / 맞은 부분
  static const Color desaturatedRed = Color(0xFFFF5252); // 차이 / 틀린 부분
}
