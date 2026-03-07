import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class ProgressBarWidget extends StatelessWidget {
  final int progress;
  final double height;
  const ProgressBarWidget({super.key, required this.progress, this.height = 3});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: LinearProgressIndicator(
        value: progress / 100,
        minHeight: height,
        backgroundColor: Colors.white.withOpacity(0.1),
        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accentPurple),
      ),
    );
  }
}
