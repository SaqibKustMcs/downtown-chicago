import 'dart:math';
import 'package:flutter/material.dart';
import 'package:food_flow_app/core/constants/app_images.dart';
import '../../../data/models/genre_model.dart';
import '../../../styles/styles.dart';
import '../../../styles/layouts/sizes.dart';
import '../../../styles/typography/app_text_styles.dart';

class GenreCardWidget extends StatelessWidget {
  final GenreModel genre;
  final int index;
  final VoidCallback onTap;

  const GenreCardWidget({super.key, required this.genre, required this.index, required this.onTap});

  String _getGenreImage() {
    final genreId = genre.id;
    final genreName = genre.name.toLowerCase();

    if (genreName.contains('drama')) {
      return AppImages.dramas;
    } else if (genreName.contains('crime')) {
      return AppImages.crime;
    } else if (genreName.contains('documentary') || genreName.contains('documentaries')) {
      return AppImages.documentaries;
    } else if (genreName.contains('family')) {
      return AppImages.family;
    } else if (genreName.contains('fantasy')) {
      return AppImages.fantasy;
    } else if (genreName.contains('holiday') || genreName.contains('christmas')) {
      return AppImages.holidays;
    } else if (genreName.contains('horror')) {
      return AppImages.horror;
    }

    final imageMap = {18: AppImages.dramas, 80: AppImages.crime, 99: AppImages.documentaries, 10751: AppImages.family, 14: AppImages.fantasy, 27: AppImages.horror};

    if (imageMap.containsKey(genreId)) {
      return imageMap[genreId]!;
    }

    final allImages = [AppImages.dramas, AppImages.crime, AppImages.documentaries, AppImages.family, AppImages.fantasy, AppImages.holidays, AppImages.horror];

    final random = Random(genreId);
    return allImages[random.nextInt(allImages.length)];
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(color: CustomColors.primaryColor.withOpacity(0.9), borderRadius: BorderRadius.circular(12)),
          child: Stack(
            children: [
              Container(
                height: double.infinity,
                width: double.infinity,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(_getGenreImage(), fit: BoxFit.cover),
                      Container(color: const Color(0xff000000).withOpacity(0.30)),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(genre.name, style: AppTextStyles.titleWhite, textAlign: TextAlign.center),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
