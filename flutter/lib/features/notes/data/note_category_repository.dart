import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/endpoints.dart';
import '../../../core/auth/auth_provider.dart';
import '../domain/note_category.dart';

class NoteCategoryRepository {
  NoteCategoryRepository(this._dio);

  final Dio _dio;

  Future<List<NoteCategory>> getCategories({required bool isPersonal}) async {
    final response = await _dio.get(
      Endpoints.noteCategories,
      queryParameters: {
        'scope': isPersonal ? 'personal' : 'family',
      },
    );
    final list = response.data as List<dynamic>;
    return list
        .map((e) => NoteCategory.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<NoteCategory> createCategory(Map<String, dynamic> data) async {
    final response = await _dio.post(Endpoints.noteCategories, data: data);
    return NoteCategory.fromJson(response.data as Map<String, dynamic>);
  }

  Future<NoteCategory> updateCategory(int id, Map<String, dynamic> data) async {
    final response = await _dio.put(Endpoints.noteCategory(id), data: data);
    return NoteCategory.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteCategory(int id) async {
    await _dio.delete(
      Endpoints.noteCategory(id),
      options: Options(responseType: ResponseType.plain),
    );
  }

  Future<void> reorderCategories(
    List<int> ids, {
    required bool isPersonal,
  }) async {
    await _dio.put(
      Endpoints.noteCategoriesReorder,
      data: {'ids': ids},
      queryParameters: {
        'scope': isPersonal ? 'personal' : 'family',
      },
      options: Options(responseType: ResponseType.plain),
    );
  }
}

final noteCategoryRepositoryProvider =
    Provider<NoteCategoryRepository>((ref) {
  return NoteCategoryRepository(ref.watch(dioProvider));
});

/// [forPersonal] `true` = persönliche Kategorien, `false` = Familien-Kategorien.
final noteCategoriesListProvider =
    FutureProvider.family<List<NoteCategory>, bool>((ref, forPersonal) {
  ref.watch(authStateProvider.select((s) => s.user?.id));
  return ref
      .watch(noteCategoryRepositoryProvider)
      .getCategories(isPersonal: forPersonal);
});

void invalidateNoteCategoryCaches(WidgetRef ref) {
  ref.invalidate(noteCategoriesListProvider(true));
  ref.invalidate(noteCategoriesListProvider(false));
}
