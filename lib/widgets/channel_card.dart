import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/channel.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'live_badge.dart';
import 'quality_badge.dart';
import 'channel_logo.dart';

class ChannelCard extends StatelessWidget {
  final Channel channel;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;

  const ChannelCard({super.key, required this.channel, required this.onTap, required this.onFavoriteToggle});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 12, offset: Offset(0, 4))],
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _Thumbnail(channel: channel),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                ChannelLogo(channel: channel, size: 32, borderRadius: 8),
                const SizedBox(width: 8),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(channel.name, style: AppTextStyles.channelName, maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(channel.country, style: AppTextStyles.bodySmall),
                ])),
                GestureDetector(
                  onTap: onFavoriteToggle,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(channel.isFavorite ? Icons.star_rounded : Icons.star_border_rounded, size: 18, color: channel.isFavorite ? AppColors.warning : AppColors.textDisabled),
                  ),
                ),
              ]),
              const SizedBox(height: 8),
              Text(channel.currentProgram, style: AppTextStyles.programName, maxLines: 1, overflow: TextOverflow.ellipsis),
              if (channel.groupTitle != null) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: AppColors.accentPurple.withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
                  child: Text(channel.groupTitle!, style: AppTextStyles.labelSmall.copyWith(color: AppColors.accentViolet), maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ],
            ]),
          ),
        ]),
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  final Channel channel;
  const _Thumbnail({required this.channel});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.channelGradientStart(channel.id);
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(fit: StackFit.expand, children: [
        channel.logoUrl != null && channel.logoUrl!.isNotEmpty
            ? CachedNetworkImage(imageUrl: channel.logoUrl!, fit: BoxFit.contain, placeholder: (_, __) => _gradientBg(color), errorWidget: (_, __, ___) => _gradientBg(color))
            : _gradientBg(color),
        const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.transparent, Color(0xCC000000)], begin: Alignment.topCenter, end: Alignment.bottomCenter, stops: [0.4, 1.0]))),
        Positioned(
          top: 8, left: 8, right: 8,
          child: Row(children: [
            if (channel.isLive) const LiveBadge(),
            const Spacer(),
            QualityBadge(quality: channel.quality),
          ]),
        ),
        Center(child: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(gradient: AppColors.primaryGradient, shape: BoxShape.circle, boxShadow: [BoxShadow(color: AppColors.accentPurple.withOpacity(0.5), blurRadius: 16)]),
          child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 24),
        )),
      ]),
    );
  }

  Widget _gradientBg(Color color) => Container(
    decoration: BoxDecoration(gradient: LinearGradient(colors: [color.withOpacity(0.8), color.withOpacity(0.3)], begin: Alignment.topLeft, end: Alignment.bottomRight)),
    child: Center(child: Text(channel.logo.length > 3 ? channel.logo.substring(0, 3) : channel.logo, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white70))),
  );
}
