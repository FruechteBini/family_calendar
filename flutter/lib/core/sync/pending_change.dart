import 'dart:convert';
import 'package:drift/drift.dart';
import '../database/app_database.dart';

class PendingChangeService {
  final AppDatabase _db;

  PendingChangeService(this._db);

  Future<void> enqueue({
    required String action,
    required String endpoint,
    Map<String, dynamic>? payload,
  }) async {
    await _db.insertPendingChange(PendingChangesCompanion.insert(
      action: action,
      endpoint: endpoint,
      payloadJson: payload != null ? Value(jsonEncode(payload)) : const Value.absent(),
    ));
  }

  Future<List<PendingChange>> getAll() => _db.getPendingChanges();

  Future<void> remove(int id) => _db.deletePendingChange(id);

  Future<int> count() => _db.pendingChangeCount();
}
