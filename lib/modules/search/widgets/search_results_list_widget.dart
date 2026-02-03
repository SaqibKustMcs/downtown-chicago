import 'package:flutter/material.dart';
import '../../../data/models/movie_model.dart';
import '../../../styles/styles.dart';
import '../viewmodels/search_viewmodel.dart';
import 'movie_list_item_widget.dart';

class SearchResultsListWidget extends StatefulWidget {
  final SearchViewModel viewModel;
  final Function(MovieModel) onMovieTap;

  const SearchResultsListWidget({super.key, required this.viewModel, required this.onMovieTap});

  @override
  State<SearchResultsListWidget> createState() => _SearchResultsListWidgetState();
}

class _SearchResultsListWidgetState extends State<SearchResultsListWidget> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      widget.viewModel.loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: widget.viewModel.isLoadingNotifier,
      builder: (context, isLoading, child) {
        if (isLoading) {
          return Center(child: CircularProgressIndicator(color: CustomColors.purpleColor));
        }

        return ValueListenableBuilder<String?>(
          valueListenable: widget.viewModel.errorNotifier,
          builder: (context, error, child) {
            if (error != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: CustomColors.pinkColor),
                    const SizedBox(height: 16),
                    Text(
                      error,
                      style: TextStyle(color: CustomColors.pinkColor),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            return ValueListenableBuilder<List<MovieModel>>(
              valueListenable: widget.viewModel.searchResultsNotifier,
              builder: (context, movies, child) {
                if (movies.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: CustomColors.secondaryTextColor),
                        const SizedBox(height: 16),
                        Text('No results found', style: Theme.of(context).textTheme.titleMedium),
                      ],
                    ),
                  );
                }

                return ValueListenableBuilder<bool>(
                  valueListenable: widget.viewModel.isLoadingMoreNotifier,
                  builder: (context, isLoadingMore, child) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            itemCount: movies.length + (isLoadingMore ? 1 : 0),
                            itemExtent: 116,
                            cacheExtent: 500,
                            addAutomaticKeepAlives: true,
                            addRepaintBoundaries: true,
                            addSemanticIndexes: true,
                            physics: const BouncingScrollPhysics(),
                            itemBuilder: (context, index) {
                              if (index == movies.length) {
                                return Center(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 20),
                                    child: SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        color: CustomColors.buttonColor,
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  ),
                                );
                              }

                              final movie = movies[index];
                              return RepaintBoundary(
                                key: ValueKey(movie.id),
                                child: MovieListItemWidget(movie: movie, onTap: () => widget.onMovieTap(movie)),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}
