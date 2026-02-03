import '../../data/database/app_database.dart';

class DatabaseService {
  static AppDatabase? _database;

  static Future<AppDatabase> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  static Future<AppDatabase> _initDatabase() async {
    return await $FloorAppDatabase
        .databaseBuilder('movie_database.db')
        .build();
  }

  static Future<void> closeDatabase() async {
    await _database?.close();
    _database = null;
  }
}
