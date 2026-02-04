import "package:flutter_riverpod/flutter_riverpod.dart";

import "package:dio/dio.dart";
import "package:flutter/foundation.dart";

import "../network/api_client.dart";
import "../network/api_provider.dart";
import "../network/endpoints.dart";
import "../storage/secure_store.dart";
import "../storage/storage_keys.dart";

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  final api = ref.watch(apiClientProvider);
  final store = ref.watch(secureStoreProvider);
  return AuthController(api, store);
});

class AuthState {
  const AuthState({
    required this.isAuthenticated,
    this.isLoading = false,
    this.errorMessage,
  });

  final bool isAuthenticated;
  final bool isLoading;
  final String? errorMessage;

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._api, this._store)
      : super(const AuthState(isAuthenticated: false)) {
    _load();
  }

  final ApiClient _api;
  final SecureStore _store;

  Future<void> _load() async {
    final token = await _store.read(StorageKeys.apiToken);
    if (!mounted) return;
    state = state.copyWith(isAuthenticated: token != null && token.isNotEmpty);
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      debugPrint("Login started for $email");
      final payload = {
        "email": email,
        "password": password,
        "device_type": "WEB",
        "device_token": "",
      };
      final response = await _api.dio.post(Endpoints.login, data: payload);
      debugPrint("Login response status: ${response.statusCode}");
      debugPrint("Login response data: ${response.data}");

      final raw = response.data;
      Map<String, dynamic>? data;
      if (raw is Map<String, dynamic>) {
        final inner = raw["data"];
        data = inner is Map<String, dynamic> ? inner : raw;
      }

      final token = data?["token"] as String?;
      final agaliaId = data?["agalia_id"]?.toString();
      final success = token != null || (raw is Map && raw["success"] == true);
      if (!success) {
        debugPrint("Login failed: no token in response");
        state = state.copyWith(
          isLoading: false,
          errorMessage: "Login failed.",
        );
        return false;
      }
      if (token != null && token.isNotEmpty) {
        await _store.write(StorageKeys.apiToken, token);
      }
      if (agaliaId != null) {
        await _store.write(StorageKeys.agaliaId, agaliaId);
      }
      debugPrint("Login success");
      state = state.copyWith(isAuthenticated: true, isLoading: false);
      return true;
    } catch (e) {
      String message = "Incorrect email or password.";
      if (e is DioException) {
        debugPrint("Login error: ${e.response?.statusCode} ${e.message}");
        debugPrint("Login error data: ${e.response?.data}");
        if (e.type == DioExceptionType.connectionError ||
            e.type == DioExceptionType.connectionTimeout) {
          message = "Network error. Check your internet or API host.";
        }
        final err = e.response?.data;
        if (err is Map && err["error"] is Map) {
          final msg = err["error"]["message"];
          if (msg is List && msg.isNotEmpty) {
            message = msg.first.toString();
          } else if (msg != null) {
            message = msg.toString();
          }
        }
      }
      debugPrint("Login failed: $message");
      state = state.copyWith(
        isLoading: false,
        errorMessage: message,
      );
      return false;
    }
  }

  Future<bool> requestPasswordReset(String email) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final payload = {"email": email};
      final response = await _api.dio.patch(Endpoints.forgotPassword, data: payload);
      final success = response.data?["success"] == true;
      state = state.copyWith(isLoading: false);
      return success;
    } catch (e) {
      state = state.copyWith(isLoading: false);
      return false;
    }
  }

  Future<bool> setPassword({
    required String uid,
    required String token,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final payload = {"password": password, "token": token, "uidb64": uid};
      final response = await _api.dio.patch(Endpoints.resetPassword, data: payload);
      final success = response.data?["success"] == true;
      state = state.copyWith(isLoading: false);
      return success;
    } catch (e) {
      state = state.copyWith(isLoading: false);
      return false;
    }
  }

  Future<void> logout() async {
    await _store.delete(StorageKeys.apiToken);
    state = state.copyWith(isAuthenticated: false);
  }
}
