import 'package:drift/web.dart';
import 'package:drift/drift.dart';

DatabaseConnection openConnection() {
  return DatabaseConnection(WebDatabase('familienkalender'));
}
