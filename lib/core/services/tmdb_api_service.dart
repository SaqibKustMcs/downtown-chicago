import 'package:dio/dio.dart';
import '../network/dio_client.dart';

class TmdbApiService {
  final Dio _dio = DioClient.instance;

  Future<Map<String, dynamic>> getUpcomingMovies({int page = 1}) async {
    try {
      final response = await _dio.get(
        'movie/upcoming',
        queryParameters: {
          'page': page,
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.error ?? 'Failed to load upcoming movies');
    }
  }

  Future<Map<String, dynamic>> getPopularMovies({int page = 1}) async {
    try {
      final response = await _dio.get(
        'movie/popular',
        queryParameters: {
          'page': page,
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.error ?? 'Failed to load popular movies');
    }
  }

  Future<Map<String, dynamic>> getNowPlayingMovies({int page = 1}) async {
    try {
      final response = await _dio.get(
        'movie/now_playing',
        queryParameters: {
          'page': page,
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.error ?? 'Failed to load now playing movies');
    }
  }

  Future<Map<String, dynamic>> getTopRatedMovies({int page = 1}) async {
    try {
      final response = await _dio.get(
        'movie/top_rated',
        queryParameters: {
          'page': page,
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.error ?? 'Failed to load top rated movies');
    }
  }

  Future<Map<String, dynamic>> getMovieDetails(int movieId) async {
    try {
      final response = await _dio.get('movie/$movieId');
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.error ?? 'Failed to load movie details');
    }
  }

  Future<Map<String, dynamic>> searchMovies(String query, {int page = 1}) async {
    try {
      final response = await _dio.get(
        'search/movie',
        queryParameters: {
          'query': query,
          'page': page,
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.error ?? 'Failed to search movies');
    }
  }

  Future<Map<String, dynamic>> getMovieCredits(int movieId) async {
    try {
      final response = await _dio.get('movie/$movieId/credits');
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.error ?? 'Failed to load movie credits');
    }
  }

  Future<Map<String, dynamic>> getSimilarMovies(int movieId, {int page = 1}) async {
    try {
      final response = await _dio.get(
        'movie/$movieId/similar',
        queryParameters: {
          'page': page,
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.error ?? 'Failed to load similar movies');
    }
  }

  Future<Map<String, dynamic>> getMovieVideos(int movieId) async {
    try {
      final response = await _dio.get('movie/$movieId/videos');
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.error ?? 'Failed to load movie videos');
    }
  }

  Future<Map<String, dynamic>> getGenres() async {
    try {
      final response = await _dio.get('genre/movie/list');
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.error ?? 'Failed to load genres');
    }
  }

  Future<Map<String, dynamic>> discoverMoviesByGenre(int genreId, {int page = 1}) async {
    try {
      final response = await _dio.get(
        'discover/movie',
        queryParameters: {
          'with_genres': genreId,
          'page': page,
          'sort_by': 'popularity.desc',
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.error ?? 'Failed to discover movies by genre');
    }
  }

  void cancelRequests() {
    _dio.close(force: true);
  }
}
