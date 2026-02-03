import 'package:floor/floor.dart';

@Entity(tableName: 'movies')
class MovieEntity {
  @PrimaryKey()
  final int id;
  final String title;
  final String overview;
  final String? posterPath;
  final String? backdropPath;
  final double voteAverage;
  final String releaseDate;
  final String genreIds; // Stored as comma-separated string
  final String cacheType; // 'popular', 'upcoming', 'now_playing', 'top_rated'
  final int page;
  final int timestamp; // For cache expiration

  MovieEntity({
    required this.id,
    required this.title,
    required this.overview,
    this.posterPath,
    this.backdropPath,
    required this.voteAverage,
    required this.releaseDate,
    required this.genreIds,
    required this.cacheType,
    required this.page,
    required this.timestamp,
  });
}
