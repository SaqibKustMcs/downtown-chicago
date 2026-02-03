import 'dart:async';
import 'package:floor/floor.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'entities/movie_entity.dart';
import 'daos/movie_dao.dart';

part 'app_database.g.dart';

@Database(version: 1, entities: [MovieEntity])
abstract class AppDatabase extends FloorDatabase {
  MovieDao get movieDao;
}
