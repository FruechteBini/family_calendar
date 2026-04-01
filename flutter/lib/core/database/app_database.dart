import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'tables/tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [
  CachedEvents,
  CachedTodos,
  CachedRecipes,
  CachedCategories,
  CachedFamilyMembers,
  CachedShoppingItems,
  CachedPantryItems,
  PendingChanges,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          // Future migrations go here
        },
      );

  // Pending changes operations
  Future<List<PendingChange>> getPendingChanges() =>
      (select(pendingChanges)..orderBy([(t) => OrderingTerm.asc(t.createdAt)])).get();

  Future<int> insertPendingChange(PendingChangesCompanion entry) =>
      into(pendingChanges).insert(entry);

  Future<void> deletePendingChange(int id) =>
      (delete(pendingChanges)..where((t) => t.id.equals(id))).go();

  Future<void> incrementRetry(int id) =>
      (update(pendingChanges)..where((t) => t.id.equals(id)))
          .write(PendingChangesCompanion(retryCount: pendingChanges.retryCount + const Constant(1)));

  Future<int> pendingChangeCount() async {
    final count = countAll();
    final query = selectOnly(pendingChanges)..addColumns([count]);
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }

  // Cache clear
  Future<void> clearAllCaches() async {
    await delete(cachedEvents).go();
    await delete(cachedTodos).go();
    await delete(cachedRecipes).go();
    await delete(cachedCategories).go();
    await delete(cachedFamilyMembers).go();
    await delete(cachedShoppingItems).go();
    await delete(cachedPantryItems).go();
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'familienkalender.db'));
    return NativeDatabase.createInBackground(file);
  });
}

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});
