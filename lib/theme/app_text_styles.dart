import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static const TextStyle displayLarge = TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.textPrimary, height: 1.2, letterSpacing: -0.5);
  static const TextStyle displayMedium = TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary, height: 1.3);
  static const TextStyle headlineLarge = TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary, height: 1.4);
  static const TextStyle headlineMedium = TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary, height: 1.4);
  static const TextStyle headlineSmall = TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary, height: 1.4);
  static const TextStyle bodyLarge = TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: AppColors.textSecondary, height: 1.5);
  static const TextStyle bodyMedium = TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: AppColors.textSecondary, height: 1.5);
  static const TextStyle bodySmall = TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textMuted, height: 1.4);
  static const TextStyle labelLarge = TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary, height: 1.4);
  static const TextStyle labelMedium = TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary, height: 1.4);
  static const TextStyle labelSmall = TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textSecondary, height: 1.3, letterSpacing: 0.5);
  static const TextStyle channelName = TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary, height: 1.3);
  static const TextStyle programName = TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textSecondary, height: 1.4);
  static const TextStyle liveBadge = TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.5);
  static const TextStyle qualityBadge = TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5, height: 1.2);
  static const TextStyle viewerCount = TextStyle(fontSize: 11, fontWeight: FontWeight.w400, color: Color(0xB3FFFFFF), height: 1.3);
  static const TextStyle timeLabel = TextStyle(fontSize: 11, fontWeight: FontWeight.w400, color: AppColors.textMuted, height: 1.3);
  static const TextStyle sectionTitle = TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary, height: 1.4);
  static const TextStyle categoryLabel = TextStyle(fontSize: 13, fontWeight: FontWeight.w500, height: 1.3);
  static const TextStyle trendingRank = TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.accentViolet, height: 1.3);
  static const TextStyle settingTitle = TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary, height: 1.4);
  static const TextStyle settingSubtitle = TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textMuted, height: 1.4);
}
