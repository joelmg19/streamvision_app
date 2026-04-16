import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VodProvider with ChangeNotifier {
  List<Map<String, String>> _favorites = [];

  List<Map<String, String>> get favorites => _favorites;

  VodProvider() {
    _loadFavorites();
  }

  // Cargar favoritos guardados en el teléfono
  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favStringList = prefs.getStringList('vod_favorites') ?? [];

    _favorites = favStringList.map((str) {
      return Map<String, String>.from(json.decode(str));
    }).toList();

    notifyListeners();
  }

  // Comprobar si una película/serie es favorita
  bool isFavorite(String id) {
    return _favorites.any((item) => item['id'] == id);
  }

  // Agregar o quitar de favoritos y guardar en memoria
  Future<void> toggleFavorite(Map<String, String> item) async {
    final prefs = await SharedPreferences.getInstance();

    if (isFavorite(item['id']!)) {
      _favorites.removeWhere((element) => element['id'] == item['id']);
    } else {
      _favorites.add(item);
    }

    // Guardar la lista actualizada en el teléfono
    final favStringList = _favorites.map((e) => json.encode(e)).toList();
    await prefs.setStringList('vod_favorites', favStringList);

    notifyListeners();
  }
}