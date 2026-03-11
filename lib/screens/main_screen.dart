import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/channel_provider.dart';
import '../models/channel.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/channel_list_tile.dart';
import '../widgets/video_player_sheet.dart';
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
  bool _searchActive = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Fetch real channels on startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChannelProvider>().loadChannels();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
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
      ),
    );
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
                if (!_searchActive) {
                  _searchController.clear();
                  context.read<ChannelProvider>().setSearchQuery('');
                }
              }),
              onSearchChanged: (q) =>
                  context.read<ChannelProvider>().setSearchQuery(q),
              onClearSearch: () {
                _searchController.clear();
                context.read<ChannelProvider>().setSearchQuery('');
              },
            ),
            Expanded(
              child: Consumer<ChannelProvider>(
                builder: (context, provider, _) {
                  // Show search results when active
                  if (_searchActive &&
                      provider.searchQuery.isNotEmpty) {
                    return _SearchResults(
                      channels: provider.filteredChannels,
                      query: provider.searchQuery,
                      onTap: _openPlayer,
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
      case 0:
        return HomeScreen(onChannelTap: _openPlayer);
      case 1:
        return LiveTVScreen(onChannelTap: _openPlayer);
      case 2:
        return EpgScreen(onChannelTap: _openPlayer);
      case 3:
        return FavoritesScreen(onChannelTap: _openPlayer);
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
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child:
                  const Icon(Icons.bolt_rounded, color: Colors.white, size: 20),
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
                          fontWeight: FontWeight.w700)),
                  Text('IPTV Player', style: AppTextStyles.bodySmall),
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
                            color: AppColors.textPrimary, fontSize: 14),
                        decoration: const InputDecoration(
                          hintText: 'Buscar canales, categorías...',
                          hintStyle:
                              TextStyle(color: AppColors.textMuted, fontSize: 14),
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
                          child: Icon(Icons.close_rounded,
                              size: 16, color: AppColors.textMuted),
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
                searchActive ? Icons.close_rounded : Icons.search_rounded,
                size: 18,
                color: searchActive
                    ? AppColors.accentViolet
                    : AppColors.textSecondary,
              ),
            ),
          ),
          if (!searchActive) ...[
            const SizedBox(width: 8),
            // Live indicator with channel count
            Consumer<ChannelProvider>(
              builder: (_, provider, __) => Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: provider.isLoading
                    ? const Center(
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.accentPurple,
                          ),
                        ),
                      )
                    : Stack(
                        alignment: Alignment.center,
                        children: [
                          const Icon(Icons.tv_rounded,
                              size: 18, color: AppColors.textSecondary),
                          if (provider.isLoaded && provider.allChannels.isNotEmpty)
                            Positioned(
                              top: 5,
                              right: 5,
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: AppColors.success,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: AppColors.background, width: 1.5),
                                ),
                              ),
                            ),
                        ],
                      ),
              ),
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

  static const _items = [
    _NavItem(Icons.home_rounded, Icons.home_rounded, 'Inicio'),
    _NavItem(Icons.live_tv_outlined, Icons.live_tv_rounded, 'En Vivo'),
    _NavItem(Icons.calendar_month_outlined, Icons.calendar_month_rounded, 'EPG'),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
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
                        fontWeight:
                            isActive ? FontWeight.w600 : FontWeight.w400,
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

// ── Search Results ─────────────────────────────────────────────────────────────

class _SearchResults extends StatelessWidget {
  final List<Channel> channels;
  final String query;
  final void Function(Channel) onTap;
  final void Function(int) onFavoriteToggle;

  const _SearchResults({
    required this.channels,
    required this.query,
    required this.onTap,
    required this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    if (channels.isEmpty) {
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
          child: Text(
            '${channels.length} resultado${channels.length != 1 ? "s" : ""} para "$query"',
            style: AppTextStyles.bodyMedium,
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: channels.length,
            itemBuilder: (context, index) {
              final ch = channels[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ChannelListTile(
                  channel: ch,
                  onTap: () => onTap(ch),
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
