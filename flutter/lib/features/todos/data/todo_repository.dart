import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import '../../../core/api/api_client.dart';
import '../../../core/api/endpoints.dart';
import '../domain/todo.dart';
import '../domain/todo_attachment.dart';

class TodoRepository {
  final Dio _dio;

  TodoRepository(this._dio);

  Future<Todo> getTodo(int id) async {
    try {
      final response = await _dio.get(Endpoints.todo(id));
      return Todo.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<Todo>> getTodos({
    String scope = 'all', // all|personal|family
    int? viewMemberId,
    String? priority,
    int? memberId,
    bool? completed,
    int? categoryId,
  }) async {
    try {
      final params = <String, dynamic>{};
      params['scope'] = scope;
      if (viewMemberId != null) params['view_member_id'] = viewMemberId;
      if (priority != null) params['priority'] = priority;
      if (memberId != null) params['member_id'] = memberId;
      if (completed != null) params['completed'] = completed;
      if (categoryId != null) params['category_id'] = categoryId;

      final response = await _dio.get(
        Endpoints.todos,
        queryParameters: params,
      );
      return (response.data as List)
          .map((e) => Todo.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Todo> createTodo(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(Endpoints.todos, data: data);
      return Todo.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Todo> updateTodo(int id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put(Endpoints.todo(id), data: data);
      return Todo.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> deleteTodo(int id) async {
    try {
      await _dio.delete(Endpoints.todo(id));
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Todo> completeTodo(int id, {required bool completed}) async {
    try {
      final response = await _dio.patch(
        Endpoints.todoComplete(id),
        data: {'completed': completed},
      );
      return Todo.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> reorderSubtodos(int todoId, List<int> subtodoIds) async {
    try {
      await _dio.patch(
        Endpoints.todoReorderSubtodos(todoId),
        data: {'subtodo_ids': subtodoIds},
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Todo> linkTodoToEvent(int todoId, int? eventId) async {
    try {
      final response = await _dio.patch(
        Endpoints.todoLinkEvent(todoId),
        data: {'event_id': eventId},
      );
      return Todo.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<Proposal>> getProposals(int todoId) async {
    try {
      final response = await _dio.get(Endpoints.todoProposals(todoId));
      return (response.data as List)
          .map((e) => Proposal.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Proposal> createProposal(int todoId, Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(
        Endpoints.todoProposals(todoId),
        data: data,
      );
      return Proposal.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> respondToProposal(
    int proposalId, {
    required String response, // accepted|rejected
    DateTime? counterDate,
    String? message,
  }) async {
    try {
      final data = <String, dynamic>{
        'response': response,
        if (message != null) 'message': message,
        if (counterDate != null) 'counter_date': counterDate.toIso8601String(),
      };
      await _dio.post(Endpoints.proposalRespond(proposalId), data: data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<Proposal>> getPendingProposals() async {
    try {
      final response = await _dio.get(Endpoints.proposalsPending);
      return (response.data as List)
          .map((e) => Proposal.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Map<String, dynamic>> prioritizeTodos() async {
    try {
      final response = await _dio.post(Endpoints.aiPrioritizeTodos);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<int> applyTodoPriorities(List<Map<String, dynamic>> items) async {
    try {
      final response = await _dio.post(
        Endpoints.aiApplyTodoPriorities,
        data: {'items': items},
      );
      final data = response.data as Map<String, dynamic>;
      return data['updated'] as int? ?? 0;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<TodoAttachment> uploadTodoAttachment(int todoId, String filePath) async {
    return uploadTodoAttachmentData(
      todoId,
      filename: path.basename(filePath),
      filePath: filePath,
    );
  }

  Future<TodoAttachment> uploadTodoAttachmentData(
    int todoId, {
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
        Endpoints.todoAttachments(todoId),
        data: form,
      );
      return TodoAttachment.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> deleteTodoAttachment(int todoId, int attachmentId) async {
    try {
      await _dio.delete(Endpoints.todoAttachment(todoId, attachmentId));
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}

final todoRepositoryProvider = Provider<TodoRepository>((ref) {
  return TodoRepository(ref.watch(dioProvider));
});
