import '../../models/movie_model.dart';
import '../../database/app_database.dart';
import '../../database/entities/movie_entity.dart';

class MovieLocalDataSource {
  final AppDatabase _database;

  MovieLocalDataSource(this._database);

  // Convert MovieModel to MovieEntity
  MovieEntity _modelToEntity(MovieModel model, String cacheType, int page) {
    return MovieEntity(
      id: model.id,
      title: model.title,
      overview: model.overview,
      posterPath: model.posterPath,
      backdropPath: model.backdropPath,
      voteAverage: model.voteAverage,
      releaseDate: model.releaseDate,
      genreIds: model.genreIds.join(','),
      cacheType: cacheType,
      page: page,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
  }

  // Convert MovieEntity to MovieModel
  MovieModel _entityToModel(MovieEntity entity) {
    return MovieModel(
      id: entity.id,
      title: entity.title,
      overview: entity.overview,
      posterPath: entity.posterPath,
      backdropPath: entity.backdropPath,
      voteAverage: entity.voteAverage,
      releaseDate: entity.releaseDate,
      genreIds: entity.genreIds.split(',').where((id) => id.isNotEmpty).map((id) => int.parse(id)).toList(),
    );
  }

  // Save movies to local database
  Future<void> saveMovies(List<MovieModel> movies, String cacheType, int page) async {
    final entities = movies.map((movie) => _modelToEntity(movie, cacheType, page)).toList();
    await _database.movieDao.insertMovies(entities);
  }

  // Get movies from local database by cache type
  Future<List<MovieModel>> getMovies(String cacheType) async {
    final entities = await _database.movieDao.getMoviesByCacheType(cacheType);
    return entities.map((entity) => _entityToModel(entity)).toList();
  }

  // Get movies from local database by cache type and page
  Future<List<MovieModel>> getMoviesByPage(String cacheType, int page) async {
    final entities = await _database.movieDao.getMoviesByCacheTypeAndPage(cacheType, page);
    return entities.map((entity) => _entityToModel(entity)).toList();
  }

  // Clear expired movies (older than 24 hours)
  Future<void> clearExpiredMovies() async {
    const twentyFourHours = 24 * 60 * 60 * 1000; // 24 hours in milliseconds
    final expirationTimestamp = DateTime.now().millisecondsSinceEpoch - twentyFourHours;
    await _database.movieDao.deleteExpiredMovies(expirationTimestamp);
  }
}
