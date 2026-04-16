import 'package:flutter/material.dart';
import '../services/tmdb_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'webview_player_screen.dart';
import 'package:provider/provider.dart';
import '../providers/vod_provider.dart';

class DetailsScreen extends StatefulWidget {
  final String tmdbId;
  final String type; // 'movie' o 'tv'
  final String title;
  final String? posterPath;

  const DetailsScreen({
    super.key,
    required this.tmdbId,
    required this.type,
    required this.title,
    this.posterPath,
  });

  @override
  State<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  Map<String, dynamic>? _details;
  bool _isLoading = true;

  // Variables para Series (TV)
  List<dynamic> _seasons = [];
  Map<String, dynamic>? _selectedSeason;
  List<dynamic> _episodes = [];
  bool _isLoadingEpisodes = false;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    final data = await TmdbService.getDetails(widget.type, widget.tmdbId);
    if (mounted && data != null) {
      setState(() {
        _details = data;
        _isLoading = false;

        if (widget.type == 'tv' && data['seasons'] != null) {
          // Filtrar "Especiales" (Temporada 0) si lo prefieres, o dejarlos
          _seasons = (data['seasons'] as List).where((s) => s['season_number'] > 0).toList();
          if (_seasons.isNotEmpty) {
            _selectedSeason = _seasons[0];
            _loadEpisodes(_selectedSeason!['season_number']);
          }
        }
      });
    }
  }

  Future<void> _loadEpisodes(int seasonNumber) async {
    setState(() => _isLoadingEpisodes = true);
    final eps = await TmdbService.getSeasonEpisodes(widget.tmdbId, seasonNumber);
    if (mounted) {
      setState(() {
        _episodes = eps;
        _isLoadingEpisodes = false;
      });
    }
  }

  void _playMovie() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => WebviewPlayerScreen(
        tmdbId: widget.tmdbId,
        title: widget.title,
        type: 'movie',
      ),
    ));
  }

  void _playEpisode(int season, int episode) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => WebviewPlayerScreen(
        tmdbId: widget.tmdbId,
        title: widget.title,
        type: 'tv',
        season: season,
        episode: episode,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final backdropPath = _details?['backdrop_path'] ?? widget.posterPath;
    final overview = _details?['overview'] ?? 'No hay sinopsis disponible.';
    final credits = _details?['credits']?['cast'] as List<dynamic>? ?? [];

    // Tomamos solo los 10 primeros actores
    final cast = credits.take(10).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // CABECERA CON IMAGEN
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: AppColors.background,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                child: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
        // ── NUEVO BOTÓN DE FAVORITOS ──
        actions: [
          Consumer<VodProvider>(
            builder: (context, provider, _) {
              final isFav = provider.isFavorite(widget.tmdbId);
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                    child: Icon(
                      isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      color: isFav ? AppColors.liveRed : Colors.white,
                    ),
                  ),
                  onPressed: () {
                    provider.toggleFavorite({
                      'id': widget.tmdbId,
                      'title': widget.title,
                      'type': widget.type,
                      'poster_path': widget.posterPath ?? '',
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isFav ? 'Eliminado de favoritos' : 'Añadido a favoritos'),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],

        // ── FIN BOTÓN FAVORITOS ──

            flexibleSpace: FlexibleSpaceBar(
              background: backdropPath != null
                  ? Image.network(
                '${TmdbService.originalImageBaseUrl}$backdropPath',
                fit: BoxFit.cover,
              )
                  : Container(color: AppColors.surface),
            ),
          ),

          // CONTENIDO
          SliverToBoxAdapter(
            child: _isLoading
                ? const Padding(
              padding: EdgeInsets.only(top: 100),
              child: Center(child: CircularProgressIndicator(color: AppColors.accentViolet)),
            )
                : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.title, style: AppTextStyles.headlineMedium.copyWith(fontSize: 24)),
                  const SizedBox(height: 8),

                  // Botón PLAY para películas
                  if (widget.type == 'movie') ...[
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: _playMovie,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.play_arrow_rounded, color: Colors.white),
                            SizedBox(width: 8),
                            Text('Reproducir Película', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),
                  const Text('Sinopsis', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(overview, style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70)),

                  // ACTORES
                  if (cast.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Text('Reparto Principal', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: cast.length,
                        itemBuilder: (context, index) {
                          final actor = cast[index];
                          return Container(
                            width: 80,
                            margin: const EdgeInsets.only(right: 12),
                            child: Column(
                              children: [
                                CircleAvatar(
                                  radius: 35,
                                  backgroundColor: AppColors.surface,
                                  backgroundImage: actor['profile_path'] != null
                                      ? NetworkImage('${TmdbService.imageBaseUrl}${actor['profile_path']}')
                                      : null,
                                  child: actor['profile_path'] == null ? const Icon(Icons.person, color: Colors.white54) : null,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  actor['name'] ?? '',
                                  style: const TextStyle(color: Colors.white, fontSize: 10),
                                  maxLines: 2,
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],

                  // EPISODIOS (SOLO PARA SERIES)
                  if (widget.type == 'tv' && _seasons.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Temporadas', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        DropdownButton<Map<String, dynamic>>(
                          dropdownColor: AppColors.surface,
                          value: _selectedSeason,
                          style: const TextStyle(color: AppColors.accentViolet, fontWeight: FontWeight.bold),
                          underline: Container(),
                          items: _seasons.map((season) {
                            return DropdownMenuItem<Map<String, dynamic>>(
                              value: season,
                              child: Text(season['name'] ?? 'Temporada ${season['season_number']}'),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _selectedSeason = value);
                              _loadEpisodes(value['season_number']);
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_isLoadingEpisodes)
                      const Center(child: CircularProgressIndicator(color: AppColors.accentViolet))
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _episodes.length,
                        itemBuilder: (context, index) {
                          final ep = _episodes[index];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 120,
                                  height: 70,
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(8),
                                    image: ep['still_path'] != null
                                        ? DecorationImage(image: NetworkImage('${TmdbService.imageBaseUrl}${ep['still_path']}'), fit: BoxFit.cover)
                                        : null,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                  child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
                                )
                              ],
                            ),
                            title: Text('${ep['episode_number']}. ${ep['name']}', style: const TextStyle(color: Colors.white, fontSize: 14)),
                            subtitle: Text('${ep['runtime'] ?? '--'} min', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                            onTap: () => _playEpisode(_selectedSeason!['season_number'], ep['episode_number']),
                          );
                        },
                      ),
                  ],
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}