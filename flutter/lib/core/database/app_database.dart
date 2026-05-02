import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'tables/tables.dart';
import 'connection/native.dart'
    if (dart.library.html) 'connection/web.dart';

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
  AppDatabase() : super(openConnection());

  @override
  int get schemaVersion => 5;

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
          if (from < 4) {
            await m.addColumn(cachedEvents, cachedEvents.color);
          }
          if (from < 5) {
            await m.addColumn(cachedCategories, cachedCategories.isPersonal);
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


final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});
