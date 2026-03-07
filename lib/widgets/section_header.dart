import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final String? emoji;
  final int? count;
  final VoidCallback? onSeeAll;

  const SectionHeader({super.key, required this.title, this.emoji, this.count, this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      if (emoji != null) ...[Text(emoji!, style: const TextStyle(fontSize: 18)), const SizedBox(width: 8)],
      Expanded(child: Text(title, style: AppTextStyles.sectionTitle)),
      if (count != null) ...[
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(color: AppColors.accentPurple.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
          child: Text('$count', style: AppTextStyles.labelSmall.copyWith(color: AppColors.accentViolet)),
        ),
        const SizedBox(width: 8),
      ],
      if (onSeeAll != null)
        GestureDetector(
          onTap: onSeeAll,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text('Ver todos', style: AppTextStyles.labelMedium.copyWith(color: AppColors.textMuted)),
            const SizedBox(width: 2),
            const Icon(Icons.chevron_right, size: 16, color: AppColors.textMuted),
          ]),
        ),
    ]);
  }
}
