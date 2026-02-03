import 'package:flutter/foundation.dart';
import '../../../data/models/movie_model.dart';
import '../../../data/models/genre_model.dart';
import '../../../core/services/repository_factory.dart';

class SearchViewModel {
  final _repository = RepositoryFactory.getMovieRepository();

  final ValueNotifier<bool> isLoadingNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isLoadingMoreNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<List<MovieModel>> searchResultsNotifier = ValueNotifier<List<MovieModel>>([]);
  final ValueNotifier<String?> errorNotifier = ValueNotifier<String?>(null);
  final ValueNotifier<String> searchQueryNotifier = ValueNotifier<String>('');
  final ValueNotifier<List<GenreModel>> genresNotifier = ValueNotifier<List<GenreModel>>([]);

  bool get isLoading => isLoadingNotifier.value;
  bool get isLoadingMore => isLoadingMoreNotifier.value;
  List<MovieModel> get searchResults => searchResultsNotifier.value;
  String? get error => errorNotifier.value;
  String get searchQuery => searchQueryNotifier.value;
  List<GenreModel> get genres => genresNotifier.value;

  int _currentPage = 1;
  int _totalPages = 1;
  String _lastSearchQuery = '';
  int? _lastGenreId;
  bool _hasMoreData = true;

  bool get hasMoreData => _hasMoreData && _currentPage < _totalPages;

  SearchViewModel() {
    loadGenres();
  }

  Future<void> loadGenres() async {
    try {
      isLoadingNotifier.value = true;
      errorNotifier.value = null;

      final genres = await _repository.getGenres();
      genresNotifier.value = genres;
    } catch (e) {
      errorNotifier.value = 'Failed to load genres: $e';
      if (kDebugMode) {
        print('Error loading genres: $e');
      }
    } finally {
      isLoadingNotifier.value = false;
    }
  }

  Future<void> loadUpcomingMovies({int page = 1}) async {
    try {
      isLoadingNotifier.value = true;
      errorNotifier.value = null;

      final response = await _repository.getUpcomingMovies(page: page);
      
      if (page == 1) {
        searchResultsNotifier.value = response.results;
      } else {
        searchResultsNotifier.value = [...searchResultsNotifier.value, ...response.results];
      }
    } catch (e) {
      errorNotifier.value = 'Failed to load movies: $e';
      if (kDebugMode) {
        print('Error loading upcoming movies: $e');
      }
    } finally {
      isLoadingNotifier.value = false;
    }
  }

  Future<void> searchMovies(String query, {int page = 1}) async {
    if (query.trim().isEmpty) {
      searchResultsNotifier.value = [];
      searchQueryNotifier.value = '';
      _resetPagination();
      return;
    }

    try {
      if (page == 1) {
        isLoadingNotifier.value = true;
        _resetPagination();
        _lastSearchQuery = query;
        _lastGenreId = null;
      } else {
        isLoadingMoreNotifier.value = true;
      }
      
      errorNotifier.value = null;
      searchQueryNotifier.value = query;

      final response = await _repository.searchMovies(query, page: page);
      
      _currentPage = response.page;
      _totalPages = response.totalPages;
      _hasMoreData = response.page < response.totalPages;

      if (page == 1) {
        searchResultsNotifier.value = response.results;
      } else {
        searchResultsNotifier.value = [...searchResultsNotifier.value, ...response.results];
      }
    } catch (e) {
      errorNotifier.value = 'Failed to search movies: $e';
      if (kDebugMode) {
        print('Error searching movies: $e');
      }
    } finally {
      isLoadingNotifier.value = false;
      isLoadingMoreNotifier.value = false;
    }
  }

  Future<void> getMoviesByGenre(int genreId, String genreName, {int page = 1}) async {
    try {
      if (page == 1) {
        isLoadingNotifier.value = true;
        _resetPagination();
        _lastGenreId = genreId;
        _lastSearchQuery = '';
      } else {
        isLoadingMoreNotifier.value = true;
      }
      
      errorNotifier.value = null;
      searchQueryNotifier.value = genreName;

      final response = await _repository.discoverMoviesByGenre(genreId, page: page);
      
      _currentPage = response.page;
      _totalPages = response.totalPages;
      _hasMoreData = response.page < response.totalPages;

      if (page == 1) {
        searchResultsNotifier.value = response.results;
      } else {
        searchResultsNotifier.value = [...searchResultsNotifier.value, ...response.results];
      }
    } catch (e) {
      errorNotifier.value = 'Failed to load movies: $e';
      if (kDebugMode) {
        print('Error loading movies by genre: $e');
      }
    } finally {
      isLoadingNotifier.value = false;
      isLoadingMoreNotifier.value = false;
    }
  }

  void clearSearch() {
    searchQueryNotifier.value = '';
    errorNotifier.value = null;
    _resetPagination();
    loadUpcomingMovies();
  }

  Future<void> loadMore() async {
    if (!hasMoreData || isLoadingNotifier.value || isLoadingMoreNotifier.value) {
      return;
    }

    final nextPage = _currentPage + 1;

    if (_lastGenreId != null) {
      await getMoviesByGenre(_lastGenreId!, searchQueryNotifier.value, page: nextPage);
    } else if (_lastSearchQuery.isNotEmpty) {
      await searchMovies(_lastSearchQuery, page: nextPage);
    }
  }

  void _resetPagination() {
    _currentPage = 1;
    _totalPages = 1;
    _hasMoreData = true;
    _lastSearchQuery = '';
    _lastGenreId = null;
  }

  void dispose() {
    isLoadingNotifier.dispose();
    isLoadingMoreNotifier.dispose();
    searchResultsNotifier.dispose();
    errorNotifier.dispose();
    searchQueryNotifier.dispose();
    genresNotifier.dispose();
  }
}
