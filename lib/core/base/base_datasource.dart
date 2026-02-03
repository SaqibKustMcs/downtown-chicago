/// Base DataSource Interface
/// All data sources should implement this interface
abstract class BaseDataSource<T> {
  /// Get all items
  Future<List<Map<String, dynamic>>> getAll();

  /// Get item by ID
  Future<Map<String, dynamic>?> getById(String id);

  /// Create new item
  Future<String> create(Map<String, dynamic> data);

  /// Update existing item
  Future<void> update(String id, Map<String, dynamic> data);

  /// Delete item
  Future<void> delete(String id);
}

/// Remote DataSource Interface (Firebase, API, etc.)
abstract class RemoteDataSource<T> extends BaseDataSource<T> {
  /// Stream items (for real-time updates)
  Stream<List<Map<String, dynamic>>> streamAll();
  
  /// Stream single item
  Stream<Map<String, dynamic>?> streamById(String id);
}

/// Local DataSource Interface (SQLite, SharedPreferences, etc.)
abstract class LocalDataSource<T> extends BaseDataSource<T> {
  /// Clear all local data
  Future<void> clearAll();
}
