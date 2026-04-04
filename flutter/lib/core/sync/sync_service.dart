import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';
import 'pending_change.dart';

class SyncService {
  final AppDatabase _db;
  final Dio _dio;
  final PendingChangeService _pendingChanges;
  bool _isSyncing = false;

  SyncService(this._db, this._dio)
      : _pendingChanges = PendingChangeService(_db);

  bool get isSyncing => _isSyncing;

  Future<SyncResult> sync() async {
    if (_isSyncing) return SyncResult(replayed: 0, failed: 0);
    _isSyncing = true;

    try {
      final result = await _replayPendingChanges();
      await _refreshCaches();
      return result;
    } finally {
      _isSyncing = false;
    }
  }

  Future<SyncResult> _replayPendingChanges() async {
    final changes = await _pendingChanges.getAll();
    int replayed = 0;
    int failed = 0;

    for (final change in changes) {
      try {
        final payload = change.payloadJson != null
            ? jsonDecode(change.payloadJson!) as Map<String, dynamic>?
            : null;

        Response response;
        switch (change.action) {
          case 'CREATE':
            response = await _dio.post(change.endpoint, data: payload);
            break;
          case 'UPDATE':
            response = await _dio.put(change.endpoint, data: payload);
            break;
          case 'PATCH':
            response = await _dio.patch(change.endpoint, data: payload);
            break;
          case 'DELETE':
            response = await _dio.delete(change.endpoint);
            break;
          default:
            await _pendingChanges.remove(change.id);
            continue;
        }

        final status = response.statusCode ?? 0;
        if (status >= 200 && status < 300 || status == 404 || status == 409) {
          await _pendingChanges.remove(change.id);
          replayed++;
        } else {
          failed++;
        }
      } on DioException catch (_) {
        failed++;
        if (change.retryCount >= 5) {
          await _pendingChanges.remove(change.id);
        }
      }
    }

    return SyncResult(replayed: replayed, failed: failed);
  }

  Future<void> _refreshCaches() async {
    // Refresh all cached data from server
    try {
      await _refreshMembers();
      await _refreshCategories();
      await _refreshEvents();
      await _refreshTodos();
      await _refreshRecipes();
      await _refreshShopping();
      await _refreshPantry();
    } catch (_) {
      // Non-critical: cache refresh failures are acceptable
    }
  }

  Future<void> _refreshMembers() async {
    try {
      final response = await _dio.get('/api/family-members');
      final items = (response.data as List);
      await _db.delete(_db.cachedFamilyMembers).go();
      for (final item in items) {
        await _db.into(_db.cachedFamilyMembers).insert(
          CachedFamilyMembersCompanion.insert(
            id: Value(item['id'] as int),
            name: item['name'] as String,
            emoji: Value(item['emoji'] as String?),
            color: Value(item['color'] as String?),
          ),
        );
      }
    } catch (_) {}
  }

  Future<void> _refreshCategories() async {
    try {
      final response = await _dio.get('/api/categories');
      final items = (response.data as List);
      await _db.delete(_db.cachedCategories).go();
      for (final item in items) {
        await _db.into(_db.cachedCategories).insert(
          CachedCategoriesCompanion.insert(
            id: Value(item['id'] as int),
            name: item['name'] as String,
            color: Value(item['color'] as String?),
          ),
        );
      }
    } catch (_) {}
  }

  Future<void> _refreshEvents() async {
    try {
      final now = DateTime.now();
      final start = now.subtract(const Duration(days: 30));
      final end = now.add(const Duration(days: 60));
      final response = await _dio.get('/api/events', queryParameters: {
        'start_date': start.toIso8601String(),
        'end_date': end.toIso8601String(),
      });
      final items = (response.data as List);
      await _db.delete(_db.cachedEvents).go();
      for (final item in items) {
        await _db.into(_db.cachedEvents).insert(
          CachedEventsCompanion.insert(
            id: Value(item['id'] as int),
            title: item['title'] as String,
            description: Value(item['description'] as String?),
            startTime: DateTime.parse(item['start_time'] as String),
            endTime: DateTime.parse(item['end_time'] as String),
            allDay: Value(item['all_day'] as bool? ?? false),
            categoryId: Value(item['category_id'] as int?),
            categoryName: Value(item['category_name'] as String?),
            categoryColor: Value(item['category_color'] as String?),
            memberIdsJson: Value(jsonEncode(item['member_ids'] ?? [])),
          ),
        );
      }
    } catch (_) {}
  }

  Future<void> _refreshTodos() async {
    try {
      final response = await _dio.get('/api/todos');
      final items = (response.data as List);
      await _db.delete(_db.cachedTodos).go();
      for (final item in items) {
        await _db.into(_db.cachedTodos).insert(
          CachedTodosCompanion.insert(
            id: Value(item['id'] as int),
            title: item['title'] as String,
            description: Value(item['description'] as String?),
            priority: Value(item['priority'] as String? ?? 'none'),
            completed: Value(item['completed'] as bool? ?? false),
            dueDate: Value(item['due_date'] != null ? DateTime.parse(item['due_date'] as String) : null),
            categoryId: Value(item['category_id'] as int?),
            eventId: Value(item['event_id'] as int?),
            parentId: Value(item['parent_id'] as int?),
            memberIdsJson: Value(jsonEncode(item['member_ids'] ?? [])),
          ),
        );
      }
    } catch (_) {}
  }

  Future<void> _refreshRecipes() async {
    try {
      final response = await _dio.get('/api/recipes');
      final items = (response.data as List);
      await _db.delete(_db.cachedRecipes).go();
      for (final item in items) {
        await _db.into(_db.cachedRecipes).insert(
          CachedRecipesCompanion.insert(
            id: Value(item['id'] as int),
            name: item['name'] as String,
            description: Value(item['description'] as String?),
            difficulty: Value(item['difficulty'] as String? ?? 'mittel'),
            prepTime: Value(item['prep_time'] as int?),
            imageUrl: Value(item['image_url'] as String?),
            isCookidoo: Value(item['is_cookidoo'] as bool? ?? false),
            ingredientsJson: Value(jsonEncode(item['ingredients'] ?? [])),
          ),
        );
      }
    } catch (_) {}
  }

  Future<void> _refreshShopping() async {
    try {
      final response = await _dio.get('/api/shopping/list');
      final data = response.data as Map<String, dynamic>;
      final items = (data['items'] as List?) ?? [];
      await _db.delete(_db.cachedShoppingItems).go();
      for (final item in items) {
        await _db.into(_db.cachedShoppingItems).insert(
          CachedShoppingItemsCompanion.insert(
            id: Value(item['id'] as int),
            name: item['name'] as String,
            amount: Value((item['amount'] as num?)?.toDouble()),
            unit: Value(item['unit'] as String?),
            checked: Value(item['checked'] as bool? ?? false),
            isManual: Value(item['is_manual'] as bool? ?? false),
            category: Value(item['category'] as String?),
            sortOrder: Value(item['sort_order'] as int?),
          ),
        );
      }
    } catch (_) {}
  }

  Future<void> _refreshPantry() async {
    try {
      final response = await _dio.get('/api/pantry');
      final items = (response.data as List);
      await _db.delete(_db.cachedPantryItems).go();
      for (final item in items) {
        await _db.into(_db.cachedPantryItems).insert(
          CachedPantryItemsCompanion.insert(
            id: Value(item['id'] as int),
            name: item['name'] as String,
            quantity: Value((item['quantity'] as num?)?.toDouble()),
            unit: Value(item['unit'] as String?),
            category: Value(item['category'] as String?),
            expiryDate: Value(item['expiry_date'] != null ? DateTime.parse(item['expiry_date'] as String) : null),
            lowStockThreshold: Value(item['low_stock_threshold'] as int?),
          ),
        );
      }
    } catch (_) {}
  }
}

class SyncResult {
  final int replayed;
  final int failed;

  SyncResult({required this.replayed, required this.failed});
}

final syncServiceProvider = Provider<SyncService>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final dio = ref.watch(dioProvider);
  return SyncService(db, dio);
});

final syncStatusProvider = StateProvider<SyncStatus>((ref) => SyncStatus.idle);

enum SyncStatus { idle, syncing, success, error }

final pendingCountProvider = FutureProvider<int>((ref) {
  return PendingChangeService(ref.watch(appDatabaseProvider)).count();
});

