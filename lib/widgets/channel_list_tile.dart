import 'package:flutter/material.dart';
import '../models/channel.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'channel_logo.dart';
import 'live_badge.dart';
import 'quality_badge.dart';

class ChannelListTile extends StatelessWidget {
  final Channel channel;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;

  const ChannelListTile({super.key, required this.channel, required this.onTap, required this.onFavoriteToggle});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
        child: Row(children: [
          ChannelLogo(channel: channel, size: 44, borderRadius: 12),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(channel.name, style: AppTextStyles.channelName, maxLines: 1, overflow: TextOverflow.ellipsis)),
              if (channel.isLive) ...[const SizedBox(width: 6), const LiveBadge()],
            ]),
            const SizedBox(height: 3),
            Text(channel.currentProgram, style: AppTextStyles.programName, maxLines: 1, overflow: TextOverflow.ellipsis),
            if (channel.groupTitle != null) ...[
              const SizedBox(height: 3),
              Text(channel.groupTitle!, style: AppTextStyles.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ])),
          const SizedBox(width: 10),
          Column(children: [
            QualityBadge(quality: channel.quality),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: onFavoriteToggle,
              behavior: HitTestBehavior.opaque,
              child: Icon(channel.isFavorite ? Icons.star_rounded : Icons.star_border_rounded, size: 20, color: channel.isFavorite ? AppColors.warning : AppColors.textDisabled),
            ),
          ]),
        ]),
      ),
    );
  }
}
