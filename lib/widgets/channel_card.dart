import 'package:flutter/material.dart';
import '../models/channel.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'live_badge.dart';
import 'quality_badge.dart';
import 'channel_logo.dart';
import 'progress_bar_widget.dart';

class ChannelCard extends StatelessWidget {
  final Channel channel;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;

  const ChannelCard({
    super.key,
    required this.channel,
    required this.onTap,
    required this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Thumbnail ─────────────────────────────────────
            _Thumbnail(channel: channel),

            // ── Bottom info ───────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ChannelLogo(
                        channelId: channel.id,
                        logoText: channel.logo,
                        size: 32,
                        borderRadius: 8,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              channel.name,
                              style: AppTextStyles.channelName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              channel.country,
                              style: AppTextStyles.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: onFavoriteToggle,
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            channel.isFavorite
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            size: 18,
                            color: channel.isFavorite
                                ? AppColors.warning
                                : AppColors.textDisabled,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    channel.currentProgram,
                    style: AppTextStyles.programName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time_rounded,
                        size: 11,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: ProgressBarWidget(progress: channel.progress),
                      ),
                      const SizedBox(width: 6),
                      Text(channel.endTime, style: AppTextStyles.timeLabel),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  final Channel channel;

  const _Thumbnail({required this.channel});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background image
          Image.network(
            channel.thumbnailUrl,
            fit: BoxFit.cover,
            color: Colors.black38,
            colorBlendMode: BlendMode.darken,
            errorBuilder: (_, __, ___) => Container(
              color: AppColors.surface,
              child: const Icon(
                Icons.tv_rounded,
                color: AppColors.textDisabled,
                size: 32,
              ),
            ),
            loadingBuilder: (_, child, progress) {
              if (progress == null) return child;
              return Container(color: AppColors.surface);
            },
          ),

          // Gradient overlay
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, Color(0xCC000000)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.4, 1.0],
              ),
            ),
          ),

          // Top badges
          Positioned(
            top: 8,
            left: 8,
            right: 8,
            child: Row(
              children: [
                if (channel.isLive) const LiveBadge(),
                const Spacer(),
                QualityBadge(quality: channel.quality),
              ],
            ),
          ),

          // Viewer count
          Positioned(
            bottom: 8,
            left: 10,
            child: Row(
              children: [
                const Icon(Icons.people_rounded, size: 12, color: Color(0xB3FFFFFF)),
                const SizedBox(width: 4),
                Text(channel.formattedViewers, style: AppTextStyles.viewerCount),
              ],
            ),
          ),

          // Play icon overlay
          Center(
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accentPurple.withOpacity(0.5),
                    blurRadius: 16,
                  ),
                ],
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
