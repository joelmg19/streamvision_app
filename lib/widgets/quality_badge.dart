import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class QualityBadge extends StatelessWidget {
  final String quality;
  const QualityBadge({super.key, required this.quality});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.qualityColor(quality);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(quality, style: AppTextStyles.qualityBadge.copyWith(color: color)),
    );
  }
}
