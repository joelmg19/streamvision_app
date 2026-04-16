import 'dart:convert';
import 'package:http/http.dart' as http;

class TmdbService {
  static const String apiKey = 'ccec11dfc09c42b10813615c10dd142d'; // Reemplaza con tu API Key
  static const String baseUrl = 'https://api.themoviedb.org/3';
  static const String imageBaseUrl = 'https://image.tmdb.org/t/p/w500';
  static const String originalImageBaseUrl = 'https://image.tmdb.org/t/p/original';

  static Future<List<dynamic>> _fetchList(String endpoint) async {
    try {
      final response = await http.get(
          Uri.parse('$baseUrl$endpoint&api_key=$apiKey&language=es-ES'));
      if (response.statusCode == 200) {
        return json.decode(response.body)['results'] ?? [];
      }
    } catch (e) {
      print('Error TMDB: $e');
    }
    return [];
  }

  static Future<List<dynamic>> getTrendingMovies() =>
      _fetchList('/trending/movie/week?');

  static Future<List<dynamic>> getTrendingTv() =>
      _fetchList('/trending/tv/week?');

  static Future<List<dynamic>> getAnime() =>
      _fetchList('/discover/tv?with_genres=16&with_original_language=ja');

  static Future<List<dynamic>> getKDramas() =>
      _fetchList('/discover/tv?with_original_language=ko');

  static Future<List<dynamic>> getPopularShows() => _fetchList('/tv/popular?');

  // Obtener detalles completos de Película o Serie (incluyendo Actores)
  static Future<Map<String, dynamic>?> getDetails(String type,
      String id) async {
    try {
      // type debe ser 'movie' o 'tv'
      final response = await http.get(
        Uri.parse(
            '$baseUrl/$type/$id?api_key=$apiKey&language=es-ES&append_to_response=credits'),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      print('Error obteniendo detalles: $e');
    }
    return null;
  }

  // Obtener episodios de una temporada específica
  static Future<List<dynamic>> getSeasonEpisodes(String id,
      int seasonNumber) async {
    try {
      final response = await http.get(
        Uri.parse(
            '$baseUrl/tv/$id/season/$seasonNumber?api_key=$apiKey&language=es-ES'),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body)['episodes'] ?? [];
      }
    } catch (e) {
      print('Error obteniendo episodios: $e');
    }
    return [];
  }

// Buscar Películas y Series (Búsqueda global)
  static Future<List<dynamic>> searchMulti(String query) async {
    if (query
        .trim()
        .isEmpty) return [];
    try {
      final response = await http.get(
        Uri.parse(
            '$baseUrl/search/multi?api_key=$apiKey&language=es-ES&query=${Uri
                .encodeComponent(query)}'),
      );
      if (response.statusCode == 200) {
        final results = json.decode(response.body)['results'] as List<
            dynamic>? ?? [];
// Filtramos para quitar personas/actores y quedarnos solo con películas y series
        return results.where((item) =>
        item['media_type'] == 'movie' || item['media_type'] == 'tv').toList();
      }
    } catch (e) {
      print('Error buscando en TMDB: $e');
    }
    return [];
  }
}