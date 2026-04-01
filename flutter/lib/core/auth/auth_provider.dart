import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../api/api_client.dart';
import '../api/endpoints.dart';
import '../../features/auth/domain/user.dart';

const _storage = FlutterSecureStorage();
const _tokenKey = 'kalender_token';
const _serverUrlKey = 'kalender_server_url';

class AuthState {
  final String? token;
  final User? user;
  final bool isLoading;

  const AuthState({this.token, this.user, this.isLoading = false});

  bool get isAuthenticated => token != null && user != null;
  bool get hasFamilyId => user?.familyId != null;

  AuthState copyWith({String? token, User? user, bool? isLoading}) {
    return AuthState(
      token: token ?? this.token,
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class AuthStateNotifier extends StateNotifier<AuthState> {
  final Ref _ref;

  AuthStateNotifier(this._ref) : super(const AuthState(isLoading: true)) {
    _loadSavedAuth();
  }

  Future<void> _loadSavedAuth() async {
    final token = await _storage.read(key: _tokenKey);
    final serverUrl = await _storage.read(key: _serverUrlKey);
    if (serverUrl != null) {
      _ref.read(serverUrlProvider.notifier).state = serverUrl;
    }
    if (token != null) {
      state = state.copyWith(token: token, isLoading: true);
      try {
        final user = await _fetchCurrentUser(token);
        state = AuthState(token: token, user: user);
      } catch (_) {
        state = const AuthState();
        await _storage.delete(key: _tokenKey);
      }
    } else {
      state = const AuthState();
    }
  }

  Future<User> _fetchCurrentUser(String token) async {
    final serverUrl = _ref.read(serverUrlProvider);
    final dio = Dio(BaseOptions(
      baseUrl: serverUrl,
      headers: {'Authorization': 'Bearer $token'},
    ));
    final response = await dio.get(Endpoints.authMe);
    return User.fromJson(response.data);
  }

  Future<void> login(String username, String password) async {
    state = state.copyWith(isLoading: true);
    try {
      final serverUrl = _ref.read(serverUrlProvider);
      final dio = Dio(BaseOptions(baseUrl: serverUrl));
      final response = await dio.post(
        Endpoints.authLogin,
        data: FormData.fromMap({
          'username': username,
          'password': password,
        }),
        options: Options(contentType: 'application/x-www-form-urlencoded'),
      );
      final token = response.data['access_token'] as String;
      await _storage.write(key: _tokenKey, value: token);
      final user = await _fetchCurrentUser(token);
      state = AuthState(token: token, user: user);
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false);
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> register(String username, String password) async {
    state = state.copyWith(isLoading: true);
    try {
      final serverUrl = _ref.read(serverUrlProvider);
      final dio = Dio(BaseOptions(baseUrl: serverUrl));
      await dio.post(
        Endpoints.authRegister,
        data: {'username': username, 'password': password},
      );
      await login(username, password);
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false);
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> createFamily(String name) async {
    final dio = _ref.read(dioProvider);
    final response = await dio.post(Endpoints.authFamily, data: {'name': name});
    final user = state.user?.copyWith(familyId: response.data['id'] as int);
    state = state.copyWith(user: user);
  }

  Future<void> joinFamily(String inviteCode) async {
    final dio = _ref.read(dioProvider);
    final response = await dio.post(
      Endpoints.authFamilyJoin,
      data: {'invite_code': inviteCode},
    );
    final user = state.user?.copyWith(familyId: response.data['id'] as int);
    state = state.copyWith(user: user);
  }

  Future<void> linkMember(int memberId) async {
    final dio = _ref.read(dioProvider);
    await dio.patch(Endpoints.authLinkMember, data: {'member_id': memberId});
    final user = state.user?.copyWith(memberId: memberId);
    state = state.copyWith(user: user);
  }

  Future<void> setServerUrl(String url) async {
    String normalized = url.trimRight();
    if (normalized.endsWith('/')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }
    await _storage.write(key: _serverUrlKey, value: normalized);
    _ref.read(serverUrlProvider.notifier).state = normalized;
  }

  Future<void> refreshUser() async {
    if (state.token == null) return;
    try {
      final user = await _fetchCurrentUser(state.token!);
      state = state.copyWith(user: user);
    } catch (_) {}
  }

  Future<void> logout() async {
    await _storage.delete(key: _tokenKey);
    state = const AuthState();
  }
}

final authStateProvider =
    StateNotifierProvider<AuthStateNotifier, AuthState>((ref) {
  return AuthStateNotifier(ref);
});
