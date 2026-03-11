import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../models/channel.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'live_badge.dart';
import 'quality_badge.dart';
import 'channel_logo.dart';

class VideoPlayerSheet extends StatefulWidget {
  final Channel channel;
  final void Function(int channelId) onFavoriteToggle;
  final bool isFavorite;

  const VideoPlayerSheet({
    super.key,
    required this.channel,
    required this.onFavoriteToggle,
    required this.isFavorite,
  });

  @override
  State<VideoPlayerSheet> createState() => _VideoPlayerSheetState();
}

class _VideoPlayerSheetState extends State<VideoPlayerSheet> {
  late final Player _player;
  late final VideoController _controller;
  bool _isFullscreen = false;
  bool _isCopied = false;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _player = Player();
    _controller = VideoController(_player);
    _playStream();
  }

  Future<void> _playStream() async {
    final url = widget.channel.streamUrl;
    if (url == null || url.isEmpty) {
      setState(() {
        _hasError = true;
        _errorMessage = 'No hay URL de stream disponible';
      });
      return;
    }
    try {
      await _player.open(Media(url));
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'No se pudo cargar el stream: $e';
        });
      }
    }
  }

  void _toggleFullscreen() {
    setState(() => _isFullscreen = !_isFullscreen);
    if (_isFullscreen) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  void _copyStreamUrl() async {
    if (widget.channel.streamUrl != null) {
      await Clipboard.setData(ClipboardData(text: widget.channel.streamUrl!));
      setState(() => _isCopied = true);
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) setState(() => _isCopied = false);
    }
  }

  @override
  void dispose() {
    _player.dispose();
    // Restore orientation when closing
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isFullscreen) {
      return _FullscreenPlayer(
        controller: _controller,
        player: _player,
        channel: widget.channel,
        onExitFullscreen: _toggleFullscreen,
      );
    }

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40, height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // ── Video Player ──────────────────────────────────────
          _VideoArea(
            controller: _controller,
            player: _player,
            channel: widget.channel,
            hasError: _hasError,
            errorMessage: _errorMessage,
            onFullscreen: _toggleFullscreen,
            onRetry: _playStream,
          ),

          // ── Channel Header ────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(children: [
              ChannelLogo(channel: widget.channel, size: 48, borderRadius: 12),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(widget.channel.name, style: AppTextStyles.headlineMedium),
                const SizedBox(height: 4),
                Row(children: [
                  if (widget.channel.isLive) ...[const LiveBadge(), const SizedBox(width: 8)],
                  QualityBadge(quality: widget.channel.quality),
                  if (widget.channel.country.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(widget.channel.country, style: AppTextStyles.labelSmall),
                    ),
                  ],
                ]),
              ])),
              // Playback status indicator
              StreamBuilder(
                stream: _player.stream.buffering,
                builder: (_, snap) {
                  final buffering = snap.data ?? false;
                  return Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: widget.isFavorite
                          ? AppColors.warning.withOpacity(0.15)
                          : Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: widget.isFavorite
                          ? AppColors.warning.withOpacity(0.3)
                          : AppColors.border),
                    ),
                    child: buffering
                        ? const Padding(
                            padding: EdgeInsets.all(10),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.accentPurple,
                            ),
                          )
                        : GestureDetector(
                            onTap: () => widget.onFavoriteToggle(widget.channel.id),
                            child: Icon(
                              widget.isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
                              size: 20,
                              color: widget.isFavorite ? AppColors.warning : AppColors.textMuted,
                            ),
                          ),
                  );
                },
              ),
            ]),
          ),

          const SizedBox(height: 16),

          // ── Playback Controls ─────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _PlaybackControls(player: _player, onCopyUrl: _copyStreamUrl, isCopied: _isCopied),
          ),

          // ── Channel Info ──────────────────────────────────────
          if (widget.channel.groupTitle != null || widget.channel.currentProgram.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Column(children: [
                if (widget.channel.groupTitle != null)
                  _InfoRow(icon: Icons.category_rounded, label: 'Categoría', value: widget.channel.groupTitle!),
                if (widget.channel.currentProgram.isNotEmpty && widget.channel.currentProgram != 'En directo')
                  _InfoRow(icon: Icons.tv_rounded, label: 'Programa', value: widget.channel.currentProgram),
              ]),
            ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ── Video Area ─────────────────────────────────────────────────────────────────

class _VideoArea extends StatelessWidget {
  final VideoController controller;
  final Player player;
  final Channel channel;
  final bool hasError;
  final String errorMessage;
  final VoidCallback onFullscreen;
  final VoidCallback onRetry;

  const _VideoArea({
    required this.controller,
    required this.player,
    required this.channel,
    required this.hasError,
    required this.errorMessage,
    required this.onFullscreen,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 210,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(fit: StackFit.expand, children: [
        if (hasError)
          _ErrorPlaceholder(channel: channel, message: errorMessage, onRetry: onRetry)
        else
          Video(
            controller: controller,
            controls: NoVideoControls,
            fill: Colors.black,
          ),

        // Top overlay: channel name + live badge
        Positioned(
          top: 10, left: 12, right: 12,
          child: Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 6, height: 6,
                  margin: const EdgeInsets.only(right: 5),
                  decoration: const BoxDecoration(color: AppColors.liveRed, shape: BoxShape.circle),
                ),
                Text(channel.name,
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
              ]),
            ),
            const Spacer(),
            // Fullscreen button
            GestureDetector(
              onTap: onFullscreen,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.fullscreen_rounded, color: Colors.white, size: 18),
              ),
            ),
          ]),
        ),

        // Bottom: buffering + play/pause overlay
        Positioned(
          bottom: 10, left: 12, right: 12,
          child: StreamBuilder(
            stream: player.stream.playing,
            builder: (_, snap) {
              return Row(children: [
                // Play/Pause
                GestureDetector(
                  onTap: () => player.playOrPause(),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: AppColors.accentPurple.withOpacity(0.5), blurRadius: 12)],
                    ),
                    child: Icon(
                      (snap.data ?? false) ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: Colors.white, size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Volume
                StreamBuilder(
                  stream: player.stream.volume,
                  builder: (_, volSnap) {
                    final vol = volSnap.data ?? 100.0;
                    return GestureDetector(
                      onTap: () => player.setVolume(vol > 0 ? 0 : 100),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          vol > 0 ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                          color: Colors.white, size: 16,
                        ),
                      ),
                    );
                  },
                ),
                const Spacer(),
                // Buffering indicator
                StreamBuilder(
                  stream: player.stream.buffering,
                  builder: (_, bufSnap) {
                    if (bufSnap.data == true) {
                      return const SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ]);
            },
          ),
        ),
      ]),
    );
  }
}

// ── Fullscreen Player ──────────────────────────────────────────────────────────

class _FullscreenPlayer extends StatelessWidget {
  final VideoController controller;
  final Player player;
  final Channel channel;
  final VoidCallback onExitFullscreen;

  const _FullscreenPlayer({
    required this.controller,
    required this.player,
    required this.channel,
    required this.onExitFullscreen,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(fit: StackFit.expand, children: [
        Video(
          controller: controller,
          controls: NoVideoControls,
          fill: Colors.black,
        ),
        // Exit fullscreen button
        Positioned(
          top: 48, right: 16,
          child: GestureDetector(
            onTap: onExitFullscreen,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.fullscreen_exit_rounded, color: Colors.white, size: 24),
            ),
          ),
        ),
        // Channel name overlay
        Positioned(
          top: 52, left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 7, height: 7,
                margin: const EdgeInsets.only(right: 6),
                decoration: const BoxDecoration(color: AppColors.liveRed, shape: BoxShape.circle),
              ),
              Text(channel.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ]),
          ),
        ),
        // Center play/pause
        Center(
          child: StreamBuilder(
            stream: player.stream.playing,
            builder: (_, snap) => GestureDetector(
              onTap: () => player.playOrPause(),
              child: AnimatedOpacity(
                opacity: 1.0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: AppColors.accentPurple.withOpacity(0.6), blurRadius: 24)],
                  ),
                  child: Icon(
                    (snap.data ?? false) ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: Colors.white, size: 36,
                  ),
                ),
              ),
            ),
          ),
        ),
        // Buffering spinner
        StreamBuilder(
          stream: player.stream.buffering,
          builder: (_, snap) {
            if (snap.data != true) return const SizedBox.shrink();
            return const Center(
              child: CircularProgressIndicator(color: AppColors.accentPurple, strokeWidth: 2),
            );
          },
        ),
      ]),
    );
  }
}

// ── Playback Controls Bar ──────────────────────────────────────────────────────

class _PlaybackControls extends StatelessWidget {
  final Player player;
  final VoidCallback onCopyUrl;
  final bool isCopied;

  const _PlaybackControls({required this.player, required this.onCopyUrl, required this.isCopied});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: player.stream.playing,
      builder: (_, snap) {
        final playing = snap.data ?? false;
        return Row(children: [
          // Play/Pause
          _CtrlBtn(
            icon: playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
            label: playing ? 'Pausar' : 'Reproducir',
            gradient: true,
            onTap: () => player.playOrPause(),
          ),
          const SizedBox(width: 10),
          // Stop
          _CtrlBtn(
            icon: Icons.stop_rounded,
            label: 'Detener',
            onTap: () => player.stop(),
          ),
          const SizedBox(width: 10),
          // Copy URL
          _CtrlBtn(
            icon: isCopied ? Icons.check_rounded : Icons.copy_rounded,
            label: isCopied ? 'Copiado' : 'Copiar URL',
            onTap: onCopyUrl,
          ),
        ]);
      },
    );
  }
}

class _CtrlBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool gradient;

  const _CtrlBtn({required this.icon, required this.label, required this.onTap, this.gradient = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          gradient: gradient ? AppColors.primaryGradient : null,
          color: gradient ? null : Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(10),
          border: gradient ? null : Border.all(color: AppColors.border),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 15, color: Colors.white),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
        ]),
      ),
    );
  }
}

// ── Error Placeholder ──────────────────────────────────────────────────────────

class _ErrorPlaceholder extends StatelessWidget {
  final Channel channel;
  final String message;
  final VoidCallback onRetry;

  const _ErrorPlaceholder({required this.channel, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.channelGradientStart(channel.id);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.4), Colors.black],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.signal_wifi_statusbar_connected_no_internet_4_rounded,
          color: Colors.white54, size: 36),
        const SizedBox(height: 10),
        Text('Stream no disponible', style: AppTextStyles.labelMedium.copyWith(color: Colors.white70)),
        const SizedBox(height: 4),
        Text('Puede estar geobloqueado o inactivo',
          style: AppTextStyles.bodySmall.copyWith(color: Colors.white38),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 14),
        GestureDetector(
          onTap: onRetry,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text('Reintentar', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ),
      ]),
    );
  }
}

// ── Info Row ───────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        Icon(icon, size: 14, color: AppColors.textMuted),
        const SizedBox(width: 8),
        Text('$label: ', style: AppTextStyles.bodySmall),
        Expanded(child: Text(value,
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary),
          maxLines: 1, overflow: TextOverflow.ellipsis,
        )),
      ]),
    );
  }
}
