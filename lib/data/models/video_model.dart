class VideoModel {
  final String id;
  final String key;
  final String name;
  final String site;
  final int size;
  final String type;
  final bool official;
  final String publishedAt;

  VideoModel({
    required this.id,
    required this.key,
    required this.name,
    required this.site,
    required this.size,
    required this.type,
    required this.official,
    required this.publishedAt,
  });

  factory VideoModel.fromJson(Map<String, dynamic> json) {
    return VideoModel(
      id: json['id'] ?? '',
      key: json['key'] ?? '',
      name: json['name'] ?? '',
      site: json['site'] ?? '',
      size: json['size'] ?? 0,
      type: json['type'] ?? '',
      official: json['official'] ?? false,
      publishedAt: json['published_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'key': key,
      'name': name,
      'site': site,
      'size': size,
      'type': type,
      'official': official,
      'published_at': publishedAt,
    };
  }

  bool get isYouTube => site.toLowerCase() == 'youtube';

  bool get isTrailer => type.toLowerCase() == 'trailer';

  String get youtubeUrl => 'https://www.youtube.com/watch?v=$key';
}

class VideosResponse {
  final int id;
  final List<VideoModel> results;

  VideosResponse({
    required this.id,
    required this.results,
  });

  factory VideosResponse.fromJson(Map<String, dynamic> json) {
    return VideosResponse(
      id: json['id'] ?? 0,
      results: (json['results'] as List<dynamic>?)
              ?.map((video) => VideoModel.fromJson(video))
              .toList() ??
          [],
    );
  }

  VideoModel? get firstTrailer {
    try {
      return results.firstWhere(
        (video) => video.isTrailer && video.official && video.isYouTube,
      );
    } catch (e) {
      try {
        return results.firstWhere(
          (video) => video.isTrailer && video.isYouTube,
        );
      } catch (e) {
        try {
          return results.firstWhere((video) => video.isYouTube);
        } catch (e) {
          return null;
        }
      }
    }
  }
}
