// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// **************************************************************************
// FloorGenerator
// **************************************************************************

abstract class $AppDatabaseBuilderContract {
  /// Adds migrations to the builder.
  $AppDatabaseBuilderContract addMigrations(List<Migration> migrations);

  /// Adds a database [Callback] to the builder.
  $AppDatabaseBuilderContract addCallback(Callback callback);

  /// Creates the database and initializes it.
  Future<AppDatabase> build();
}

// ignore: avoid_classes_with_only_static_members
class $FloorAppDatabase {
  /// Creates a database builder for a persistent database.
  /// Once a database is built, you should keep a reference to it and re-use it.
  static $AppDatabaseBuilderContract databaseBuilder(String name) =>
      _$AppDatabaseBuilder(name);

  /// Creates a database builder for an in memory database.
  /// Information stored in an in memory database disappears when the process is killed.
  /// Once a database is built, you should keep a reference to it and re-use it.
  static $AppDatabaseBuilderContract inMemoryDatabaseBuilder() =>
      _$AppDatabaseBuilder(null);
}

class _$AppDatabaseBuilder implements $AppDatabaseBuilderContract {
  _$AppDatabaseBuilder(this.name);

  final String? name;

  final List<Migration> _migrations = [];

  Callback? _callback;

  @override
  $AppDatabaseBuilderContract addMigrations(List<Migration> migrations) {
    _migrations.addAll(migrations);
    return this;
  }

  @override
  $AppDatabaseBuilderContract addCallback(Callback callback) {
    _callback = callback;
    return this;
  }

  @override
  Future<AppDatabase> build() async {
    final path = name != null
        ? await sqfliteDatabaseFactory.getDatabasePath(name!)
        : ':memory:';
    final database = _$AppDatabase();
    database.database = await database.open(
      path,
      _migrations,
      _callback,
    );
    return database;
  }
}

class _$AppDatabase extends AppDatabase {
  _$AppDatabase([StreamController<String>? listener]) {
    changeListener = listener ?? StreamController<String>.broadcast();
  }

  MovieDao? _movieDaoInstance;

  Future<sqflite.Database> open(
    String path,
    List<Migration> migrations, [
    Callback? callback,
  ]) async {
    final databaseOptions = sqflite.OpenDatabaseOptions(
      version: 1,
      onConfigure: (database) async {
        await database.execute('PRAGMA foreign_keys = ON');
        await callback?.onConfigure?.call(database);
      },
      onOpen: (database) async {
        await callback?.onOpen?.call(database);
      },
      onUpgrade: (database, startVersion, endVersion) async {
        await MigrationAdapter.runMigrations(
            database, startVersion, endVersion, migrations);

        await callback?.onUpgrade?.call(database, startVersion, endVersion);
      },
      onCreate: (database, version) async {
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `movies` (`id` INTEGER NOT NULL, `title` TEXT NOT NULL, `overview` TEXT NOT NULL, `posterPath` TEXT, `backdropPath` TEXT, `voteAverage` REAL NOT NULL, `releaseDate` TEXT NOT NULL, `genreIds` TEXT NOT NULL, `cacheType` TEXT NOT NULL, `page` INTEGER NOT NULL, `timestamp` INTEGER NOT NULL, PRIMARY KEY (`id`))');

        await callback?.onCreate?.call(database, version);
      },
    );
    return sqfliteDatabaseFactory.openDatabase(path, options: databaseOptions);
  }

  @override
  MovieDao get movieDao {
    return _movieDaoInstance ??= _$MovieDao(database, changeListener);
  }
}

class _$MovieDao extends MovieDao {
  _$MovieDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _movieEntityInsertionAdapter = InsertionAdapter(
            database,
            'movies',
            (MovieEntity item) => <String, Object?>{
                  'id': item.id,
                  'title': item.title,
                  'overview': item.overview,
                  'posterPath': item.posterPath,
                  'backdropPath': item.backdropPath,
                  'voteAverage': item.voteAverage,
                  'releaseDate': item.releaseDate,
                  'genreIds': item.genreIds,
                  'cacheType': item.cacheType,
                  'page': item.page,
                  'timestamp': item.timestamp
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<MovieEntity> _movieEntityInsertionAdapter;

  @override
  Future<List<MovieEntity>> getMoviesByCacheType(String cacheType) async {
    return _queryAdapter.queryList(
        'SELECT * FROM movies WHERE cacheType = ?1 ORDER BY page ASC, voteAverage DESC',
        mapper: (Map<String, Object?> row) => MovieEntity(id: row['id'] as int, title: row['title'] as String, overview: row['overview'] as String, posterPath: row['posterPath'] as String?, backdropPath: row['backdropPath'] as String?, voteAverage: row['voteAverage'] as double, releaseDate: row['releaseDate'] as String, genreIds: row['genreIds'] as String, cacheType: row['cacheType'] as String, page: row['page'] as int, timestamp: row['timestamp'] as int),
        arguments: [cacheType]);
  }

  @override
  Future<List<MovieEntity>> getMoviesByCacheTypeAndPage(
    String cacheType,
    int page,
  ) async {
    return _queryAdapter.queryList(
        'SELECT * FROM movies WHERE cacheType = ?1 AND page = ?2',
        mapper: (Map<String, Object?> row) => MovieEntity(
            id: row['id'] as int,
            title: row['title'] as String,
            overview: row['overview'] as String,
            posterPath: row['posterPath'] as String?,
            backdropPath: row['backdropPath'] as String?,
            voteAverage: row['voteAverage'] as double,
            releaseDate: row['releaseDate'] as String,
            genreIds: row['genreIds'] as String,
            cacheType: row['cacheType'] as String,
            page: row['page'] as int,
            timestamp: row['timestamp'] as int),
        arguments: [cacheType, page]);
  }

  @override
  Future<void> deleteExpiredMovies(int expirationTimestamp) async {
    await _queryAdapter.queryNoReturn('DELETE FROM movies WHERE timestamp < ?1',
        arguments: [expirationTimestamp]);
  }

  @override
  Future<void> insertMovies(List<MovieEntity> movies) async {
    await _movieEntityInsertionAdapter.insertList(
        movies, OnConflictStrategy.replace);
  }
}
