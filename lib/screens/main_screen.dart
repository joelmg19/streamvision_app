import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/channel_provider.dart';
import '../models/channel.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/channel_list_tile.dart';
import '../widgets/video_player_sheet.dart';
import '../services/tmdb_service.dart';
import 'home_screen.dart';
import 'live_tv_screen.dart';
import 'movies_screen.dart';
import 'favorites_screen.dart';
import 'settings_screen.dart';
import 'details_screen.dart'; // Importante para abrir las pelis

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  bool _searchActive = false;
  final TextEditingController _searchController = TextEditingController();

  // Variables para la búsqueda de TMDB
  Timer? _debounceTimer;
  List<dynamic> _tmdbSearchResults = [];
  bool _isTmdbSearching = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChannelProvider>().loadChannels();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _openPlayer(Channel channel) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => VideoPlayerSheet(
        channel: channel,
        isFavorite: context.read<ChannelProvider>().isFavorite(channel.id),
        onFavoriteToggle: (id) =>
            context.read<ChannelProvider>().toggleFavorite(id),
        launchInFullscreen: true,
      ),
    );
  }

  void _openTmdbDetails(Map<String, dynamic> item) {
    final type = item['media_type'] ?? 'movie';
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

  // Manejador unificado de búsqueda (Canales + Películas)
  void _onSearchChanged(String query) {
    // 1. Buscamos en canales locales instantáneamente
    context.read<ChannelProvider>().setSearchQuery(query);

    // 2. Retrasamos la búsqueda de TMDB para no saturar la API
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();

    if (query.trim().isEmpty) {
      setState(() {
        _tmdbSearchResults = [];
        _isTmdbSearching = false;
      });
      return;
    }

    setState(() => _isTmdbSearching = true);
    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      final results = await TmdbService.searchMulti(query);
      if (mounted) {
        setState(() {
          _tmdbSearchResults = results;
          _isTmdbSearching = false;
        });
      }
    });
  }

  void _clearSearch() {
    _searchController.clear();
    _onSearchChanged('');
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: AppColors.surface,
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(
              searchController: _searchController,
              searchActive: _searchActive,
              onSearchToggle: () => setState(() {
                _searchActive = !_searchActive;
                if (!_searchActive) _clearSearch();
              }),
              onSearchChanged: _onSearchChanged,
              onClearSearch: _clearSearch,
            ),
            Expanded(
              child: Consumer<ChannelProvider>(
                builder: (context, provider, _) {
                  if (_searchActive && provider.searchQuery.isNotEmpty) {
                    return _SearchResults(
                      channels: provider.filteredChannels,
                      tmdbResults: _tmdbSearchResults,
                      query: provider.searchQuery,
                      isTmdbSearching: _isTmdbSearching,
                      onChannelTap: _openPlayer,
                      onTmdbTap: _openTmdbDetails,
                      onFavoriteToggle: provider.toggleFavorite,
                    );
                  }
                  return _buildTab(provider);
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _BottomNav(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }

  Widget _buildTab(ChannelProvider provider) {
    switch (_currentIndex) {
      case 0: return HomeScreen(onChannelTap: _openPlayer);
      case 1: return LiveTVScreen(onChannelTap: _openPlayer);
      case 2: return const MoviesScreen();
      case 3: return FavoritesScreen(onChannelTap: _openPlayer);
      case 4: return const SettingsScreen();
      default: return const SizedBox.shrink();
    }
  }
}

// ── Top Bar ────────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final TextEditingController searchController;
  final bool searchActive;
  final VoidCallback onSearchToggle;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;

  const _TopBar({
    required this.searchController,
    required this.searchActive,
    required this.onSearchToggle,
    required this.onSearchChanged,
    required this.onClearSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Row(
        children: [
          if (!searchActive) ...[
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('StreamVision',
                      style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
                  Text('IPTV & VOD Player', style: AppTextStyles.bodySmall),
                ],
              ),
            ),
          ] else
            Expanded(
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.accentPurple.withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 12),
                    const Icon(Icons.search_rounded, size: 18, color: AppColors.accentViolet),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: searchController,
                        autofocus: true,
                        onChanged: onSearchChanged,
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                        decoration: const InputDecoration(
                          hintText: 'Buscar canales, películas, series...',
                          hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 14),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    if (searchController.text.isNotEmpty)
                      GestureDetector(
                        onTap: onClearSearch,
                        child: const Padding(
                          padding: EdgeInsets.all(8),
                          child: Icon(Icons.close_rounded, size: 16, color: AppColors.textMuted),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onSearchToggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: searchActive ? AppColors.accentPurple.withOpacity(0.2) : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: searchActive ? AppColors.accentPurple.withOpacity(0.4) : AppColors.border,
                ),
              ),
              child: Icon(
                searchActive ? Icons.close_rounded : Icons.search_rounded,
                size: 18,
                color: searchActive ? AppColors.accentViolet : AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bottom Nav ─────────────────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _BottomNav({required this.currentIndex, required this.onTap});

  static const _items = [
    _NavItem(Icons.home_rounded, Icons.home_rounded, 'Inicio'),
    _NavItem(Icons.live_tv_outlined, Icons.live_tv_rounded, 'En Vivo'),
    _NavItem(Icons.movie_creation_outlined, Icons.movie_creation_rounded, 'Catálogo'),
    _NavItem(Icons.star_border_rounded, Icons.star_rounded, 'Favoritos'),
    _NavItem(Icons.settings_outlined, Icons.settings_rounded, 'Ajustes'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(_items.length, (i) {
            final item = _items[i];
            final isActive = currentIndex == i;
            return GestureDetector(
              onTap: () => onTap(i),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  gradient: isActive ? AppColors.primaryGradient : null,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isActive ? item.activeIcon : item.icon,
                      size: 22,
                      color: isActive ? Colors.white : AppColors.textMuted,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                        color: isActive ? Colors.white : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem(this.icon, this.activeIcon, this.label);
}

// ── Search Results Unificados ──────────────────────────────────────────────────

class _SearchResults extends StatelessWidget {
  final List<Channel> channels;
  final List<dynamic> tmdbResults;
  final String query;
  final bool isTmdbSearching;
  final void Function(Channel) onChannelTap;
  final void Function(Map<String, dynamic>) onTmdbTap;
  final void Function(int) onFavoriteToggle;

  const _SearchResults({
    required this.channels,
    required this.tmdbResults,
    required this.query,
    required this.isTmdbSearching,
    required this.onChannelTap,
    required this.onTmdbTap,
    required this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    if (channels.isEmpty && tmdbResults.isEmpty && !isTmdbSearching) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🔍', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            const Text('Sin resultados', style: AppTextStyles.headlineMedium),
            const SizedBox(height: 6),
            Text('No se encontró "$query"', style: AppTextStyles.bodyMedium),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── SECCIÓN CANALES DE TV ──
          if (channels.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 16, 0, 12),
              child: Text(
                '📺 Canales de TV (${channels.length})',
                style: AppTextStyles.headlineMedium.copyWith(fontSize: 16),
              ),
            ),
            ...channels.map((ch) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ChannelListTile(
                channel: ch,
                onTap: () => onChannelTap(ch),
                onFavoriteToggle: () => onFavoriteToggle(ch.id),
              ),
            )).toList(),
          ],

          // ── SECCIÓN PELÍCULAS Y SERIES ──
          if (isTmdbSearching)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 30),
              child: Center(child: CircularProgressIndicator(color: AppColors.accentViolet)),
            )
          else if (tmdbResults.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 20, 0, 12),
              child: Text(
                '🍿 Películas y Series (${tmdbResults.length})',
                style: AppTextStyles.headlineMedium.copyWith(fontSize: 16),
              ),
            ),
            ...tmdbResults.map((item) {
              final title = item['title'] ?? item['name'] ?? 'Desconocido';
              final posterPath = item['poster_path'];
              final type = item['media_type'] == 'tv' ? 'Serie' : 'Película';
              final date = item['release_date'] ?? item['first_air_date'] ?? '';
              final year = date.isNotEmpty ? date.substring(0, 4) : '';

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 50, height: 70,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      image: posterPath != null
                          ? DecorationImage(
                        image: NetworkImage('${TmdbService.imageBaseUrl}$posterPath'),
                        fit: BoxFit.cover,
                      )
                          : null,
                    ),
                    child: posterPath == null ? const Icon(Icons.movie, color: Colors.white54) : null,
                  ),
                  title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: Text('$type ${year.isNotEmpty ? " • $year" : ""}',
                      style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white24),
                  onTap: () => onTmdbTap(item),
                ),
              );
            }).toList(),
          ],

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}