import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/channels_data.dart';
import '../models/channel.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'home_screen.dart';
import 'live_tv_screen.dart';
import 'epg_screen.dart';
import 'favorites_screen.dart';
import 'settings_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  late List<Channel> _channels;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  bool _searchActive = false;

  @override
  void initState() {
    super.initState();
    _channels = List<Channel>.from(ChannelsData.channels);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleFavorite(int channelId) {
    setState(() {
      final index = _channels.indexWhere((c) => c.id == channelId);
      if (index != -1) {
        _channels[index] = _channels[index].copyWith(
          isFavorite: !_channels[index].isFavorite,
        );
      }
    });
  }

  List<Channel> get _favoriteChannels =>
      _channels.where((c) => c.isFavorite).toList();

  List<Channel> get _searchResults {
    if (_searchQuery.isEmpty) return [];
    final q = _searchQuery.toLowerCase();
    return _channels
        .where((c) =>
            c.name.toLowerCase().contains(q) ||
            c.currentProgram.toLowerCase().contains(q) ||
            c.category.toLowerCase().contains(q) ||
            c.country.toLowerCase().contains(q))
        .toList();
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
            // ── Top bar ───────────────────────────────────────────
            _TopBar(
              searchController: _searchController,
              searchActive: _searchActive,
              searchQuery: _searchQuery,
              onSearchChanged: (q) => setState(() => _searchQuery = q),
              onSearchToggle: () => setState(() {
                _searchActive = !_searchActive;
                if (!_searchActive) {
                  _searchQuery = '';
                  _searchController.clear();
                }
              }),
              onClearSearch: () => setState(() {
                _searchQuery = '';
                _searchController.clear();
              }),
            ),

            // ── Body ──────────────────────────────────────────────
            Expanded(
              child: _searchActive && _searchQuery.isNotEmpty
                  ? _SearchResults(
                      results: _searchResults,
                      query: _searchQuery,
                      onFavoriteToggle: _toggleFavorite,
                    )
                  : _buildCurrentTab(),
            ),
          ],
        ),
      ),

      // ── Bottom Navigation ────────────────────────────────────
      bottomNavigationBar: _BottomNav(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }

  Widget _buildCurrentTab() {
    switch (_currentIndex) {
      case 0:
        return HomeScreen(
          channels: _channels,
          onFavoriteToggle: _toggleFavorite,
        );
      case 1:
        return LiveTVScreen(
          channels: _channels,
          onFavoriteToggle: _toggleFavorite,
        );
      case 2:
        return EpgScreen(
          channels: _channels,
          onFavoriteToggle: _toggleFavorite,
        );
      case 3:
        return FavoritesScreen(
          favoriteChannels: _favoriteChannels,
          onFavoriteToggle: _toggleFavorite,
        );
      case 4:
        return const SettingsScreen();
      default:
        return const SizedBox.shrink();
    }
  }
}

// ── Top Bar ────────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final TextEditingController searchController;
  final bool searchActive;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onSearchToggle;
  final VoidCallback onClearSearch;

  const _TopBar({
    required this.searchController,
    required this.searchActive,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.onSearchToggle,
    required this.onClearSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Logo
          if (!searchActive) ...[
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.bolt_rounded,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('StreamVision',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      )),
                  Text('IPTV Player',
                      style: AppTextStyles.bodySmall),
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
                  border: Border.all(
                      color: AppColors.accentPurple.withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 12),
                    const Icon(Icons.search_rounded,
                        size: 18, color: AppColors.accentViolet),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: searchController,
                        autofocus: true,
                        onChanged: onSearchChanged,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Buscar canales, programas...',
                          hintStyle: TextStyle(
                              color: AppColors.textMuted, fontSize: 14),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    if (searchQuery.isNotEmpty)
                      GestureDetector(
                        onTap: onClearSearch,
                        child: const Padding(
                          padding: EdgeInsets.all(8),
                          child: Icon(Icons.close_rounded,
                              size: 16, color: AppColors.textMuted),
                        ),
                      ),
                  ],
                ),
              ),
            ),

          const SizedBox(width: 8),

          // Search toggle
          GestureDetector(
            onTap: onSearchToggle,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: searchActive
                    ? AppColors.accentPurple.withOpacity(0.2)
                    : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: searchActive
                      ? AppColors.accentPurple.withOpacity(0.4)
                      : AppColors.border,
                ),
              ),
              child: Icon(
                searchActive
                    ? Icons.close_rounded
                    : Icons.search_rounded,
                size: 18,
                color: searchActive
                    ? AppColors.accentViolet
                    : AppColors.textSecondary,
              ),
            ),
          ),

          if (!searchActive) ...[
            const SizedBox(width: 8),
            // Notification bell
            Stack(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Icon(Icons.notifications_outlined,
                      size: 18, color: AppColors.textSecondary),
                ),
                Positioned(
                  top: 5,
                  right: 5,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: AppColors.liveRed,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: AppColors.background, width: 1.5),
                    ),
                    child: const Center(
                      child: Text('3',
                          style: TextStyle(
                              fontSize: 6,
                              color: Colors.white,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
              ],
            ),
          ],
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

  static const List<_NavItem> _items = [
    _NavItem(icon: Icons.home_rounded, activeIcon: Icons.home_rounded, label: 'Inicio'),
    _NavItem(icon: Icons.live_tv_outlined, activeIcon: Icons.live_tv_rounded, label: 'En Vivo'),
    _NavItem(icon: Icons.calendar_month_outlined, activeIcon: Icons.calendar_month_rounded, label: 'EPG'),
    _NavItem(icon: Icons.star_border_rounded, activeIcon: Icons.star_rounded, label: 'Favoritos'),
    _NavItem(icon: Icons.settings_outlined, activeIcon: Icons.settings_rounded, label: 'Ajustes'),
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
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  gradient: isActive ? AppColors.primaryGradient : null,
                  color: isActive ? null : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isActive ? item.activeIcon : item.icon,
                      size: 22,
                      color: isActive
                          ? Colors.white
                          : AppColors.textMuted,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isActive
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: isActive
                            ? Colors.white
                            : AppColors.textMuted,
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

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

// ── Search Results ─────────────────────────────────────────────────────────────

class _SearchResults extends StatelessWidget {
  final List<Channel> results;
  final String query;
  final void Function(int) onFavoriteToggle;

  const _SearchResults({
    required this.results,
    required this.query,
    required this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🔍', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            const Text('Sin resultados', style: AppTextStyles.headlineMedium),
            const SizedBox(height: 6),
            Text(
              'No se encontró "$query"',
              style: AppTextStyles.bodyMedium,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
          child: Text(
            '${results.length} resultado${results.length != 1 ? "s" : ""} para "$query"',
            style: AppTextStyles.bodyMedium,
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: results.length,
            itemBuilder: (context, index) {
              final ch = results[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _SearchTile(
                  channel: ch,
                  onFavoriteToggle: () => onFavoriteToggle(ch.id),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SearchTile extends StatelessWidget {
  final Channel channel;
  final VoidCallback onFavoriteToggle;

  const _SearchTile({
    required this.channel,
    required this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              channel.thumbnailUrl,
              width: 60,
              height: 40,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 60,
                height: 40,
                color: AppColors.surface,
                child: const Icon(Icons.tv_rounded,
                    size: 18, color: AppColors.textDisabled),
              ),
              loadingBuilder: (_, child, progress) {
                if (progress == null) return child;
                return Container(
                    width: 60, height: 40, color: AppColors.surface);
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(channel.name, style: AppTextStyles.channelName),
                const SizedBox(height: 2),
                Text(channel.currentProgram,
                    style: AppTextStyles.programName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          if (channel.isLive) ...[
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.liveRed,
                borderRadius: BorderRadius.circular(5),
              ),
              child: const Text('VIVO',
                  style: AppTextStyles.liveBadge),
            ),
            const SizedBox(width: 8),
          ],
          GestureDetector(
            onTap: onFavoriteToggle,
            child: Icon(
              channel.isFavorite
                  ? Icons.star_rounded
                  : Icons.star_border_rounded,
              size: 20,
              color: channel.isFavorite
                  ? AppColors.warning
                  : AppColors.textDisabled,
            ),
          ),
        ],
      ),
    );
  }
}
