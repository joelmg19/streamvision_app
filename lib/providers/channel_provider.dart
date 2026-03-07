import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/channel.dart';
import '../services/m3u_service.dart';

enum LoadState { idle, loading, loaded, error }

class ChannelProvider extends ChangeNotifier {
  // ── State ──────────────────────────────────────────────────────────────────
  LoadState _loadState = LoadState.idle;
  String _errorMessage = '';
  List<Channel> _channels = [];
  Set<int> _favoriteIds = {};
  String _selectedCategory = 'all';
  String _searchQuery = '';

  // ── Getters ────────────────────────────────────────────────────────────────
  LoadState get loadState => _loadState;
  String get errorMessage => _errorMessage;
  bool get isLoading => _loadState == LoadState.loading;
  bool get hasError => _loadState == LoadState.error;
  bool get isLoaded => _loadState == LoadState.loaded;
  String get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;

  List<Channel> get allChannels => _channels;

  List<Channel> get filteredChannels {
    var list = _channels;
    if (_selectedCategory != 'all') {
      list = list.where((c) => c.category == _selectedCategory).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list
          .where((c) =>
              c.name.toLowerCase().contains(q) ||
              (c.groupTitle?.toLowerCase().contains(q) ?? false) ||
              c.country.toLowerCase().contains(q))
          .toList();
    }
    return list;
  }

  List<Channel> get favoriteChannels =>
      _channels.where((c) => _favoriteIds.contains(c.id)).toList();

  List<Channel> get featuredChannels =>
      _channels.take(8).toList();

  List<Channel> get trendingChannels =>
      List.from(_channels.take(10));

  /// Unique categories derived from loaded channels
  List<ChannelCategory> get categories {
    final cats = <String, int>{};
    for (final ch in _channels) {
      cats[ch.category] = (cats[ch.category] ?? 0) + 1;
    }

    final result = <ChannelCategory>[
      ChannelCategory(
          id: 'all', name: 'Todos', emoji: '🌐', count: _channels.length),
    ];
    result.addAll(cats.entries
        .map((e) => ChannelCategory(
              id: e.key,
              name: _categoryName(e.key),
              emoji: _categoryEmoji(e.key),
              count: e.value,
            ))
        .toList()
      ..sort((a, b) => b.count.compareTo(a.count)));
    return result;
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> loadChannels() async {
    if (_loadState == LoadState.loading) return;
    _loadState = LoadState.loading;
    _errorMessage = '';
    notifyListeners();

    try {
      final fetched = await M3uService.fetchChannels();
      _channels = fetched;
      _loadState = LoadState.loaded;
      await _loadFavorites();
    } catch (e) {
      _errorMessage = e.toString();
      _loadState = LoadState.error;
    }
    notifyListeners();
  }

  void setCategory(String categoryId) {
    _selectedCategory = categoryId;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void toggleFavorite(int channelId) {
    if (_favoriteIds.contains(channelId)) {
      _favoriteIds.remove(channelId);
    } else {
      _favoriteIds.add(channelId);
    }
    _saveFavorites();
    notifyListeners();
  }

  bool isFavorite(int channelId) => _favoriteIds.contains(channelId);

  // ── Persistence ────────────────────────────────────────────────────────────

  Future<void> _loadFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ids = prefs.getStringList('favorites') ?? [];
      _favoriteIds = ids.map(int.parse).toSet();
    } catch (_) {
      _favoriteIds = {};
    }
  }

  Future<void> _saveFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
          'favorites', _favoriteIds.map((id) => id.toString()).toList());
    } catch (_) {}
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  static String _categoryName(String id) {
    const names = {
      'news': 'Noticias',
      'sports': 'Deportes',
      'movies': 'Películas',
      'series': 'Series',
      'music': 'Música',
      'documentary': 'Documentales',
      'kids': 'Infantil',
      'entertainment': 'Entretenimiento',
    };
    return names[id] ?? id[0].toUpperCase() + id.substring(1);
  }

  static String _categoryEmoji(String id) {
    const emojis = {
      'news': '📰',
      'sports': '⚽',
      'movies': '🎬',
      'series': '📺',
      'music': '🎵',
      'documentary': '🌿',
      'kids': '🧸',
      'entertainment': '🎭',
    };
    return emojis[id] ?? '📡';
  }
}
