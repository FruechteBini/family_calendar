import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/endpoints.dart';
import '../domain/note_tag.dart';

class NoteTagRepository {
  final Dio _dio;

  NoteTagRepository(this._dio);

  Future<List<NoteTag>> getTags() async {
    try {
      final response = await _dio.get(Endpoints.noteTags);
      return (response.data as List)
          .map((e) => NoteTag.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<NoteTag> createTag(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(Endpoints.noteTags, data: data);
      return NoteTag.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<NoteTag> updateTag(int id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put(Endpoints.noteTag(id), data: data);
      return NoteTag.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> deleteTag(int id) async {
    try {
      await _dio.delete(Endpoints.noteTag(id));
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}

final noteTagRepositoryProvider = Provider<NoteTagRepository>((ref) {
  return NoteTagRepository(ref.watch(dioProvider));
});
