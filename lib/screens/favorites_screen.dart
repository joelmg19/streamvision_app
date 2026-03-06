import 'package:flutter/material.dart';
import '../models/channel.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/channel_card.dart';
import '../widgets/video_player_sheet.dart';

class FavoritesScreen extends StatelessWidget {
  final List<Channel> favoriteChannels;
  final void Function(int channelId) onFavoriteToggle;

  const FavoritesScreen({
    super.key,
    required this.favoriteChannels,
    required this.onFavoriteToggle,
  });

  void _openPlayer(BuildContext context, Channel channel) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => VideoPlayerSheet(
        channel: channel,
        onFavoriteToggle: onFavoriteToggle,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // ── Header ──────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.warning.withOpacity(0.3)),
                  ),
                  child: const Icon(
                    Icons.star_rounded,
                    color: AppColors.warning,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Mis Favoritos',
                        style: AppTextStyles.headlineLarge),
                    Text(
                      '${favoriteChannels.length} canal${favoriteChannels.length != 1 ? "es" : ""} guardado${favoriteChannels.length != 1 ? "s" : ""}',
                      style: AppTextStyles.bodyMedium,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // ── Content ──────────────────────────────────────────────
        if (favoriteChannels.isEmpty)
          const SliverFillRemaining(child: _EmptyFavorites())
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final ch = favoriteChannels[index];
                  return ChannelCard(
                    channel: ch,
                    onTap: () => _openPlayer(context, ch),
                    onFavoriteToggle: () => onFavoriteToggle(ch.id),
                  );
                },
                childCount: favoriteChannels.length,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.72,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}

class _EmptyFavorites extends StatelessWidget {
  const _EmptyFavorites();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(
                Icons.tv_rounded,
                size: 36,
                color: AppColors.textDisabled,
              ),
            ),
            const SizedBox(height: 20),
            const Text('Sin favoritos aún',
                style: AppTextStyles.headlineMedium),
            const SizedBox(height: 8),
            const Text(
              'Marca canales como favoritos pulsando el ícono de estrella ⭐',
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
