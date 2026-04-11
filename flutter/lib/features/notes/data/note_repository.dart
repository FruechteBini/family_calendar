import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import '../../../core/api/api_client.dart';
import '../../../core/api/endpoints.dart';
import '../domain/note.dart';
import '../domain/note_attachment.dart';
import '../domain/note_comment.dart';

class NoteRepository {
  final Dio _dio;

  NoteRepository(this._dio);

  Future<List<Note>> getNotes({
    String scope = 'all',
    int? categoryId,
    String? type,
    int? tagId,
    String? search,
    bool isArchived = false,
    bool? isPinned,
  }) async {
    try {
      final params = <String, dynamic>{
        'scope': scope,
        'is_archived': isArchived,
      };
      if (categoryId != null) params['category_id'] = categoryId;
      if (type != null) params['type'] = type;
      if (tagId != null) params['tag_id'] = tagId;
      if (search != null && search.trim().isNotEmpty) {
        params['search'] = search.trim();
      }
      if (isPinned != null) params['is_pinned'] = isPinned;

      final response = await _dio.get(
        Endpoints.notes,
        queryParameters: params,
      );
      return (response.data as List)
          .map((e) => Note.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Note> getNote(int id) async {
    try {
      final response = await _dio.get(Endpoints.note(id));
      return Note.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Note> createNote(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(Endpoints.notes, data: data);
      return Note.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Note> updateNote(int id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put(Endpoints.note(id), data: data);
      return Note.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> deleteNote(int id) async {
    try {
      await _dio.delete(Endpoints.note(id));
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Note> togglePin(int id) async {
    try {
      final response = await _dio.patch(Endpoints.notePin(id));
      return Note.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Note> toggleArchive(int id) async {
    try {
      final response = await _dio.patch(Endpoints.noteArchive(id));
      return Note.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Note> setColor(int id, String? color) async {
    try {
      final response = await _dio.patch(
        Endpoints.noteColor(id),
        data: {'color': color},
      );
      return Note.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> reorderNotes(List<int> ids) async {
    try {
      await _dio.put(Endpoints.notesReorder, data: {'ids': ids});
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<LinkPreview> previewLink(String url) async {
    try {
      final response = await _dio.post(
        Endpoints.notesPreviewLink,
        data: {'url': url},
      );
      return LinkPreview.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<DuplicateLinkResult> checkDuplicateLink(String url) async {
    try {
      final response = await _dio.get(
        Endpoints.notesCheckDuplicate,
        queryParameters: {'url': url},
      );
      return DuplicateLinkResult.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Map<String, dynamic>> convertToTodo(int id, {bool archiveNote = true}) async {
    try {
      final response = await _dio.post(
        Endpoints.noteConvertToTodo(id),
        data: {'archive_note': archiveNote},
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<NoteComment> addComment(int noteId, String content) async {
    try {
      final response = await _dio.post(
        Endpoints.noteComments(noteId),
        data: {'content': content},
      );
      return NoteComment.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> deleteComment(int noteId, int commentId) async {
    try {
      await _dio.delete(Endpoints.noteComment(noteId, commentId));
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<NoteAttachment> uploadAttachment(int noteId, String filePath) async {
    return uploadAttachmentData(
      noteId,
      filename: path.basename(filePath),
      filePath: filePath,
    );
  }

  /// Web: [bytes] + [filename]; native: [filePath] + [filename].
  Future<NoteAttachment> uploadAttachmentData(
    int noteId, {
    required String filename,
    String? filePath,
    Uint8List? bytes,
  }) async {
    if (filePath == null && bytes == null) {
      throw ArgumentError('filePath oder bytes erforderlich');
    }
    try {
      final MultipartFile mf;
      if (filePath != null) {
        mf = await MultipartFile.fromFile(filePath, filename: filename);
      } else {
        mf = MultipartFile.fromBytes(bytes!, filename: filename);
      }
      final form = FormData.fromMap({'file': mf});
      final response = await _dio.post(
        Endpoints.noteAttachments(noteId),
        data: form,
      );
      return NoteAttachment.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> deleteAttachment(int noteId, int attachmentId) async {
    try {
      await _dio.delete(Endpoints.noteAttachment(noteId, attachmentId));
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}

final noteRepositoryProvider = Provider<NoteRepository>((ref) {
  return NoteRepository(ref.watch(dioProvider));
});
