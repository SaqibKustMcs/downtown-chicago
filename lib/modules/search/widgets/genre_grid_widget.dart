import 'package:flutter/material.dart';
import '../../../data/models/genre_model.dart';
import '../../../styles/styles.dart';
import '../viewmodels/search_viewmodel.dart';
import 'genre_card_widget.dart';

class GenreGridWidget extends StatelessWidget {
  final SearchViewModel viewModel;
  final Function(GenreModel) onGenreTap;

  const GenreGridWidget({super.key, required this.viewModel, required this.onGenreTap});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: viewModel.isLoadingNotifier,
      builder: (context, isLoading, child) {
        if (isLoading) {
          return Center(child: CircularProgressIndicator(color: CustomColors.purpleColor));
        }

        return ValueListenableBuilder<String?>(
          valueListenable: viewModel.errorNotifier,
          builder: (context, error, child) {
            if (error != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      error,
                      style: TextStyle(color: CustomColors.pinkColor),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            return ValueListenableBuilder<List<GenreModel>>(
              valueListenable: viewModel.genresNotifier,
              builder: (context, genres, child) {
                if (genres.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [Text('No genres available', style: Theme.of(context).textTheme.titleMedium)],
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.5,
                  ),
                  itemCount: genres.length,
                  itemBuilder: (context, index) {
                    final genre = genres[index];
                    return GenreCardWidget(genre: genre, index: index, onTap: () => onGenreTap(genre));
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
