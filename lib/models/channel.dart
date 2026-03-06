class Channel {
  final int id;
  final String name;
  final String logo;
  final String category;
  final String country;
  final bool isLive;
  final int viewers;
  final String currentProgram;
  final String nextProgram;
  final String startTime;
  final String endTime;
  final int progress; // 0–100
  final String thumbnailUrl;
  final bool isFeatured;
  final String description;
  final String quality; // '4K', 'FHD', 'HD', 'SD'
  bool isFavorite;

  Channel({
    required this.id,
    required this.name,
    required this.logo,
    required this.category,
    required this.country,
    required this.isLive,
    required this.viewers,
    required this.currentProgram,
    required this.nextProgram,
    required this.startTime,
    required this.endTime,
    required this.progress,
    required this.thumbnailUrl,
    this.isFeatured = false,
    this.description = '',
    required this.quality,
    this.isFavorite = false,
  });

  String get formattedViewers {
    if (viewers >= 1000) {
      return '${(viewers / 1000).toStringAsFixed(1)}K';
    }
    return viewers.toString();
  }

  Channel copyWith({bool? isFavorite}) {
    return Channel(
      id: id,
      name: name,
      logo: logo,
      category: category,
      country: country,
      isLive: isLive,
      viewers: viewers,
      currentProgram: currentProgram,
      nextProgram: nextProgram,
      startTime: startTime,
      endTime: endTime,
      progress: progress,
      thumbnailUrl: thumbnailUrl,
      isFeatured: isFeatured,
      description: description,
      quality: quality,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}

class ChannelCategory {
  final String id;
  final String name;
  final String emoji;
  final int count;

  const ChannelCategory({
    required this.id,
    required this.name,
    required this.emoji,
    required this.count,
  });
}

class EpgEntry {
  final String time;
  final String title;
  final int durationMinutes;
  final bool isLive;

  const EpgEntry({
    required this.time,
    required this.title,
    required this.durationMinutes,
    this.isLive = false,
  });
}
