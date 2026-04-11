import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../domain/knuspr.dart';
import 'knuspr_repository.dart';

/// Cached Knuspr availability for the session (refresh manually if needed).
final knusprStatusProvider = FutureProvider<KnusprStatus>((ref) async {
  try {
    return await ref.read(knusprRepositoryProvider).getStatus();
  } on ApiException {
    return const KnusprStatus(available: false, configured: false);
  }
});
