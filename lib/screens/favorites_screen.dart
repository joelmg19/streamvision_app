import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/channel_provider.dart';
import '../models/channel.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/channel_card.dart';

class FavoritesScreen extends StatelessWidget {
  final void Function(Channel) onChannelTap;
  const FavoritesScreen({super.key, required this.onChannelTap});

  @override
  Widget build(BuildContext context) {
    return Consumer<ChannelProvider>(builder: (context, provider, _) {
      final favs = provider.favoriteChannels;
      return CustomScrollView(slivers: [
        SliverToBoxAdapter(child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          child: Row(children: [
            Container(width: 44, height: 44, decoration: BoxDecoration(color: AppColors.warning.withOpacity(0.15), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.warning.withOpacity(0.3))), child: const Icon(Icons.star_rounded, color: AppColors.warning, size: 22)),
            const SizedBox(width: 14),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Mis Favoritos', style: AppTextStyles.headlineLarge),
              Text('${favs.length} canal${favs.length != 1 ? "es" : ""} guardado${favs.length != 1 ? "s" : ""}', style: AppTextStyles.bodyMedium),
            ]),
          ]),
        )),
        if (favs.isEmpty)
          const SliverFillRemaining(child: _EmptyFavorites())
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate((context, i) {
                final ch = favs[i];
                return ChannelCard(channel: ch, onTap: () => onChannelTap(ch), onFavoriteToggle: () => context.read<ChannelProvider>().toggleFavorite(ch.id));
              }, childCount: favs.length),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.78, crossAxisSpacing: 12, mainAxisSpacing: 12),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ]);
    });
  }
}

class _EmptyFavorites extends StatelessWidget {
  const _EmptyFavorites();
  @override
  Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 40), child: Column(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 80, height: 80, decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.border)), child: const Icon(Icons.star_border_rounded, size: 36, color: AppColors.textDisabled)),
    const SizedBox(height: 20),
    const Text('Sin favoritos aún', style: AppTextStyles.headlineMedium),
    const SizedBox(height: 8),
    const Text('Pulsa el ⭐ en cualquier canal para guardarlo aquí', style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
  ])));
}
