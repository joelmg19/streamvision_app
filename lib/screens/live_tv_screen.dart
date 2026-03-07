import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/channel_provider.dart';
import '../models/channel.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/category_chip_widget.dart';
import '../widgets/channel_card.dart';
import '../widgets/channel_list_tile.dart';

enum _ViewMode { grid, list }

class LiveTVScreen extends StatefulWidget {
  final void Function(Channel) onChannelTap;
  const LiveTVScreen({super.key, required this.onChannelTap});

  @override State<LiveTVScreen> createState() => _LiveTVScreenState();
}

class _LiveTVScreenState extends State<LiveTVScreen> {
  _ViewMode _viewMode = _ViewMode.grid;

  @override
  Widget build(BuildContext context) {
    return Consumer<ChannelProvider>(builder: (context, provider, _) {
      final filtered = provider.filteredChannels;

      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('TV en Vivo', style: AppTextStyles.headlineLarge),
              RichText(text: TextSpan(children: [
                TextSpan(text: '${filtered.length}', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.success)),
                TextSpan(text: ' canales disponibles', style: AppTextStyles.bodyMedium),
              ])),
            ])),
            // View toggle
            Container(
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
              child: Row(children: [
                _ViewBtn(icon: Icons.grid_view_rounded, active: _viewMode == _ViewMode.grid, onTap: () => setState(() => _viewMode = _ViewMode.grid)),
                _ViewBtn(icon: Icons.list_rounded, active: _viewMode == _ViewMode.list, onTap: () => setState(() => _viewMode = _ViewMode.list)),
              ]),
            ),
          ]),
        ),

        // Categories
        const SizedBox(height: 16),
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: provider.categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final cat = provider.categories[i];
              return CategoryChipWidget(
                category: cat,
                isSelected: provider.selectedCategory == cat.id,
                onTap: () => context.read<ChannelProvider>().setCategory(cat.id),
              );
            },
          ),
        ),
        const SizedBox(height: 16),

        // Channel list
        Expanded(child: filtered.isEmpty
            ? _EmptyState(isLoading: provider.isLoading, onRetry: provider.loadChannels)
            : _viewMode == _ViewMode.grid
                ? _Grid(channels: filtered, onTap: widget.onChannelTap, provider: provider)
                : _List(channels: filtered, onTap: widget.onChannelTap, provider: provider)),
      ]);
    });
  }
}

class _Grid extends StatelessWidget {
  final List<Channel> channels;
  final void Function(Channel) onTap;
  final ChannelProvider provider;
  const _Grid({required this.channels, required this.onTap, required this.provider});

  @override
  Widget build(BuildContext context) => GridView.builder(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.78, crossAxisSpacing: 12, mainAxisSpacing: 12),
    itemCount: channels.length,
    itemBuilder: (_, i) {
      final ch = channels[i];
      return ChannelCard(channel: ch, onTap: () => onTap(ch), onFavoriteToggle: () => context.read<ChannelProvider>().toggleFavorite(ch.id));
    },
  );
}

class _List extends StatelessWidget {
  final List<Channel> channels;
  final void Function(Channel) onTap;
  final ChannelProvider provider;
  const _List({required this.channels, required this.onTap, required this.provider});

  @override
  Widget build(BuildContext context) => ListView.builder(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    itemCount: channels.length,
    itemBuilder: (_, i) {
      final ch = channels[i];
      return Padding(padding: const EdgeInsets.only(bottom: 8), child: ChannelListTile(channel: ch, onTap: () => onTap(ch), onFavoriteToggle: () => context.read<ChannelProvider>().toggleFavorite(ch.id)));
    },
  );
}

class _ViewBtn extends StatelessWidget {
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  const _ViewBtn({required this.icon, required this.active, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(onTap: onTap, child: AnimatedContainer(duration: const Duration(milliseconds: 200), padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: active ? AppColors.accentPurple.withOpacity(0.25) : Colors.transparent, borderRadius: BorderRadius.circular(8)), child: Icon(icon, size: 18, color: active ? AppColors.accentViolet : AppColors.textMuted)));
}

class _EmptyState extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onRetry;
  const _EmptyState({required this.isLoading, required this.onRetry});
  @override
  Widget build(BuildContext context) => Center(child: isLoading
      ? const CircularProgressIndicator(color: AppColors.accentPurple, strokeWidth: 2)
      : Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('📭', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 12),
          const Text('Sin canales en esta categoría', style: AppTextStyles.headlineSmall),
          const SizedBox(height: 16),
          GestureDetector(onTap: onRetry, child: Container(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10), decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(10)), child: const Text('Recargar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)))),
        ]));
}
