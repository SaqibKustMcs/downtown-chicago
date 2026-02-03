import '../models/movie_model.dart';
import '../models/genre_model.dart';
import '../models/video_model.dart';
import '../../core/services/tmdb_api_service.dart';
import '../datasources/local/movie_local_datasource.dart';
import '../../core/utils/helpers.dart';

class MovieRepository {
  final TmdbApiService _apiService = TmdbApiService();
  final MovieLocalDataSource _localDataSource;

  MovieRepository(this._localDataSource);

  // Offline-first method: Always try API first, fallback to cache if fails
  Future<MoviesResponse> _getMoviesOfflineFirst({
    required String cacheType,
    required Future<MoviesResponse> Function() fetchFromApi,
    int page = 1,
  }) async {
    // Check connectivity (but don't rely on it completely)
    final isOnline = await Helpers.checkConnectivity();
    
    // Always try API first when connectivity check says we're online
    // This ensures we get fresh data whenever possible
    if (isOnline) {
      print('🌐 Online detected - attempting API call for $cacheType (page $page)');
      try {
        // Fetch from API - this WILL be called when online
        print('📡 Calling API for $cacheType (page $page)...');
        final apiResponse = await fetchFromApi();
        
        print('✅ API call successful for $cacheType (page $page) - got ${apiResponse.results.length} movies');
        
        // Save to local database for offline access
        if (apiResponse.results.isNotEmpty) {
          await _localDataSource.saveMovies(apiResponse.results, cacheType, page);
          print('💾 Saved ${apiResponse.results.length} movies to cache');
        }
        
        // Return fresh data from API
        return apiResponse;
      } catch (e) {
        // API failed - log the error for debugging
        print('⚠️ API call failed for $cacheType (page $page): $e');
        print('📦 Falling back to cache...');
        
        // Try to get cached data as fallback
        try {
          final cachedMovies = await _localDataSource.getMoviesByPage(cacheType, page);
          if (cachedMovies.isNotEmpty) {
            print('✅ Using ${cachedMovies.length} cached movies for $cacheType (page $page)');
            return MoviesResponse(
              page: page,
              results: cachedMovies,
              totalPages: 1,
              totalResults: cachedMovies.length,
            );
          }
        } catch (cacheError) {
          print('❌ Cache read failed: $cacheError');
        }
        
        // If API fails and no cache available, return empty response
        print('⚠️ No API data and no cache available for $cacheType (page $page)');
        return MoviesResponse(
          page: page,
          results: [],
          totalPages: 0,
          totalResults: 0,
        );
      }
    } else {
      // Connectivity check says offline - try cache first
      print('📴 Offline detected - loading from cache for $cacheType (page $page)');
      try {
        final cachedMovies = await _localDataSource.getMoviesByPage(cacheType, page);
        if (cachedMovies.isNotEmpty) {
          print('✅ Loaded ${cachedMovies.length} cached movies for $cacheType');
          return MoviesResponse(
            page: page,
            results: cachedMovies,
            totalPages: 1,
            totalResults: cachedMovies.length,
          );
        }
      } catch (cacheError) {
        print('❌ Cache read failed: $cacheError');
      }
      
      // Even if offline, try API once (connectivity check might be wrong)
      print('🔄 Trying API anyway (connectivity check might be inaccurate)...');
      try {
        final apiResponse = await fetchFromApi();
        print('✅ API call succeeded despite offline detection!');
        if (apiResponse.results.isNotEmpty) {
          await _localDataSource.saveMovies(apiResponse.results, cacheType, page);
        }
        return apiResponse;
      } catch (e) {
        print('❌ API call failed: $e');
      }
      
      // Offline and no cache: return empty response
      print('⚠️ Offline and no cache available for $cacheType (page $page)');
      return MoviesResponse(
        page: page,
        results: [],
        totalPages: 0,
        totalResults: 0,
      );
    }
  }

  Future<MoviesResponse> getUpcomingMovies({int page = 1}) async {
    return _getMoviesOfflineFirst(
      cacheType: 'upcoming',
      fetchFromApi: () async {
        final response = await _apiService.getUpcomingMovies(page: page);
        return MoviesResponse.fromJson(response);
      },
      page: page,
    );
  }

  Future<MoviesResponse> getPopularMovies({int page = 1}) async {
    return _getMoviesOfflineFirst(
      cacheType: 'popular',
      fetchFromApi: () async {
        final response = await _apiService.getPopularMovies(page: page);
        return MoviesResponse.fromJson(response);
      },
      page: page,
    );
  }

  Future<MoviesResponse> getNowPlayingMovies({int page = 1}) async {
    return _getMoviesOfflineFirst(
      cacheType: 'now_playing',
      fetchFromApi: () async {
        final response = await _apiService.getNowPlayingMovies(page: page);
        return MoviesResponse.fromJson(response);
      },
      page: page,
    );
  }

  Future<MoviesResponse> getTopRatedMovies({int page = 1}) async {
    return _getMoviesOfflineFirst(
      cacheType: 'top_rated',
      fetchFromApi: () async {
        final response = await _apiService.getTopRatedMovies(page: page);
        return MoviesResponse.fromJson(response);
      },
      page: page,
    );
  }

  // Get all cached movies (for offline viewing)
  Future<List<MovieModel>> getCachedMovies(String cacheType) async {
    return await _localDataSource.getMovies(cacheType);
  }

  // Clear expired cache
  Future<void> clearExpiredCache() async {
    await _localDataSource.clearExpiredMovies();
  }

  Future<MovieModel> getMovieDetails(int movieId) async {
    try {
      final response = await _apiService.getMovieDetails(movieId);
      return MovieModel.fromJson(response);
    } catch (e) {
      throw Exception('Repository error: $e');
    }
  }

  Future<MoviesResponse> searchMovies(String query, {int page = 1}) async {
    try {
      final response = await _apiService.searchMovies(query, page: page);
      return MoviesResponse.fromJson(response);
    } catch (e) {
      throw Exception('Repository error: $e');
    }
  }

  Future<List<GenreModel>> getGenres() async {
    try {
      final response = await _apiService.getGenres();
      final genresList = response['genres'] as List<dynamic>;
      return genresList.map((genre) => GenreModel.fromJson(genre)).toList();
    } catch (e) {
      throw Exception('Repository error: $e');
    }
  }

  Future<MoviesResponse> discoverMoviesByGenre(int genreId, {int page = 1}) async {
    try {
      final response = await _apiService.discoverMoviesByGenre(genreId, page: page);
      return MoviesResponse.fromJson(response);
    } catch (e) {
      throw Exception('Repository error: $e');
    }
  }

  Future<VideosResponse> getMovieVideos(int movieId) async {
    try {
      final response = await _apiService.getMovieVideos(movieId);
      return VideosResponse.fromJson(response);
    } catch (e) {
      throw Exception('Repository error: $e');
    }
  }
}
