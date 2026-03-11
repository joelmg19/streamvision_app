import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/channel.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'live_badge.dart';
import 'quality_badge.dart';
import 'channel_logo.dart';

class FeaturedBanner extends StatefulWidget {
  final List<Channel> channels;
  final void Function(Channel) onPlay;

  const FeaturedBanner({super.key, required this.channels, required this.onPlay});

  @override
  State<FeaturedBanner> createState() => _FeaturedBannerState();
}

class _FeaturedBannerState extends State<FeaturedBanner> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  @override
  void dispose() { _pageController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    if (widget.channels.isEmpty) return const SizedBox(height: 200);
    return SizedBox(
      height: 300,
      child: Stack(children: [
        PageView.builder(
          controller: _pageController,
          itemCount: widget.channels.length,
          onPageChanged: (i) => setState(() => _currentIndex = i),
          itemBuilder: (context, index) {
            final ch = widget.channels[index];
            return _BannerPage(channel: ch, onPlay: widget.onPlay);
          },
        ),
        Positioned(
          bottom: 16, right: 16,
          child: Row(children: List.generate(widget.channels.length, (i) {
            final isActive = i == _currentIndex;
            return GestureDetector(
              onTap: () => _pageController.animateToPage(i, duration: const Duration(milliseconds: 350), curve: Curves.easeInOut),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: isActive ? 22 : 7, height: 7,
                margin: const EdgeInsets.only(left: 5),
                decoration: BoxDecoration(
                  gradient: isActive ? AppColors.primaryGradient : null,
                  color: isActive ? null : Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            );
          })),
        ),
      ]),
    );
  }
}

class _BannerPage extends StatelessWidget {
  final Channel channel;
  final void Function(Channel) onPlay;

  const _BannerPage({required this.channel, required this.onPlay});

  @override
  Widget build(BuildContext context) {
    return Stack(fit: StackFit.expand, children: [
      channel.logoUrl != null && channel.logoUrl!.isNotEmpty
          ? CachedNetworkImage(imageUrl: channel.logoUrl!, fit: BoxFit.cover, color: Colors.black54, colorBlendMode: BlendMode.darken, errorWidget: (_, __, ___) => _GradientBg(channel: channel), placeholder: (_, __) => _GradientBg(channel: channel))
          : _GradientBg(channel: channel),
      const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(colors: [Color(0xF0080810), Color(0x80080810), Colors.transparent], begin: Alignment.bottomLeft, end: Alignment.topRight, stops: [0.0, 0.5, 1.0]))),
      const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF080810), Colors.transparent], begin: Alignment.bottomCenter, end: Alignment.topCenter, stops: [0.0, 0.5]))),
      Positioned(
        left: 20, right: 20, bottom: 32,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            const LiveBadge(),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: AppColors.accentPurple.withOpacity(0.3), borderRadius: BorderRadius.circular(6), border: Border.all(color: AppColors.accentPurple.withOpacity(0.4))),
              child: Text(channel.groupTitle?.toUpperCase() ?? 'DESTACADO', style: AppTextStyles.liveBadge.copyWith(color: AppColors.accentViolet), maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ]),
          const SizedBox(height: 10),
          Text(channel.name, style: AppTextStyles.displayMedium),
          const SizedBox(height: 4),
          Text(channel.country.isNotEmpty ? '${_flagEmoji(channel.country)}  ${channel.country}' : channel.description, style: AppTextStyles.bodyMedium),
          const SizedBox(height: 14),
          Row(children: [
            GestureDetector(
              onTap: () => onPlay(channel),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
                decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: AppColors.accentPurple.withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 4))]),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.play_arrow_rounded, color: Colors.white, size: 18), SizedBox(width: 6), Text('Ver ahora', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14))]),
              ),
            ),
            const Spacer(),
            QualityBadge(quality: channel.quality),
          ]),
        ]),
      ),
    ]);
  }

  String _flagEmoji(String countryCode) {
    const flags = {'US': '🇺🇸', 'GB': '🇬🇧', 'UK': '🇬🇧', 'ES': '🇪🇸', 'FR': '🇫🇷', 'DE': '🇩🇪', 'IT': '🇮🇹', 'PT': '🇵🇹', 'BR': '🇧🇷', 'MX': '🇲🇽', 'AR': '🇦🇷', 'RU': '🇷🇺', 'JP': '🇯🇵', 'CN': '🇨🇳', 'IN': '🇮🇳', 'AU': '🇦🇺', 'CA': '🇨🇦', 'QA': '🇶🇦', 'TR': '🇹🇷', 'INT': '🌐'};
    return flags[countryCode] ?? '📺';
  }
}

class _GradientBg extends StatelessWidget {
  final Channel channel;
  const _GradientBg({required this.channel});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.channelGradientStart(channel.id);
    return Container(
      decoration: BoxDecoration(gradient: LinearGradient(colors: [color.withOpacity(0.6), AppColors.background], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
      child: Center(child: ChannelLogo(channel: channel, size: 80, borderRadius: 20)),
    );
  }
}
