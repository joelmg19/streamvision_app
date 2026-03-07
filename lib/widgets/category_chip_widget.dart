import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../models/channel.dart';

class CategoryChipWidget extends StatelessWidget {
  final ChannelCategory category;
  final bool isSelected;
  final VoidCallback onTap;

  const CategoryChipWidget({super.key, required this.category, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          gradient: isSelected ? LinearGradient(colors: [AppColors.accentPurple.withOpacity(0.3), AppColors.accentCyan.withOpacity(0.2)], begin: Alignment.centerLeft, end: Alignment.centerRight) : null,
          color: isSelected ? null : Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppColors.accentPurple.withOpacity(0.4) : AppColors.border),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(category.emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Text(category.name, style: AppTextStyles.categoryLabel.copyWith(
            color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          )),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.accentPurple.withOpacity(0.4) : Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('${category.count}', style: AppTextStyles.labelSmall.copyWith(color: isSelected ? AppColors.accentViolet : AppColors.textMuted)),
          ),
        ]),
      ),
    );
  }
}
