import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/endpoints.dart';
import '../domain/todo.dart';

class TodoRepository {
  final Dio _dio;

  TodoRepository(this._dio);

  Future<List<Todo>> getTodos({
    String? priority,
    int? memberId,
    bool? completed,
    int? categoryId,
  }) async {
    try {
      final params = <String, dynamic>{};
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
      return Todo.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> linkEvent(int todoId, int eventId) async {
    try {
      await _dio.patch(
        Endpoints.todoLinkEvent(todoId),
        data: {'event_id': eventId},
      );
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
    required String status,
    DateTime? counterDate,
    String? counterMessage,
  }) async {
    try {
      final data = <String, dynamic>{'status': status};
      if (counterDate != null) {
        data['counter_date'] = counterDate.toIso8601String();
      }
      if (counterMessage != null) data['counter_message'] = counterMessage;
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
}

final todoRepositoryProvider = Provider<TodoRepository>((ref) {
  return TodoRepository(ref.watch(dioProvider));
});
