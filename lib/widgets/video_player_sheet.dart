import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/channel.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'live_badge.dart';
import 'quality_badge.dart';
import 'progress_bar_widget.dart';
import 'channel_logo.dart';

class VideoPlayerSheet extends StatefulWidget {
  final Channel channel;
  final void Function(int channelId) onFavoriteToggle;

  const VideoPlayerSheet({
    super.key,
    required this.channel,
    required this.onFavoriteToggle,
  });

  @override
  State<VideoPlayerSheet> createState() => _VideoPlayerSheetState();
}

class _VideoPlayerSheetState extends State<VideoPlayerSheet> {
  bool _isPlaying = true;
  bool _isMuted = false;
  double _volume = 0.8;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // ── Video Area ─────────────────────────────────────────
          _VideoArea(
            channel: widget.channel,
            isPlaying: _isPlaying,
            onPlayPause: () => setState(() => _isPlaying = !_isPlaying),
            onClose: () => Navigator.pop(context),
            onFavoriteToggle: () => widget.onFavoriteToggle(widget.channel.id),
          ),

          // ── Controls ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(
              children: [
                // Program info
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.channel.name,
                            style: AppTextStyles.bodySmall,
                          ),
                          Text(
                            widget.channel.currentProgram,
                            style: AppTextStyles.headlineSmall,
                          ),
                        ],
                      ),
                    ),
                    QualityBadge(quality: widget.channel.quality),
                  ],
                ),
                const SizedBox(height: 12),

                // Progress
                ProgressBarWidget(progress: widget.channel.progress, height: 3),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(widget.channel.startTime,
                        style: AppTextStyles.timeLabel),
                    Text(widget.channel.endTime,
                        style: AppTextStyles.timeLabel),
                  ],
                ),
                const SizedBox(height: 16),

                // Playback buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _ControlButton(
                      icon: Icons.skip_previous_rounded,
                      onTap: () {},
                    ),
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: () => setState(() => _isPlaying = !_isPlaying),
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accentPurple.withOpacity(0.5),
                              blurRadius: 20,
                            ),
                          ],
                        ),
                        child: Icon(
                          _isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    _ControlButton(
                      icon: Icons.skip_next_rounded,
                      onTap: () {},
                    ),
                    const Spacer(),
                    _ControlButton(
                      icon: _isMuted
                          ? Icons.volume_off_rounded
                          : Icons.volume_up_rounded,
                      onTap: () => setState(() => _isMuted = !_isMuted),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 90,
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 3,
                          thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 6),
                          overlayShape: SliderComponentShape.noOverlay,
                          activeTrackColor: AppColors.accentPurple,
                          inactiveTrackColor:
                              Colors.white.withOpacity(0.15),
                          thumbColor: Colors.white,
                        ),
                        child: Slider(
                          value: _isMuted ? 0 : _volume,
                          min: 0,
                          max: 1,
                          onChanged: (v) =>
                              setState(() {
                                _volume = v;
                                _isMuted = false;
                              }),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Next program
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      ChannelLogo(
                        channelId: widget.channel.id,
                        logoText: widget.channel.logo,
                        size: 30,
                        borderRadius: 8,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'A continuación',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.textMuted,
                              ),
                            ),
                            Text(
                              widget.channel.nextProgram,
                              style: AppTextStyles.labelMedium.copyWith(
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        size: 18,
                        color: AppColors.textMuted,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VideoArea extends StatelessWidget {
  final Channel channel;
  final bool isPlaying;
  final VoidCallback onPlayPause;
  final VoidCallback onClose;
  final VoidCallback onFavoriteToggle;

  const _VideoArea({
    required this.channel,
    required this.isPlaying,
    required this.onPlayPause,
    required this.onClose,
    required this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Simulated stream
          Image.network(
            channel.thumbnailUrl,
            fit: BoxFit.cover,
            color: isPlaying ? Colors.black45 : Colors.black54,
            colorBlendMode: BlendMode.darken,
            errorBuilder: (_, __, ___) => Container(color: Colors.black87),
            loadingBuilder: (_, child, progress) {
              if (progress == null) return child;
              return Container(color: Colors.black87);
            },
          ),

          // Scan lines effect
          Opacity(
            opacity: 0.05,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Colors.black12],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.5, 1.0],
                ),
              ),
            ),
          ),

          // Top bar
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Row(
              children: [
                if (channel.isLive) const LiveBadge(),
                const Spacer(),
                _IconButton(
                  icon: channel.isFavorite
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                  color: channel.isFavorite
                      ? AppColors.warning
                      : Colors.white,
                  onTap: onFavoriteToggle,
                ),
                const SizedBox(width: 8),
                _IconButton(
                  icon: Icons.close_rounded,
                  color: Colors.white,
                  onTap: onClose,
                ),
              ],
            ),
          ),

          // Center play/pause
          if (!isPlaying)
            Center(
              child: GestureDetector(
                onTap: onPlayPause,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accentPurple.withOpacity(0.6),
                        blurRadius: 24,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
            ),

          // Bottom program name
          Positioned(
            bottom: 8,
            left: 12,
            right: 12,
            child: Text(
              channel.currentProgram,
              style: AppTextStyles.labelMedium
                  .copyWith(color: Colors.white.withOpacity(0.85)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _IconButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.55),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ControlButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(icon, color: AppColors.textSecondary, size: 26),
    );
  }
}
