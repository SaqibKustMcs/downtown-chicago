import '../../data/repositories/movie_repository.dart';
import '../../data/datasources/local/movie_local_datasource.dart';
import '../../data/database/app_database.dart';

class RepositoryFactory {
  static MovieRepository? _movieRepository;
  static AppDatabase? _database;

  static void initialize(AppDatabase database) {
    _database = database;
    final localDataSource = MovieLocalDataSource(database);
    _movieRepository = MovieRepository(localDataSource);
  }

  static MovieRepository getMovieRepository() {
    if (_movieRepository == null) {
      throw Exception('RepositoryFactory not initialized. Call initialize() first.');
    }
    return _movieRepository!;
  }

  static void reset() {
    _movieRepository = null;
    _database = null;
  }
}
