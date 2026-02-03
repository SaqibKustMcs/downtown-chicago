/// Base Repository Interface
/// All repositories should implement this interface
abstract class BaseRepository<T> {
  /// Get all items
  Future<List<T>> getAll();

  /// Get item by ID
  Future<T?> getById(String id);

  /// Create new item
  Future<String> create(T item);

  /// Update existing item
  Future<void> update(String id, T item);

  /// Delete item
  Future<void> delete(String id);
}

/// Base Repository with pagination support
abstract class BaseRepositoryWithPagination<T> extends BaseRepository<T> {
  /// Get items with pagination
  Future<List<T>> getPaginated({
    required int page,
    required int pageSize,
    String? lastDocumentId,
  });
}

/// Base Repository with filtering support
abstract class BaseRepositoryWithFilter<T> extends BaseRepository<T> {
  /// Get items with filters
  Future<List<T>> getFiltered(Map<String, dynamic> filters);
}
