import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/channel.dart';
import '../providers/channel_provider.dart';
import '../providers/vod_provider.dart';
import '../services/tmdb_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/channel_list_tile.dart';
import 'details_screen.dart';

class FavoritesScreen extends StatelessWidget {
  final void Function(Channel) onChannelTap;

  const FavoritesScreen({super.key, required this.onChannelTap});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // Dos pestañas: TV y VOD
      child: Column(
        children: [
          // CABECERA Y TABS
          Container(
            padding: const EdgeInsets.only(top: 20),
            color: AppColors.background,
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text('Mis Favoritos', style: AppTextStyles.headlineLarge),
                ),
                SizedBox(height: 16),
                TabBar(
                  indicatorColor: AppColors.accentViolet,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white54,
                  dividerColor: Colors.transparent,
                  tabs: [
                    Tab(text: '📺 TV en Vivo'),
                    Tab(text: '🍿 Catálogo'),
                  ],
                ),
              ],
            ),
          ),

          // CONTENIDO DE LAS PESTAÑAS
          Expanded(
            child: TabBarView(
              children: [
                // ── PESTAÑA 1: CANALES DE TV ──
                Consumer<ChannelProvider>(
                  builder: (context, provider, child) {
                    final favorites = provider.favoriteChannels;
                    if (favorites.isEmpty) {
                      return _buildEmptyState('No tienes canales favoritos aún', Icons.tv_off_rounded);
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: favorites.length,
                      itemBuilder: (context, index) {
                        final channel = favorites[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: ChannelListTile(
                            channel: channel,
                            onTap: () => onChannelTap(channel),
                            onFavoriteToggle: () => provider.toggleFavorite(channel.id),
                          ),
                        );
                      },
                    );
                  },
                ),

                // ── PESTAÑA 2: PELÍCULAS Y SERIES ──
                Consumer<VodProvider>(
                  builder: (context, provider, child) {
                    final favorites = provider.favorites;
                    if (favorites.isEmpty) {
                      return _buildEmptyState('No tienes películas o series favoritas', Icons.movie_filter_rounded);
                    }
                    return GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 0.65,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: favorites.length,
                      itemBuilder: (context, index) {
                        final item = favorites[index];
                        final posterPath = item['poster_path'];

                        return GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => DetailsScreen(
                                  tmdbId: item['id']!,
                                  title: item['title']!,
                                  type: item['type']!,
                                  posterPath: posterPath!.isNotEmpty ? posterPath : null,
                                ),
                              ),
                            );
                          },
                          child: Column(
                            children: [
                              Expanded(
                                child: Stack(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        color: AppColors.surface,
                                        image: posterPath != null && posterPath.isNotEmpty
                                            ? DecorationImage(
                                          image: NetworkImage('${TmdbService.imageBaseUrl}$posterPath'),
                                          fit: BoxFit.cover,
                                        )
                                            : null,
                                      ),
                                      child: posterPath == null || posterPath.isEmpty
                                          ? const Center(child: Icon(Icons.movie, color: Colors.white54))
                                          : null,
                                    ),
                                    // Indicador de tipo (Película o Serie)
                                    Positioned(
                                      top: 4, left: 4,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.black87,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          item['type'] == 'tv' ? 'SERIE' : 'PELI',
                                          style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                item['title']!,
                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                                maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget para mostrar un mensaje cuando no hay favoritos
  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.white24),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(color: Colors.white54, fontSize: 16)),
        ],
      ),
    );
  }
}