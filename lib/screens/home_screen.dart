import 'package:flutter/material.dart';
import '../data/channels_data.dart';
import '../models/channel.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/channel_card.dart';
import '../widgets/featured_banner.dart';
import '../widgets/section_header.dart';
import '../widgets/video_player_sheet.dart';
import '../widgets/channel_logo.dart';

class HomeScreen extends StatefulWidget {
  final List<Channel> channels;
  final void Function(int channelId) onFavoriteToggle;

  const HomeScreen({
    super.key,
    required this.channels,
    required this.onFavoriteToggle,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
    final featured = widget.channels.where((c) => c.isFeatured).toList();
    final trending = List<Channel>.from(widget.channels)
      ..sort((a, b) => b.viewers.compareTo(a.viewers));
    final topFive = trending.take(5).toList();

    final categories = ChannelsData.categories.where((c) => c.id != 'all');
    final categoryGroups = categories.map((cat) {
      return MapEntry(
        cat,
        widget.channels.where((ch) => ch.category == cat.id).take(6).toList(),
      );
    }).where((e) => e.value.isNotEmpty).toList();

    return CustomScrollView(
      slivers: [
        // ── Featured Banner ──────────────────────────────────────
        SliverToBoxAdapter(
          child: FeaturedBanner(
            channels: featured,
            onPlay: _openPlayer,
          ),
        ),

        // ── Trending ─────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
            child: SectionHeader(
              title: 'Trending Ahora',
              emoji: '🔥',
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: _TrendingList(
            channels: topFive,
            onTap: _openPlayer,
          ),
        ),

        // ── Category rows ─────────────────────────────────────────
        for (final entry in categoryGroups) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: SectionHeader(
                title: entry.key.name,
                emoji: entry.key.emoji,
                count: entry.value.length,
                onSeeAll: () {},
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 230,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20),
                itemCount: entry.value.length,
                itemBuilder: (context, index) {
                  final channel = entry.value[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 14),
                    child: SizedBox(
                      width: 180,
                      child: ChannelCard(
                        channel: channel,
                        onTap: () => _openPlayer(channel),
                        onFavoriteToggle: () =>
                            widget.onFavoriteToggle(channel.id),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],

        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}

// ── Trending List ──────────────────────────────────────────────────────────────

class _TrendingList extends StatelessWidget {
  final List<Channel> channels;
  final void Function(Channel) onTap;

  const _TrendingList({required this.channels, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: List.generate(channels.length, (i) {
          final ch = channels[i];
          return GestureDetector(
            onTap: () => onTap(ch),
            child: Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  // Rank
                  SizedBox(
                    width: 24,
                    child: Text(
                      '${i + 1}',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.trendingRank.copyWith(
                        color: i < 3
                            ? AppColors.accentViolet
                            : AppColors.textMuted,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Logo
                  ChannelLogo(
                    channelId: ch.id,
                    logoText: ch.logo,
                    size: 40,
                    borderRadius: 10,
                  ),
                  const SizedBox(width: 12),

                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(ch.name,
                            style: AppTextStyles.channelName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        Text(ch.currentProgram,
                            style: AppTextStyles.programName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),

                  // Viewers
                  Row(
                    children: [
                      const Icon(Icons.bolt_rounded,
                          size: 13, color: AppColors.accentViolet),
                      const SizedBox(width: 3),
                      Text(
                        '${ch.formattedViewers} viendo',
                        style: AppTextStyles.viewerCount.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
