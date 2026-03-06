import 'package:flutter/material.dart';
import '../data/channels_data.dart';
import '../models/channel.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/category_chip_widget.dart';
import '../widgets/channel_card.dart';
import '../widgets/channel_list_tile.dart';
import '../widgets/video_player_sheet.dart';

enum _ViewMode { grid, list }

class LiveTVScreen extends StatefulWidget {
  final List<Channel> channels;
  final void Function(int channelId) onFavoriteToggle;

  const LiveTVScreen({
    super.key,
    required this.channels,
    required this.onFavoriteToggle,
  });

  @override
  State<LiveTVScreen> createState() => _LiveTVScreenState();
}

class _LiveTVScreenState extends State<LiveTVScreen> {
  String _selectedCategory = 'all';
  _ViewMode _viewMode = _ViewMode.grid;

  List<Channel> get _filtered {
    if (_selectedCategory == 'all') return widget.channels;
    return widget.channels
        .where((c) => c.category == _selectedCategory)
        .toList();
  }

  void _openPlayer(Channel channel) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => VideoPlayerSheet(
        channel: channel,
        onFavoriteToggle: widget.onFavoriteToggle,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final liveCount = _filtered.where((c) => c.isLive).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ──────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('TV en Vivo',
                        style: AppTextStyles.headlineLarge),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '$liveCount',
                            style: AppTextStyles.bodyMedium
                                .copyWith(color: AppColors.success),
                          ),
                          TextSpan(
                            text: ' canales en emisión',
                            style: AppTextStyles.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // View mode toggle
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    _ViewModeButton(
                      icon: Icons.grid_view_rounded,
                      isActive: _viewMode == _ViewMode.grid,
                      onTap: () =>
                          setState(() => _viewMode = _ViewMode.grid),
                    ),
                    _ViewModeButton(
                      icon: Icons.list_rounded,
                      isActive: _viewMode == _ViewMode.list,
                      onTap: () =>
                          setState(() => _viewMode = _ViewMode.list),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ── Category tabs ────────────────────────────────────────
        const SizedBox(height: 16),
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: ChannelsData.categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final cat = ChannelsData.categories[index];
              return CategoryChipWidget(
                category: cat,
                isSelected: _selectedCategory == cat.id,
                onTap: () =>
                    setState(() => _selectedCategory = cat.id),
              );
            },
          ),
        ),
        const SizedBox(height: 16),

        // ── Channel list ─────────────────────────────────────────
        Expanded(
          child: _filtered.isEmpty
              ? const _EmptyState()
              : _viewMode == _ViewMode.grid
                  ? _GridView(
                      channels: _filtered,
                      onTap: _openPlayer,
                      onFavoriteToggle: widget.onFavoriteToggle,
                    )
                  : _ListView(
                      channels: _filtered,
                      onTap: _openPlayer,
                      onFavoriteToggle: widget.onFavoriteToggle,
                    ),
        ),
      ],
    );
  }
}

// ── Grid ───────────────────────────────────────────────────────────────────────

class _GridView extends StatelessWidget {
  final List<Channel> channels;
  final void Function(Channel) onTap;
  final void Function(int) onFavoriteToggle;

  const _GridView({
    required this.channels,
    required this.onTap,
    required this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.72,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: channels.length,
      itemBuilder: (context, index) {
        final ch = channels[index];
        return ChannelCard(
          channel: ch,
          onTap: () => onTap(ch),
          onFavoriteToggle: () => onFavoriteToggle(ch.id),
        );
      },
    );
  }
}

// ── List ───────────────────────────────────────────────────────────────────────

class _ListView extends StatelessWidget {
  final List<Channel> channels;
  final void Function(Channel) onTap;
  final void Function(int) onFavoriteToggle;

  const _ListView({
    required this.channels,
    required this.onTap,
    required this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: channels.length,
      itemBuilder: (context, index) {
        final ch = channels[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: ChannelListTile(
            channel: ch,
            onTap: () => onTap(ch),
            onFavoriteToggle: () => onFavoriteToggle(ch.id),
          ),
        );
      },
    );
  }
}

// ── View mode button ───────────────────────────────────────────────────────────

class _ViewModeButton extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _ViewModeButton({
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.accentPurple.withOpacity(0.25)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 18,
          color: isActive ? AppColors.accentViolet : AppColors.textMuted,
        ),
      ),
    );
  }
}

// ── Empty state ────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(
              Icons.tv_off_rounded,
              size: 32,
              color: AppColors.textDisabled,
            ),
          ),
          const SizedBox(height: 16),
          const Text('Sin canales disponibles',
              style: AppTextStyles.headlineSmall),
          const SizedBox(height: 6),
          const Text('Prueba con otra categoría',
              style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }
}
