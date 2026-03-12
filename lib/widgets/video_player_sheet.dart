import 'dart:async';
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
  StreamSubscription<String>? _errorSub;
  StreamSubscription<bool>? _playingSub;
  StreamSubscription<dynamic>? _videoParamsSub;
  bool _isCopied = false;
  bool _hasError = false;
  String _errorMessage = '';
  bool _isLoading = true;
  bool _hasVideoFrame = false;
  bool _recoveryAttempted = false;
  Timer? _timeoutTimer;

  @override
  void initState() {
    super.initState();
    _player = Player();
    _controller = VideoController(_player);
    _bindPlayerStreams();
    _playStream();
  }

  void _bindPlayerStreams() {
    _errorSub = _player.stream.error.listen((err) {
      if (mounted && err.isNotEmpty && !_hasError) {
        _timeoutTimer?.cancel();
        setState(() {
          _hasError = true;
          _isLoading = false;
          _errorMessage = 'Stream no disponible.\nPuede estar caído o geobloqueado.';
        });
      }
    });

    // Keep this subscription to react to player state changes.
    _playingSub = _player.stream.playing.listen((_) {});

    _videoParamsSub = _player.stream.videoParams.listen((_) {
      if (!mounted) return;
      if (!_hasVideoFrame || _isLoading) {
        setState(() {
          _hasVideoFrame = true;
          _isLoading = false;
        });
      }
    });
  }

  Future<void> _playStream() async {
    if (!mounted) return;
    setState(() {
      _hasError = false;
      _isLoading = true;
      _errorMessage = '';
      _hasVideoFrame = false;
      _recoveryAttempted = false;
    });

    _timeoutTimer?.cancel();

    final url = widget.channel.streamUrl;
    if (url == null || url.isEmpty) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
          _errorMessage = 'No hay URL de stream disponible para este canal.';
        });
      }
      return;
    }

    try {
      await _player.open(Media(url));

      // If after 15s no video frame is rendered, try one recovery open.
      _timeoutTimer = Timer(const Duration(seconds: 15), () {
        if (mounted && !_hasError) {
          if (!_hasVideoFrame) {
            if (_player.state.playing && !_recoveryAttempted) {
              _recoverVideoSurface(url);
              return;
            }
            setState(() {
              _hasError = true;
              _isLoading = false;
              _errorMessage = _player.state.playing
                  ? 'Se detectó audio pero no video.\nReintenta o prueba otro canal.'
                  : 'El canal no responde.\nPuede estar inactivo o geobloqueado.';
            });
          }
        }
      });
    } catch (e) {
      _timeoutTimer?.cancel();
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
          _errorMessage = 'Error al conectar con el stream.';
        });
      }
    }
  }

  Future<void> _recoverVideoSurface(String url) async {
    _recoveryAttempted = true;
    try {
      await _player.stop();
      await _player.open(Media(url));
      _timeoutTimer?.cancel();
      _timeoutTimer = Timer(const Duration(seconds: 10), () {
        if (mounted && !_hasError && !_hasVideoFrame) {
          setState(() {
            _hasError = true;
            _isLoading = false;
            _errorMessage = 'No se pudo renderizar video para este stream.';
          });
        }
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
          _errorMessage = 'Error al reintentar la reproducción de video.';
        });
      }
    }
  }

  void _enterFullscreen(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: true,
        barrierColor: Colors.black,
        pageBuilder: (_, __, ___) => _FullscreenPlayer(
          controller: _controller,
          player: _player,
          channel: widget.channel,
          onExit: () {
            SystemChrome.setPreferredOrientations([
              DeviceOrientation.portraitUp,
              DeviceOrientation.portraitDown,
            ]);
            SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  void _copyStreamUrl() async {
    if (widget.channel.streamUrl != null) {
      await Clipboard.setData(ClipboardData(text: widget.channel.streamUrl!));
      if (!mounted) return;
      setState(() => _isCopied = true);
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) setState(() => _isCopied = false);
    }
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    _errorSub?.cancel();
    _playingSub?.cancel();
    _videoParamsSub?.cancel();
    _player.dispose();
    super.dispose();
  }

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
          // Handle bar
          Container(
            width: 40, height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // ── VIDEO AREA ────────────────────────────────────────
          _buildVideoArea(context),

          // ── Channel Header ────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(children: [
              ChannelLogo(channel: widget.channel, size: 48, borderRadius: 12),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(widget.channel.name,
                    style: AppTextStyles.headlineMedium,
                    maxLines: 1, overflow: TextOverflow.ellipsis),
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
                ]),
              ),
              GestureDetector(
                onTap: () => widget.onFavoriteToggle(widget.channel.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: widget.isFavorite
                        ? AppColors.warning.withOpacity(0.15)
                        : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: widget.isFavorite
                          ? AppColors.warning.withOpacity(0.3)
                          : AppColors.border,
                    ),
                  ),
                  child: Icon(
                    widget.isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
                    size: 20,
                    color: widget.isFavorite ? AppColors.warning : AppColors.textMuted,
                  ),
                ),
              ),
            ]),
          ),

          const SizedBox(height: 14),

          // ── Playback Controls ─────────────────────────────────
          if (!_hasError)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _PlaybackControls(
                player: _player,
                onCopyUrl: _copyStreamUrl,
                isCopied: _isCopied,
              ),
            ),

          // ── Info ──────────────────────────────────────────────
          if (widget.channel.groupTitle != null || widget.channel.currentProgram.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Column(children: [
                if (widget.channel.groupTitle != null)
                  _InfoRow(icon: Icons.category_rounded,
                    label: 'Categoría', value: widget.channel.groupTitle!),
                if (widget.channel.currentProgram.isNotEmpty &&
                    widget.channel.currentProgram != 'En directo')
                  _InfoRow(icon: Icons.tv_rounded,
                    label: 'Programa', value: widget.channel.currentProgram),
              ]),
            ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  /// CRITICAL FIX: Use LayoutBuilder to get exact pixel dimensions and pass
  /// explicit width/height to the Video widget.
  /// Without this, the native video renderer has no bounds → black screen.
  Widget _buildVideoArea(BuildContext ctx) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: LayoutBuilder(builder: (context, constraints) {
        final vw = constraints.maxWidth;
        final vh = vw * 9 / 16; // 16:9 aspect ratio

        return SizedBox(
          width: vw,
          height: vh,
          child: Stack(children: [

            // NOTE:
            // Avoid ClipRRect around native video renderers (Android SurfaceView/TextureView).
            // Clipping can cause a black frame on some devices while audio keeps playing.
            const Positioned.fill(
              child: ColoredBox(color: Colors.black),
            ),

                // ── Video widget with EXPLICIT w/h ─────────────
            if (!_hasError)
              Positioned.fill(
                child: Video(
                  controller: _controller,
                  width: vw,
                  height: vh,
                  controls: NoVideoControls,
                  fill: Colors.black,
                ),
              ),

                // ── Loading overlay ────────────────────────────
            if (_isLoading && !_hasError)
              Positioned.fill(
                child: ColoredBox(
                  color: Colors.black,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 30, height: 30,
                        child: CircularProgressIndicator(
                          color: AppColors.accentViolet, strokeWidth: 2.5),
                      ),
                      const SizedBox(height: 10),
                      Text('Conectando…',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: Colors.white54)),
                    ],
                  ),
                ),
              ),

            // Rounded border overlay (without clipping the video surface).
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                ),
              ),
            ),

            // ── Error overlay ──────────────────────────────
            if (_hasError)
              Positioned.fill(
                child: _ErrorPlaceholder(
                  channel: widget.channel,
                  message: _errorMessage,
                  onRetry: _playStream,
                ),
              ),

            // ── Top bar: name + fullscreen ─────────────────
            if (!_hasError)
              Positioned(
                top: 10, left: 12, right: 12,
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.65),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Container(
                        width: 6, height: 6,
                        margin: const EdgeInsets.only(right: 5),
                        decoration: const BoxDecoration(
                            color: AppColors.liveRed, shape: BoxShape.circle),
                      ),
                      Text(widget.channel.name,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 11,
                            fontWeight: FontWeight.w600),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    ]),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => _enterFullscreen(ctx),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.65),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.fullscreen_rounded,
                          color: Colors.white, size: 18),
                    ),
                  ),
                ]),
              ),

                // ── Bottom controls ────────────────────────────
            if (!_hasError)
              Positioned(
                bottom: 10, left: 12, right: 12,
                child: Row(children: [
                      // Play/pause
                      StreamBuilder<bool>(
                        stream: _player.stream.playing,
                        builder: (_, snap) => GestureDetector(
                          onTap: () => _player.playOrPause(),
                          child: Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              shape: BoxShape.circle,
                              boxShadow: [BoxShadow(
                                color: AppColors.accentPurple.withOpacity(0.5),
                                blurRadius: 10)],
                            ),
                            child: Icon(
                              (snap.data ?? false)
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              color: Colors.white, size: 18),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Volume
                      StreamBuilder<double>(
                        stream: _player.stream.volume,
                        builder: (_, snap) {
                          final muted = (snap.data ?? 100.0) == 0;
                          return GestureDetector(
                            onTap: () =>
                                _player.setVolume(muted ? 100.0 : 0.0),
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.55),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(
                                muted
                                    ? Icons.volume_off_rounded
                                    : Icons.volume_up_rounded,
                                color: Colors.white, size: 16),
                            ),
                          );
                        },
                      ),
                      const Spacer(),
                      // Buffering
                      StreamBuilder<bool>(
                        stream: _player.stream.buffering,
                        builder: (_, snap) {
                          if (snap.data != true) return const SizedBox.shrink();
                          return const SizedBox(
                            width: 14, height: 14,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white70),
                          );
                        },
                      ),
                ]),
              ),

          ]),
        );
      }),
    );
  }
}

// ── Fullscreen Player ──────────────────────────────────────────────────────────

class _FullscreenPlayer extends StatefulWidget {
  final VideoController controller;
  final Player player;
  final Channel channel;
  final VoidCallback onExit;

  const _FullscreenPlayer({
    required this.controller,
    required this.player,
    required this.channel,
    required this.onExit,
  });

  @override
  State<_FullscreenPlayer> createState() => _FullscreenPlayerState();
}

class _FullscreenPlayerState extends State<_FullscreenPlayer> {
  bool _showControls = true;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _startHideTimer();
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _showControls = false);
    });
  }

  void _onTap() {
    setState(() => _showControls = !_showControls);
    if (_showControls) _startHideTimer();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _onTap,
        behavior: HitTestBehavior.opaque,
        child: LayoutBuilder(builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;
          return Stack(children: [

            // ── Video with explicit size (critical) ────────────
            SizedBox(
              width: w, height: h,
              child: Video(
                controller: widget.controller,
                width: w, height: h,
                controls: NoVideoControls,
                fill: Colors.black,
              ),
            ),

            // ── Buffering ──────────────────────────────────────
            StreamBuilder<bool>(
              stream: widget.player.stream.buffering,
              builder: (_, snap) {
                if (snap.data != true) return const SizedBox.shrink();
                return const Center(
                  child: CircularProgressIndicator(
                      color: AppColors.accentViolet, strokeWidth: 3),
                );
              },
            ),

            // ── Controls overlay ───────────────────────────────
            AnimatedOpacity(
              opacity: _showControls ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 250),
              child: IgnorePointer(
                ignoring: !_showControls,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.75),
                        Colors.transparent,
                        Colors.black.withOpacity(0.6),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: SafeArea(child: Stack(children: [
                    // Top bar
                    Positioned(
                      top: 8, left: 8, right: 8,
                      child: Row(children: [
                        GestureDetector(
                          onTap: widget.onExit,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.fullscreen_exit_rounded,
                                color: Colors.white, size: 24),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                              color: AppColors.liveRed,
                              borderRadius: BorderRadius.circular(6)),
                          child: const Text('● LIVE',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(widget.channel.name,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 16),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                      ]),
                    ),

                    // Center play/pause
                    Center(
                      child: StreamBuilder<bool>(
                        stream: widget.player.stream.playing,
                        builder: (_, snap) => GestureDetector(
                          onTap: () {
                            widget.player.playOrPause();
                            _startHideTimer();
                          },
                          child: Container(
                            width: 68, height: 68,
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              shape: BoxShape.circle,
                              boxShadow: [BoxShadow(
                                color: AppColors.accentPurple.withOpacity(0.55),
                                blurRadius: 24)],
                            ),
                            child: Icon(
                              (snap.data ?? false)
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              color: Colors.white, size: 36),
                          ),
                        ),
                      ),
                    ),

                    // Bottom volume
                    Positioned(
                      bottom: 12, left: 12,
                      child: StreamBuilder<double>(
                        stream: widget.player.stream.volume,
                        builder: (_, snap) {
                          final muted = (snap.data ?? 100.0) == 0;
                          return GestureDetector(
                            onTap: () =>
                                widget.player.setVolume(muted ? 100.0 : 0.0),
                            child: Icon(
                              muted
                                  ? Icons.volume_off_rounded
                                  : Icons.volume_up_rounded,
                              color: Colors.white, size: 26),
                          );
                        },
                      ),
                    ),
                  ])),
                ),
              ),
            ),
          ]);
        }),
      ),
    );
  }
}

// ── Playback Controls ──────────────────────────────────────────────────────────

class _PlaybackControls extends StatelessWidget {
  final Player player;
  final VoidCallback onCopyUrl;
  final bool isCopied;

  const _PlaybackControls({
    required this.player, required this.onCopyUrl, required this.isCopied});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: player.stream.playing,
      builder: (_, snap) {
        final playing = snap.data ?? false;
        return Row(children: [
          _CtrlBtn(
            icon: playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
            label: playing ? 'Pausar' : 'Reproducir',
            gradient: true,
            onTap: () => player.playOrPause(),
          ),
          const SizedBox(width: 10),
          _CtrlBtn(
            icon: Icons.stop_rounded,
            label: 'Detener',
            onTap: () => player.stop(),
          ),
          const SizedBox(width: 10),
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
  const _CtrlBtn(
      {required this.icon, required this.label, required this.onTap, this.gradient = false});

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
          Text(label,
              style: const TextStyle(
                  color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
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
  const _ErrorPlaceholder(
      {required this.channel, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.channelGradientStart(channel.id);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.35), Colors.black],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 52, height: 52,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white24),
          ),
          child: const Icon(
            Icons.signal_wifi_statusbar_connected_no_internet_4_rounded,
            color: Colors.white54, size: 26),
        ),
        const SizedBox(height: 12),
        Text('Canal no disponible',
            style: AppTextStyles.labelMedium.copyWith(color: Colors.white70)),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(message,
            style: AppTextStyles.bodySmall.copyWith(color: Colors.white38),
            textAlign: TextAlign.center),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: onRetry,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.refresh_rounded, color: Colors.white, size: 15),
              SizedBox(width: 6),
              Text('Reintentar',
                  style: TextStyle(
                      color: Colors.white, fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ]),
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
        Expanded(
          child: Text(value,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary),
            maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ]),
    );
  }
}
