import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../api/api_client.dart';

const _storage = FlutterSecureStorage();
const _familyAvatarPathKey = 'kalender_family_avatar_path';

class FamilyInfo {
  final int? id;
  final String name;

  const FamilyInfo({required this.name, this.id});

  factory FamilyInfo.fromJson(Map<String, dynamic> json) {
    return FamilyInfo(
      id: json['id'] is int ? (json['id'] as int) : null,
      name: (json['name'] as String?)?.trim().isNotEmpty == true
          ? (json['name'] as String).trim()
          : 'Familie',
    );
  }
}

final familyInfoProvider = FutureProvider<FamilyInfo?>((ref) async {
  try {
    final dio = ref.watch(dioProvider);
    final response = await dio.get('/api/auth/family');
    final data = response.data;
    if (data is Map<String, dynamic>) return FamilyInfo.fromJson(data);
    if (data is Map) {
      return FamilyInfo.fromJson(Map<String, dynamic>.from(data));
    }
    return null;
  } on ApiException {
    return null;
  } catch (_) {
    return null;
  }
});

final familyAvatarPathProvider =
    StateNotifierProvider<FamilyAvatarPathNotifier, AsyncValue<String?>>((ref) {
  return FamilyAvatarPathNotifier();
});

class FamilyAvatarPathNotifier extends StateNotifier<AsyncValue<String?>> {
  FamilyAvatarPathNotifier() : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    try {
      final path = await _storage.read(key: _familyAvatarPathKey);
      if (path == null || path.isEmpty) {
        state = const AsyncValue.data(null);
        return;
      }
      final f = File(path);
      state = AsyncValue.data(await f.exists() ? path : null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> setFromPickedFile(File pickedFile) async {
    state = const AsyncValue.loading();
    try {
      final dir = await getApplicationDocumentsDirectory();
      final destPath = p.join(dir.path, 'family_avatar.jpg');
      await pickedFile.copy(destPath);
      await _storage.write(key: _familyAvatarPathKey, value: destPath);
      state = AsyncValue.data(destPath);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> remove() async {
    state = const AsyncValue.loading();
    try {
      final path = await _storage.read(key: _familyAvatarPathKey);
      await _storage.delete(key: _familyAvatarPathKey);
      if (path != null && path.isNotEmpty) {
        try {
          final f = File(path);
          if (await f.exists()) await f.delete();
        } catch (_) {
          // best-effort delete
        }
      }
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

