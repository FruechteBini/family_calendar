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
  CachedRecipeCategories,
  CachedFamilyMembers,
  CachedShoppingItems,
  CachedPantryItems,
  CachedNotes,
  CachedNoteCategories,
  PendingChanges,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          if (from < 2) {
            await m.createTable(cachedNotes);
            await m.createTable(cachedNoteCategories);
          }
          if (from < 3) {
            await m.createTable(cachedRecipeCategories);
            await m.addColumn(cachedRecipes, cachedRecipes.recipeCategoryId);
            await m.addColumn(cachedRecipes, cachedRecipes.recipeCategoryName);
            await m.addColumn(cachedRecipes, cachedRecipes.tagsJson);
          }
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
      _incrementRetryInternal(id);

  Future<void> _incrementRetryInternal(int id) async {
    final row =
        await (select(pendingChanges)..where((t) => t.id.equals(id))).getSingleOrNull();
    if (row == null) return;
    await (update(pendingChanges)..where((t) => t.id.equals(id))).write(
      PendingChangesCompanion(
        retryCount: Value(row.retryCount + 1),
      ),
    );
  }

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
    await delete(cachedNotes).go();
    await delete(cachedNoteCategories).go();
    await delete(cachedRecipeCategories).go();
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
