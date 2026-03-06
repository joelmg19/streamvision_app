import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class ChannelLogo extends StatelessWidget {
  final int channelId;
  final String logoText;
  final double size;
  final double borderRadius;

  const ChannelLogo({
    super.key,
    required this.channelId,
    required this.logoText,
    this.size = 40,
    this.borderRadius = 10,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppColors.channelGradientStart(channelId);
    final displayText = logoText.length > 3 ? logoText.substring(0, 3) : logoText;
    final fontSize = size * 0.28;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      alignment: Alignment.center,
      child: Text(
        displayText,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          letterSpacing: -0.5,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
