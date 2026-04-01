class Channel {
  final int id;
  final String name;
  final String logo;
  final String category;
  final String country;
  final bool isLive;
  int viewers;
  final String currentProgram;
  final String nextProgram;
  final String startTime;
  final String endTime;
  final int progress;
  final String thumbnailUrl;
  final bool isFeatured;
  final String description;
  final String quality;
  bool isFavorite;
  final String? streamUrl;
  final String? logoUrl;
  final String? groupTitle;
  final String? tvgId;
  final String? tvgName;

  Channel({
    required this.id, required this.name, required this.logo,
    required this.category, required this.country, required this.isLive,
    required this.viewers, required this.currentProgram, required this.nextProgram,
    required this.startTime, required this.endTime, required this.progress,
    required this.thumbnailUrl, this.isFeatured = false, this.description = '',
    required this.quality, this.isFavorite = false, this.streamUrl,
    this.logoUrl, this.groupTitle, this.tvgId, this.tvgName,
  });

  String get formattedViewers {
    if (viewers >= 1000) return '${(viewers / 1000).toStringAsFixed(1)}K';
    return viewers.toString();
  }

  String get displayLogoUrl => logoUrl ?? thumbnailUrl;

  Channel copyWith({bool? isFavorite, int? viewers, String? currentProgram,
      String? nextProgram, String? streamUrl, String? logoUrl}) {
    return Channel(
      id: id, name: name, logo: logo, category: category, country: country,
      isLive: isLive, viewers: viewers ?? this.viewers,
      currentProgram: currentProgram ?? this.currentProgram,
      nextProgram: nextProgram ?? this.nextProgram, startTime: startTime,
      endTime: endTime, progress: progress, thumbnailUrl: thumbnailUrl,
      isFeatured: isFeatured, description: description, quality: quality,
      isFavorite: isFavorite ?? this.isFavorite,
      streamUrl: streamUrl ?? this.streamUrl, logoUrl: logoUrl ?? this.logoUrl,
      groupTitle: groupTitle, tvgId: tvgId, tvgName: tvgName,
    );
  }

  factory Channel.fromM3u({required int id, required String name,
      required String streamUrl, String? logoUrl, String? groupTitle,
      String? tvgId, String? tvgName, String? country}) {
    final category = _mapGroupToCategory(groupTitle ?? '');
    final countryCode = country ?? _inferCountry(groupTitle ?? '', name);
    return Channel(
      id: id, name: name,
      logo: name.length >= 3 ? name.substring(0, 3).toUpperCase() : name.toUpperCase(),
      category: category, country: countryCode, isLive: true, viewers: 0,
      currentProgram: 'En directo', nextProgram: '', startTime: '', endTime: '',
      progress: 0,
      thumbnailUrl: logoUrl ?? 'https://images.unsplash.com/photo-1668027732452-295c9d6ca23b?w=400&q=80',
      isFeatured: false, description: '$name — ${groupTitle ?? "TV"}', quality: 'HD',
      streamUrl: streamUrl, logoUrl: logoUrl, groupTitle: groupTitle,
      tvgId: tvgId, tvgName: tvgName,
    );
  }

  static String _mapGroupToCategory(String group) {
    final g = group.toLowerCase();
    if (g.contains('news') || g.contains('noticias') || g.contains('notícias')) return 'news';
    if (g.contains('sport') || g.contains('deporte') || g.contains('desporto')) return 'sports';
    if (g.contains('movie') || g.contains('cine') || g.contains('film') || g.contains('película')) return 'movies';
    if (g.contains('series') || g.contains('serie') || g.contains('drama')) return 'series';
    if (g.contains('music') || g.contains('música') || g.contains('musica')) return 'music';
    if (g.contains('document') || g.contains('nature') || g.contains('history') || g.contains('natur')) return 'documentary';
    if (g.contains('kid') || g.contains('child') || g.contains('cartoon') || g.contains('infantil') || g.contains('niño')) return 'kids';
    if (g.contains('entertain') || g.contains('general') || g.contains('entretenimiento')) return 'entertainment';
    return 'entertainment';
  }

  static String _inferCountry(String group, String name) {
    final combined = '$group $name'.toLowerCase();
    if (combined.contains('usa') || combined.contains('united states') || combined.contains('america')) return 'US';
    if (combined.contains('uk') || combined.contains('britain') || combined.contains('england')) return 'UK';
    if (combined.contains('france') || combined.contains('français')) return 'FR';
    if (combined.contains('germany') || combined.contains('deutsch') || combined.contains('german')) return 'DE';
    if (combined.contains('spain') || combined.contains('español') || combined.contains('espana') || combined.contains('españa')) return 'ES';
    if (combined.contains('italy') || combined.contains('italian') || combined.contains('italiano')) return 'IT';
    if (combined.contains('russia') || combined.contains('russian') || combined.contains('россия')) return 'RU';
    if (combined.contains('japan') || combined.contains('japanese') || combined.contains('日本')) return 'JP';
    if (combined.contains('china') || combined.contains('chinese') || combined.contains('中国')) return 'CN';
    if (combined.contains('india') || combined.contains('indian') || combined.contains('hindi')) return 'IN';
    if (combined.contains('brazil') || combined.contains('brasil') || combined.contains('brazilian')) return 'BR';
    if (combined.contains('mexico') || combined.contains('méxico')) return 'MX';
    if (combined.contains('argentina')) return 'AR';
    if (combined.contains('australia') || combined.contains('australian')) return 'AU';
    if (combined.contains('canada') || combined.contains('canadian')) return 'CA';
    if (combined.contains('qatar')) return 'QA';
    if (combined.contains('turkey') || combined.contains('türk')) return 'TR';
    return 'INT';
  }
}

class ChannelCategory {
  final String id;
  final String name;
  final String emoji;
  final int count;

  const ChannelCategory({required this.id, required this.name, required this.emoji, required this.count});

  ChannelCategory copyWith({int? count}) {
    return ChannelCategory(id: id, name: name, emoji: emoji, count: count ?? this.count);
  }
}

class EpgEntry {
  final String time;
  final String title;
  final int durationMinutes;
  final bool isLive;

  const EpgEntry({required this.time, required this.title, required this.durationMinutes, this.isLive = false});
}
