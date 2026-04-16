import 'package:flutter/material.dart';
import '../services/tmdb_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'details_screen.dart';

class MoviesScreen extends StatefulWidget {
  const MoviesScreen({super.key});

  @override
  State<MoviesScreen> createState() => _MoviesScreenState();
}

class _MoviesScreenState extends State<MoviesScreen> {
  bool _isLoading = true;

  List<dynamic> _trendingMovies = [];
  List<dynamic> _trendingTv = [];
  List<dynamic> _anime = [];
  List<dynamic> _kDramas = [];

  @override
  void initState() {
    super.initState();
    _loadAllContent();
  }

  Future<void> _loadAllContent() async {
    // Cargamos todo en paralelo para que sea más rápido
    final results = await Future.wait([
      TmdbService.getTrendingMovies(),
      TmdbService.getTrendingTv(),
      TmdbService.getAnime(),
      TmdbService.getKDramas(),
    ]);

    if (mounted) {
      setState(() {
        _trendingMovies = results[0];
        _trendingTv = results[1];
        _anime = results[2];
        _kDramas = results[3];
        _isLoading = false;
      });
    }
  }

  void _openDetails(Map<String, dynamic> item, String type) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DetailsScreen(
          tmdbId: item['id'].toString(),
          title: item['title'] ?? item['name'] ?? 'Desconocido',
          type: type,
          posterPath: item['poster_path'],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.accentViolet));
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          _buildSection('Películas en Tendencia', _trendingMovies, 'movie'),
          _buildSection('Series Populares', _trendingTv, 'tv'),
          _buildSection('Anime', _anime, 'tv'),
          _buildSection('K-Dramas', _kDramas, 'tv'),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<dynamic> items, String type) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Text(title, style: AppTextStyles.headlineMedium.copyWith(fontSize: 18)),
        ),
        SizedBox(
          height: 180, // Altura de las portadas
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final posterPath = item['poster_path'];

              return GestureDetector(
                onTap: () => _openDetails(item, type),
                child: Container(
                  width: 120, // Ancho de la portada
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: AppColors.surface,
                    image: posterPath != null
                        ? DecorationImage(
                      image: NetworkImage('${TmdbService.imageBaseUrl}$posterPath'),
                      fit: BoxFit.cover,
                    )
                        : null,
                  ),
                  child: posterPath == null
                      ? const Center(child: Icon(Icons.movie, color: Colors.white54))
                      : null,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}