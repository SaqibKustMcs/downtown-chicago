import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../data/models/movie_model.dart';
import '../../../styles/styles.dart';
import '../../../styles/layouts/sizes.dart';
import '../../../styles/typography/app_text_styles.dart';

class MovieListItemWidget extends StatelessWidget {
  final MovieModel movie;
  final VoidCallback onTap;

  const MovieListItemWidget({
    super.key,
    required this.movie,
    required this.onTap,
  });

  String _getGenre() {
    if (movie.genreIds.isEmpty) return 'Movie';
    
    final genreMap = <int, String>{};
    return genreMap[movie.genreIds.first] ?? 'Movie';
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        height: 100,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 130,
                height: 100,
                color: CustomColors.borderColor,
                child: movie.posterUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: movie.posterUrl,
                        fit: BoxFit.cover,
                        memCacheWidth: 260,
                        memCacheHeight: 200,
                        maxWidthDiskCache: 260,
                        maxHeightDiskCache: 200,
                        placeholder: (context, url) => Container(
                          color: CustomColors.borderColor,
                          child: Center(
                            child: CircularProgressIndicator(
                              color: CustomColors.purpleColor,
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: CustomColors.borderColor,
                          child: Icon(
                            Icons.movie,
                            color: CustomColors.secondaryTextColor,
                            size: 32,
                          ),
                        ),
                      )
                    : Icon(
                        Icons.movie,
                        color: CustomColors.buttonColor,
                        size: 35,
                      ),
              ),
            ),
            const SizedBox(width: 21),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    movie.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getGenre(),
                    style: AppTextStyles.bodyLargeSecondary,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.more_horiz,
                color: CustomColors.secondaryTextColor,
              ),
              onPressed: onTap,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
      ),
    );
  }
}
