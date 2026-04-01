import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/channel_provider.dart';
import '../models/channel.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/channel_card.dart';
import '../widgets/section_header.dart';
import '../widgets/channel_logo.dart';

class HomeScreen extends StatelessWidget {
  final void Function(Channel) onChannelTap;

  const HomeScreen({super.key, required this.onChannelTap});

  @override
  Widget build(BuildContext context) {
    return Consumer<ChannelProvider>(builder: (context, provider, _) {
      if (provider.isLoading) {
        return const _LoadingState();
      }
      if (provider.hasError) {
        return _ErrorState(message: provider.errorMessage, onRetry: () => provider.loadChannels());
      }
      if (!provider.isLoaded) {
        return const _EmptyState();
      }

      final channels = provider.allChannels;
      final featured = channels.take(5).toList();
      final trending = channels.take(10).toList();

      // Group by category
      final Map<String, List<Channel>> byCategory = {};
      for (final ch in channels) {
        byCategory.putIfAbsent(ch.category, () => []).add(ch);
      }

      final categoryEntries = provider.categories
          .where((c) => c.id != 'all')
          .map((cat) => MapEntry(cat, byCategory[cat.id]?.take(8).toList() ?? []))
          .where((e) => e.value.isNotEmpty)
          .take(5)
          .toList();

      return CustomScrollView(slivers: [
        // ── Featured ──────────────────────────────────────────
        SliverToBoxAdapter(child: _FeaturedBanner(channels: featured, onTap: onChannelTap)),

        // ── Trending ──────────────────────────────────────────
        SliverToBoxAdapter(child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
          child: SectionHeader(title: 'Trending Ahora', emoji: '🔥'),
        )),
        SliverToBoxAdapter(child: _TrendingList(channels: trending, onTap: onChannelTap)),

        // ── Category rows ─────────────────────────────────────
        for (final entry in categoryEntries) ...[
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
            child: SectionHeader(title: entry.key.name, emoji: entry.key.emoji, count: byCategory[entry.key.id]?.length),
          )),
          SliverToBoxAdapter(child: SizedBox(
            height: 220,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: entry.value.length,
              itemBuilder: (context, index) {
                final ch = entry.value[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: SizedBox(width: 175, child: ChannelCard(channel: ch, onTap: () => onChannelTap(ch), onFavoriteToggle: () => context.read<ChannelProvider>().toggleFavorite(ch.id))),
                );
              },
            ),
          )),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ]);
    });
  }
}

// ── Featured Banner ────────────────────────────────────────────────────────────

class _FeaturedBanner extends StatefulWidget {
  final List<Channel> channels;
  final void Function(Channel) onTap;
  const _FeaturedBanner({required this.channels, required this.onTap});
  @override State<_FeaturedBanner> createState() => _FeaturedBannerState();
}

class _FeaturedBannerState extends State<_FeaturedBanner> {
  final PageController _ctrl = PageController();
  int _index = 0;

  @override void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    if (widget.channels.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 280,
      child: Stack(children: [
        PageView.builder(
          controller: _ctrl,
          itemCount: widget.channels.length,
          onPageChanged: (i) => setState(() => _index = i),
          itemBuilder: (_, i) {
            final ch = widget.channels[i];
            final color = AppColors.channelGradientStart(ch.id);
            return GestureDetector(
              onTap: () => widget.onTap(ch),
              child: Stack(fit: StackFit.expand, children: [
                Container(decoration: BoxDecoration(gradient: LinearGradient(colors: [color.withOpacity(0.9), color.withOpacity(0.3), AppColors.background], begin: Alignment.topLeft, end: Alignment.bottomRight))),
                const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(colors: [Color(0xF0080810), Colors.transparent], begin: Alignment.bottomCenter, end: Alignment.topCenter, stops: [0.0, 0.6]))),
                Positioned(left: 20, right: 20, bottom: 32, child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                  Row(children: [
                    Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: AppColors.liveRed, borderRadius: BorderRadius.circular(6)), child: const Text('EN VIVO', style: AppTextStyles.liveBadge)),
                    const SizedBox(width: 8),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: AppColors.accentPurple.withOpacity(0.3), borderRadius: BorderRadius.circular(6), border: Border.all(color: AppColors.accentPurple.withOpacity(0.4))), child: Text('DESTACADO', style: AppTextStyles.liveBadge.copyWith(color: AppColors.accentViolet))),
                  ]),
                  const SizedBox(height: 10),
                  Text(ch.name, style: AppTextStyles.displayMedium),
                  if (ch.groupTitle != null) ...[const SizedBox(height: 4), Text(ch.groupTitle!, style: AppTextStyles.bodyMedium)],
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
                    decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: AppColors.accentPurple.withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 4))]),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.play_arrow_rounded, color: Colors.white, size: 18), SizedBox(width: 6), Text('Ver ahora', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14))]),
                  ),
                ])),
              ]),
            );
          },
        ),
        Positioned(bottom: 16, right: 16, child: Row(children: List.generate(widget.channels.length, (i) {
          final active = i == _index;
          return GestureDetector(onTap: () => _ctrl.animateToPage(i, duration: const Duration(milliseconds: 350), curve: Curves.easeInOut),
            child: AnimatedContainer(duration: const Duration(milliseconds: 250), width: active ? 22 : 7, height: 7, margin: const EdgeInsets.only(left: 5), decoration: BoxDecoration(gradient: active ? AppColors.primaryGradient : null, color: active ? null : Colors.white.withOpacity(0.3), borderRadius: BorderRadius.circular(4))),
          );
        }))),
      ]),
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
      child: Column(children: List.generate(channels.length, (i) {
        final ch = channels[i];
        return GestureDetector(
          onTap: () => onTap(ch),
          child: Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
            child: Row(children: [
              SizedBox(width: 24, child: Text('${i + 1}', textAlign: TextAlign.center, style: AppTextStyles.trendingRank.copyWith(color: i < 3 ? AppColors.accentViolet : AppColors.textMuted))),
              const SizedBox(width: 10),
              ChannelLogo(channel: ch, size: 40, borderRadius: 10),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(ch.name, style: AppTextStyles.channelName, maxLines: 1, overflow: TextOverflow.ellipsis),
                if (ch.groupTitle != null) Text(ch.groupTitle!, style: AppTextStyles.programName, maxLines: 1, overflow: TextOverflow.ellipsis),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: AppColors.liveRed.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                child: Row(children: [
                  Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.liveRed, shape: BoxShape.circle)),
                  const SizedBox(width: 4),
                  Text('LIVE', style: AppTextStyles.labelSmall.copyWith(color: AppColors.liveRed)),
                ]),
              ),
            ]),
          ),
        );
      })),
    );
  }
}

// ── States ─────────────────────────────────────────────────────────────────────

class _LoadingState extends StatelessWidget {
  const _LoadingState();
  @override
  Widget build(BuildContext context) {
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 64, height: 64, decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 32)),
      const SizedBox(height: 24),
      const CircularProgressIndicator(color: AppColors.accentPurple, strokeWidth: 2),
      const SizedBox(height: 16),
      Text('Cargando canales...', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
      const SizedBox(height: 8),
      Text('Obteniendo playlist desde Free-TV/IPTV', style: AppTextStyles.bodySmall),
    ]));
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) {
    return Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 64, height: 64, decoration: BoxDecoration(color: AppColors.liveRed.withOpacity(0.15), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.liveRed.withOpacity(0.3))), child: const Icon(Icons.wifi_off_rounded, color: AppColors.liveRed, size: 32)),
      const SizedBox(height: 20),
      Text('Sin conexión', style: AppTextStyles.headlineMedium),
      const SizedBox(height: 8),
      Text('No se pudo cargar la playlist. Verifica tu conexión a internet.', style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
      const SizedBox(height: 20),
      GestureDetector(onTap: onRetry, child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
        decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(12)),
        child: const Text('Reintentar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      )),
    ])));
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Text('📺', style: TextStyle(fontSize: 48)),
      const SizedBox(height: 16),
      Text('Sin canales', style: AppTextStyles.headlineMedium),
    ]));
  }
}
