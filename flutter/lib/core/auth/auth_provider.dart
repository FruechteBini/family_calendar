import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../api/api_client.dart' show serverUrlProvider, ApiException;
import '../api/endpoints.dart';
import '../../features/auth/domain/user.dart';
import 'google_auth_service.dart';

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
  final GoogleAuthService _googleAuth = GoogleAuthService();

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

  Dio _authedDio() {
    final serverUrl = _ref.read(serverUrlProvider);
    return Dio(BaseOptions(
      baseUrl: serverUrl,
      headers: {'Authorization': 'Bearer ${state.token}'},
    ));
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
        data: {
          'username': username,
          'password': password,
        },
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

  Future<void> loginWithGoogle() async {
    state = state.copyWith(isLoading: true);
    try {
      final payload = await _googleAuth.signInBasic();
      final serverUrl = _ref.read(serverUrlProvider);
      final dio = Dio(BaseOptions(baseUrl: serverUrl));
      final response = await dio.post(
        Endpoints.authGoogle,
        data: {
          'id_token': payload.idToken,
          'server_auth_code': payload.serverAuthCode,
        },
      );
      final token = response.data['access_token'] as String;
      await _storage.write(key: _tokenKey, value: token);
      final user = await _fetchCurrentUser(token);
      state = AuthState(token: token, user: user);
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false);
      throw ApiException.fromDioError(e);
    } catch (e) {
      state = state.copyWith(isLoading: false);
      final msg = e is Exception ? e.toString().replaceFirst('Exception: ', '') : '$e';
      throw ApiException(msg);
    }
  }

  Future<void> linkGoogle() async {
    final dio = _authedDio();
    try {
      final payload = await _googleAuth.signInBasic();
      await dio.post(
        Endpoints.authGoogleLink,
        data: {
          'id_token': payload.idToken,
          'server_auth_code': payload.serverAuthCode,
        },
      );
      await refreshUser();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> unlinkGoogle() async {
    final dio = _authedDio();
    try {
      await dio.post(Endpoints.authGoogleUnlink);
      await refreshUser();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> grantGoogleSyncScopes({
    required bool calendar,
    required bool tasks,
  }) async {
    final dio = _authedDio();
    try {
      final payload = await _googleAuth.requestSyncScopes(
        calendar: calendar,
        tasks: tasks,
      );
      await dio.post(
        Endpoints.authGoogleGrantSync,
        data: {
          'server_auth_code': payload.serverAuthCode,
          'calendar': calendar,
          'tasks': tasks,
        },
      );
      await refreshUser();
    } on DioException catch (e) {
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
    final dio = _authedDio();
    final response = await dio.post(Endpoints.authFamily, data: {'name': name});
    final user = state.user?.copyWith(familyId: response.data['id'] as int);
    state = state.copyWith(user: user);
  }

  Future<void> joinFamily(String inviteCode) async {
    final dio = _authedDio();
    final response = await dio.post(
      Endpoints.authFamilyJoin,
      data: {'invite_code': inviteCode},
    );
    final user = state.user?.copyWith(familyId: response.data['id'] as int);
    state = state.copyWith(user: user);
  }

  Future<void> linkMember(int memberId) async {
    final dio = _authedDio();
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
