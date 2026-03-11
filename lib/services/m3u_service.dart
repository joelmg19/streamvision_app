import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/channel.dart';

class M3uService {
  static const String _playlistUrl =
      'https://raw.githubusercontent.com/Free-TV/IPTV/master/playlist.m3u8';

  static Future<List<Channel>> fetchChannels() async {
    final response = await http
        .get(Uri.parse(_playlistUrl))
        .timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) throw Exception('HTTP ${response.statusCode}');

    final body = utf8.decode(response.bodyBytes);
    return _parseM3u(body);
  }

  static List<Channel> _parseM3u(String content) {
    final lines = content.split('\n');
    final channels = <Channel>[];
    int id = 1;

    for (int i = 0; i < lines.length - 1; i++) {
      final line = lines[i].trim();
      if (!line.startsWith('#EXTINF')) continue;

      final urlLine = _nextStreamLine(lines, i + 1);
      if (urlLine == null) continue;

      final name = _parseName(line);
      final logoUrl = _parseAttr(line, 'tvg-logo');
      final groupTitle = _parseAttr(line, 'group-title');
      final tvgId = _parseAttr(line, 'tvg-id');
      final tvgName = _parseAttr(line, 'tvg-name');
      final tvgCountry = _parseAttr(line, 'tvg-country');

      if (name.isEmpty || urlLine.isEmpty) continue;

      channels.add(Channel.fromM3u(
        id: id++, name: name, streamUrl: urlLine,
        logoUrl: logoUrl?.isNotEmpty == true ? logoUrl : null,
        groupTitle: groupTitle, tvgId: tvgId, tvgName: tvgName, country: tvgCountry,
      ));
    }
    return channels;
  }

  static String? _nextStreamLine(List<String> lines, int startIndex) {
    for (int j = startIndex; j < lines.length; j++) {
      final l = lines[j].trim();
      if (l.isEmpty || l.startsWith('#')) continue;
      return l;
    }
    return null;
  }

  static String _parseName(String extinf) {
    final commaIdx = extinf.lastIndexOf(',');
    if (commaIdx < 0) return '';
    return extinf.substring(commaIdx + 1).trim();
  }

  static String? _parseAttr(String extinf, String attr) {
    final regExp = RegExp('$attr=["\']([^"\']*)["\']', caseSensitive: false);
    final match = regExp.firstMatch(extinf);
    return match?.group(1);
  }
}
