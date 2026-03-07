import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color background = Color(0xFF080810);
  static const Color surface = Color(0xFF0F0F1E);
  static const Color card = Color(0xFF12121F);
  static const Color cardHover = Color(0xFF17172A);

  static const Color accentPurple = Color(0xFF7C3AED);
  static const Color accentCyan = Color(0xFF06B6D4);
  static const Color accentPink = Color(0xFFEC4899);
  static const Color accentViolet = Color(0xFF8B5CF6);

  static const Color liveRed = Color(0xFFEF4444);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF60A5FA);

  static const Color textPrimary = Color(0xFFE5E7EB);
  static const Color textSecondary = Color(0xFF9CA3AF);
  static const Color textMuted = Color(0xFF6B7280);
  static const Color textDisabled = Color(0xFF4B5563);

  static const Color border = Color(0x0FFFFFFF);
  static const Color borderMedium = Color(0x18FFFFFF);
  static const Color borderStrong = Color(0x33FFFFFF);

  static const Color quality4K = Color(0xFFFBBF24);
  static const Color qualityFHD = Color(0xFF60A5FA);
  static const Color qualityHD = Color(0xFF34D399);
  static const Color qualitySD = Color(0xFF9CA3AF);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [accentPurple, accentCyan],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient purplePinkGradient = LinearGradient(
    colors: [accentPurple, accentPink],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static List<Color> channelGradients = const [
    Color(0xFF7C3AED), Color(0xFFEF4444), Color(0xFFF59E0B),
    Color(0xFF10B981), Color(0xFF06B6D4), Color(0xFFEC4899),
    Color(0xFF8B5CF6), Color(0xFFF97316), Color(0xFF14B8A6),
    Color(0xFFA855F7),
  ];

  static Color channelGradientStart(int id) =>
      channelGradients[id % channelGradients.length];

  static Color qualityColor(String quality) {
    switch (quality) {
      case '4K': return quality4K;
      case 'FHD': return qualityFHD;
      case 'HD': return qualityHD;
      default: return qualitySD;
    }
  }
}
