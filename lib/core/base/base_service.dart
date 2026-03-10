import 'package:downtown/core/base/base_repository.dart';

/// Base Service Interface
/// All services should implement this interface
abstract class BaseService<T> {
  final BaseRepository<T> repository;

  BaseService(this.repository);

  /// Get all items
  Future<List<T>> getAll() => repository.getAll();

  /// Get item by ID
  Future<T?> getById(String id) => repository.getById(id);

  /// Create new item
  Future<String> create(T item) => repository.create(item);

  /// Update existing item
  Future<void> update(String id, T item) => repository.update(id, item);

  /// Delete item
  Future<void> delete(String id) => repository.delete(id);
}
