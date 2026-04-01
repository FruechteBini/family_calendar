import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/endpoints.dart';
import '../domain/family_member.dart';

class MemberRepository {
  final Dio _dio;

  MemberRepository(this._dio);

  Future<List<FamilyMember>> getMembers() async {
    try {
      final response = await _dio.get(Endpoints.familyMembers);
      return (response.data as List)
          .map((e) => FamilyMember.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<FamilyMember> createMember(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(Endpoints.familyMembers, data: data);
      return FamilyMember.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<FamilyMember> updateMember(int id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put(Endpoints.familyMember(id), data: data);
      return FamilyMember.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> deleteMember(int id) async {
    try {
      await _dio.delete(Endpoints.familyMember(id));
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}

final memberRepositoryProvider = Provider<MemberRepository>((ref) {
  return MemberRepository(ref.watch(dioProvider));
});
