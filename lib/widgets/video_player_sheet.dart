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
  final bool launchInFullscreen;

  const VideoPlayerSheet({
    super.key,
    required this.channel,
    required this.onFavoriteToggle,
    required this.isFavorite,
    this.launchInFullscreen = false,
  });

  @override
  State<VideoPlayerSheet> createState() => _VideoPlayerSheetState();
}

class _VideoPlayerSheetState extends State<VideoPlayerSheet> {
  late Player _player;
  late VideoController _controller;
  StreamSubscription<String>? _errorSub;
  StreamSubscription<bool>? _playingSub;
  StreamSubscription<dynamic>? _videoParamsSub;
  StreamSubscription<dynamic>? _tracksSub;

  bool _hasError = false;
  String _errorMessage = '';
  bool _isLoading = true;
  bool _hasVideoFrame = false;
  bool _recoveryAttempted = false;
  bool _subtitleLoading = false;
  List<dynamic> _subtitleTracks = [];
  dynamic _selectedSubtitleTrack;
  Timer? _timeoutTimer;

  // Notificador para avisar a la Pantalla Completa cuando hay un error
  final ValueNotifier<String?> _errorNotifier = ValueNotifier(null);

  @override
  void initState() {
    super.initState();
    _initializePlayer();
    _playStream();
    if (widget.launchInFullscreen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _enterFullscreen(context);
        }
      });
    }
  }

  void _initializePlayer() {
    _player = Player();
    _controller = VideoController(_player);
    _bindPlayerStreams();
  }

  Future<void> _recreatePlayer() async {
    _timeoutTimer?.cancel();
    await _errorSub?.cancel();
    await _playingSub?.cancel();
    await _videoParamsSub?.cancel();
    await _tracksSub?.cancel();
    _player.dispose();
    _initializePlayer();
  }

  void _setErrorState(String message) {
    if (!mounted) return;
    _timeoutTimer?.cancel();
    _errorNotifier.value = message;
    setState(() {
      _hasError = true;
      _isLoading = false;
      _errorMessage = message;
    });
  }

  void _bindPlayerStreams() {
    _errorSub = _player.stream.error.listen((err) {
      final errorStr = err.toString();
      if (mounted && errorStr.isNotEmpty && errorStr != 'none' && !_hasError) {
        _setErrorState('Stream no disponible.\nPuede estar caído o geobloqueado.');
      }
    });

    _playingSub = _player.stream.playing.listen((_) {});

    _videoParamsSub = _player.stream.videoParams.listen((_) {
      if (!mounted) return;
      if (!_hasVideoFrame || _isLoading) {
        _timeoutTimer?.cancel();
        setState(() {
          _hasVideoFrame = true;
          _isLoading = false;
        });
      }
    });

    _tracksSub = _player.stream.tracks.listen((tracks) {
      if (!mounted) return;
      final dynamic dynTracks = tracks;
      final List<dynamic> subtitleTracks = [];
      try {
        final dynamic list = dynTracks.subtitle;
        if (list is List) {
          subtitleTracks.addAll(list);
        }
      } catch (_) {}

      setState(() {
        _subtitleTracks = subtitleTracks;
      });
    });
  }

  Future<void> _playStream() async {
    if (!mounted) return;
    _errorNotifier.value = null; // Reiniciar error
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
      _setErrorState('No hay URL de stream disponible para este canal.');
      return;
    }

    try {
      _timeoutTimer = Timer(const Duration(seconds: 20), () {
        if (mounted && !_hasError) {
          if (!_hasVideoFrame) {
            if (_player.state.playing && !_recoveryAttempted) {
              _recoverVideoSurface(url);
              return;
            }
            _setErrorState(_player.state.playing
                ? 'Se detectó audio pero no video.\nSin señal de imagen en este canal.'
                : 'Tiempo de conexión agotado.\nEl canal puede estar caído o geobloqueado.');

            if (!_player.state.playing) {
              _player.stop();
            }
          }
        }
      });

      await _player.open(Media(url));

    } catch (e) {
      _setErrorState('Error al conectar con el stream.');
    }
  }

  Future<void> _recoverVideoSurface(String url) async {
    _recoveryAttempted = true;
    try {
      await _recreatePlayer();

      if (!mounted) return;
      setState(() {
        _isLoading = true;
        _hasVideoFrame = false;
      });

      _timeoutTimer?.cancel();
      _timeoutTimer = Timer(const Duration(seconds: 10), () {
        if (mounted && !_hasError && !_hasVideoFrame) {
          _setErrorState('No se pudo renderizar video para este stream.');
          _player.stop();
        }
      });

      await _player.open(Media(url));

    } catch (_) {
      _setErrorState('Error al reintentar la reproducción de video.');
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
          onSubtitlesTap: _openSubtitleMenu,
          subtitleEnabled: _selectedSubtitleTrack != null,
          errorNotifier: _errorNotifier,
          onRetry: _playStream,
          onSystemExit: _resetPortraitMode,
          onExit: () {
            _resetPortraitMode();
            Navigator.of(context).pop();
          },
        ),
      ),
    ).then((_) {
      if (widget.launchInFullscreen && mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  String _subtitleLabel(dynamic track) {
    try {
      final dynamic title = track.title;
      if (title is String && title.trim().isNotEmpty) {
        return title.trim();
      }
    } catch (_) {}
    try {
      final dynamic language = track.language;
      if (language is String && language.trim().isNotEmpty) {
        return language.trim().toUpperCase();
      }
    } catch (_) {}
    return 'Subtítulo';
  }

  Future<void> _openSubtitleMenu() async {
    if (_subtitleLoading) return;
    final options = <dynamic>[null, ..._subtitleTracks];
    final selected = await showModalBottomSheet<dynamic>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Subtítulos',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 6),
            ...options.map((track) {
              final isOff = track == null;
              final label = isOff ? 'Desactivados' : _subtitleLabel(track);
              final isSelected = isOff
                  ? _selectedSubtitleTrack == null
                  : _selectedSubtitleTrack == track;
              return ListTile(
                title: Text(
                  label,
                  style: const TextStyle(color: Colors.white),
                ),
                trailing: isSelected
                    ? const Icon(Icons.check_rounded, color: AppColors.accentViolet)
                    : null,
                onTap: () => Navigator.of(context).pop(track),
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (!mounted || selected == null && _selectedSubtitleTrack == null) return;
    await _setSubtitleTrack(selected);
  }

  Future<void> _setSubtitleTrack(dynamic track) async {
    setState(() => _subtitleLoading = true);
    try {
      final dynamic dynPlayer = _player;
      if (track == null) {
        final noTrack = (SubtitleTrack as dynamic).no();
        await dynPlayer.setSubtitleTrack(noTrack);
      } else {
        await dynPlayer.setSubtitleTrack(track);
      }
      if (!mounted) return;
      setState(() => _selectedSubtitleTrack = track);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            track == null
                ? 'Subtítulos desactivados'
                : 'Subtítulos: ${_subtitleLabel(track)}',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Este canal no permite cambiar subtítulos o idiomas.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _subtitleLoading = false);
      }
    }
  }

  void _resetPortraitMode() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    _errorSub?.cancel();
    _playingSub?.cancel();
    _videoParamsSub?.cancel();
    _tracksSub?.cancel();
    _errorNotifier.dispose();
    _resetPortraitMode();
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
          Container(
            width: 40, height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          _buildVideoArea(context),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
        ],
      ),
    );
  }

  Widget _buildVideoArea(BuildContext ctx) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: LayoutBuilder(builder: (context, constraints) {
        final vw = constraints.maxWidth;
        final vh = vw * 9 / 16;
        return SizedBox(
          width: vw, height: vh,
          child: Stack(children: [
            const Positioned.fill(child: ColoredBox(color: Colors.black)),
            if (!_hasError)
              Positioned.fill(
                child: Video(
                  key: ValueKey(_controller.hashCode),
                  controller: _controller,
                  width: vw, height: vh,
                  controls: NoVideoControls,
                  fill: Colors.black,
                ),
              ),
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
            if (_hasError)
              Positioned.fill(
                child: _ErrorPlaceholder(
                  channel: widget.channel,
                  message: _errorMessage,
                  onRetry: _playStream,
                ),
              ),
            if (!_hasError)
              Positioned(
                top: 10, left: 12, right: 12,
                child: Row(children: [
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
  final VoidCallback onSubtitlesTap;
  final bool subtitleEnabled;
  final VoidCallback onSystemExit;
  final VoidCallback onExit;

  final ValueNotifier<String?> errorNotifier;
  final VoidCallback onRetry;

  const _FullscreenPlayer({
    required this.controller,
    required this.player,
    required this.channel,
    required this.onSubtitlesTap,
    required this.subtitleEnabled,
    required this.onSystemExit,
    required this.onExit,
    required this.errorNotifier,
    required this.onRetry,
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
    return PopScope(
      onPopInvokedWithResult: (_, __) => widget.onSystemExit(),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          onTap: _onTap,
          behavior: HitTestBehavior.opaque,
          child: LayoutBuilder(builder: (context, constraints) {
            final w = constraints.maxWidth;
            final h = constraints.maxHeight;

            return ValueListenableBuilder<String?>(
                valueListenable: widget.errorNotifier,
                builder: (context, errorMsg, child) {

                  final hasError = errorMsg != null;

                  return Stack(children: [
                    // 1. Reproductor de Video
                    if (!hasError)
                      SizedBox(
                        width: w, height: h,
                        child: Video(
                          key: ValueKey(widget.controller.hashCode),
                          controller: widget.controller,
                          width: w, height: h,
                          controls: NoVideoControls,
                          fill: Colors.black,
                        ),
                      ),

                    // 2. Indicador de Buffering (oculto si hay error)
                    if (!hasError)
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

                    // 3. Controles (ocultos si hay error)
                    if (!hasError)
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
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                        color: AppColors.liveRed,
                                        borderRadius: BorderRadius.circular(6)),
                                    child: const Text('● LIVE',
                                        style: TextStyle(
                                            color: Colors.white, fontSize: 10,
                                            fontWeight: FontWeight.w700)),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(widget.channel.name,
                                        style: const TextStyle(
                                            color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
                                        maxLines: 1, overflow: TextOverflow.ellipsis),
                                  ),
                                ]),
                              ),
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
                              Positioned(
                                bottom: 12, left: 12, right: 12,
                                child: Row(
                                  children: [
                                    StreamBuilder<double>(
                                      stream: widget.player.stream.volume,
                                      builder: (_, snap) {
                                        final muted = (snap.data ?? 100.0) == 0;
                                        return GestureDetector(
                                          onTap: () => widget.player.setVolume(muted ? 100.0 : 0.0),
                                          child: Icon(
                                            muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                                            color: Colors.white, size: 26,
                                          ),
                                        );
                                      },
                                    ),
                                    const Spacer(),
                                    GestureDetector(
                                      onTap: widget.onSubtitlesTap,
                                      child: Icon(
                                        widget.subtitleEnabled
                                            ? Icons.closed_caption_rounded
                                            : Icons.closed_caption_off_rounded,
                                        color: Colors.white, size: 26,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ])),
                          ),
                        ),
                      ),

                    // 4. Pantalla de Error en Fullscreen
                    if (hasError)
                      Positioned.fill(
                        child: Stack(
                            children: [
                              _ErrorPlaceholder(
                                channel: widget.channel,
                                message: errorMsg,
                                onRetry: widget.onRetry,
                              ),
                              // Botón para salir del fullscreen si hay error
                              Positioned(
                                top: 24,
                                left: 24,
                                child: SafeArea(
                                  child: GestureDetector(
                                    onTap: widget.onExit,
                                    child: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.5),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: Colors.white24)
                                      ),
                                      child: const Icon(Icons.close_rounded,
                                          color: Colors.white, size: 28),
                                    ),
                                  ),
                                ),
                              ),
                            ]
                        ),
                      ),
                  ]);
                }
            );
          }),
        ),
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
      width: double.infinity,  // <--- ¡Esto fuerza a que ocupe todo el ancho!
      height: double.infinity, // <--- ¡Esto fuerza a que ocupe todo el alto!
      decoration: BoxDecoration(
        color: Colors.black, // Fondo base sólido
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
        Text('Canal sin señal / no disponible',
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