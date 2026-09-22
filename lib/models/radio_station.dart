class RadioStation {
  final String uuid;
  final String name;
  final String url;
  final String favicon;
  final String country;
  final String countryCode;
  final String language;
  final List<String> tags;
  final int votes;
  final int bitrate;
  final String codec;
  bool isFavorite;

  RadioStation({
    required this.uuid,
    required this.name,
    required this.url,
    required this.favicon,
    required this.country,
    required this.countryCode,
    required this.language,
    required this.tags,
    this.votes = 0,
    this.bitrate = 0,
    this.codec = '',
    this.isFavorite = false,
  });

  factory RadioStation.fromJson(Map<String, dynamic> json) {
    List<String> tagList = [];
    if (json['tags'] != null && json['tags'].toString().isNotEmpty) {
      tagList = json['tags']
          .toString()
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .take(5)
          .toList();
    }

    return RadioStation(
      uuid: json['stationuuid'] ?? json['uuid'] ?? '',
      name: (json['name'] ?? 'Unknown Station').toString().trim(),
      url: (json['url_resolved'] ?? json['url'] ?? '').toString().trim(),
      favicon: (json['favicon'] ?? '').toString().trim(),
      country: (json['country'] ?? 'Global').toString().trim(),
      countryCode: (json['countrycode'] ?? '').toString().trim().toUpperCase(),
      language: (json['language'] ?? '').toString().trim(),
      tags: tagList,
      votes: json['votes'] is int ? json['votes'] : int.tryParse(json['votes']?.toString() ?? '0') ?? 0,
      bitrate: json['bitrate'] is int ? json['bitrate'] : int.tryParse(json['bitrate']?.toString() ?? '0') ?? 0,
      codec: (json['codec'] ?? '').toString().trim(),
      isFavorite: json['isFavorite'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stationuuid': uuid,
      'name': name,
      'url_resolved': url,
      'favicon': favicon,
      'country': country,
      'countrycode': countryCode,
      'language': language,
      'tags': tags.join(','),
      'votes': votes,
      'bitrate': bitrate,
      'codec': codec,
      'isFavorite': isFavorite,
    };
  }
}
