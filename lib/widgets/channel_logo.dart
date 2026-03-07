import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/channel.dart';
import '../theme/app_colors.dart';

class ChannelLogo extends StatelessWidget {
  final Channel channel;
  final double size;
  final double borderRadius;

  const ChannelLogo({super.key, required this.channel, this.size = 40, this.borderRadius = 10});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.channelGradientStart(channel.id);
    final displayText = channel.logo.length > 3 ? channel.logo.substring(0, 3) : channel.logo;
    final fontSize = size * 0.28;

    if (channel.logoUrl != null && channel.logoUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: CachedNetworkImage(
          imageUrl: channel.logoUrl!,
          width: size, height: size, fit: BoxFit.contain,
          placeholder: (_, __) => _fallback(color, displayText, fontSize),
          errorWidget: (_, __, ___) => _fallback(color, displayText, fontSize),
        ),
      );
    }
    return _fallback(color, displayText, fontSize);
  }

  Widget _fallback(Color color, String text, double fontSize) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color, color.withOpacity(0.6)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      alignment: Alignment.center,
      child: Text(text, style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5), textAlign: TextAlign.center),
    );
  }
}
