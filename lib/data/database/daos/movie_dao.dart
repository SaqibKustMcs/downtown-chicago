import 'package:floor/floor.dart';
import '../entities/movie_entity.dart';

@dao
abstract class MovieDao {
  @Query('SELECT * FROM movies WHERE cacheType = :cacheType ORDER BY page ASC, voteAverage DESC')
  Future<List<MovieEntity>> getMoviesByCacheType(String cacheType);

  @Query('SELECT * FROM movies WHERE cacheType = :cacheType AND page = :page')
  Future<List<MovieEntity>> getMoviesByCacheTypeAndPage(String cacheType, int page);

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertMovies(List<MovieEntity> movies);

  @Query('DELETE FROM movies WHERE timestamp < :expirationTimestamp')
  Future<void> deleteExpiredMovies(int expirationTimestamp);
}
