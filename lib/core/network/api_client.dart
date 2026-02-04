import "package:dio/dio.dart";

import "../config/app_env.dart";
import "../storage/secure_store.dart";
import "../storage/storage_keys.dart";

class ApiClient {
  ApiClient({
    required AppEnvironment env,
    required SecureStore secureStore,
  })  : _secureStore = secureStore,
        _dio = Dio(
          BaseOptions(
            baseUrl: AppEnvConfig.apiBaseUrl(env),
            listFormat: ListFormat.multiCompatible,
          ),
        ) {
    _dio.interceptors.add(
      QueuedInterceptorsWrapper(
        onRequest: (options, handler) async {
          options.path = dedupeUrlSlashes(options.path);
          final token = await _secureStore.read(StorageKeys.apiToken);
          final facilityId = await _secureStore.read(StorageKeys.facilityId);
          if (token != null && token.isNotEmpty) {
            options.headers["Authorization"] = "Bearer $token";
          }
          if (facilityId != null && facilityId.isNotEmpty && facilityId != "null") {
            options.headers["facility-id"] = facilityId;
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            await _secureStore.delete(StorageKeys.apiToken);
          }
          handler.next(error);
        },
      ),
    );
  }

  final Dio _dio;
  final SecureStore _secureStore;

  Dio get dio => _dio;
}

String dedupeUrlSlashes(String path) {
  final parts = path.split("?");
  final base = parts.first;
  final query = parts.length > 1 ? parts.sublist(1).join("?") : null;
  final normalized = base.replaceAllMapped(
    RegExp(r"([^:]/)/+"),
    (m) => m.group(1)!,
  );
  return query == null ? normalized : "$normalized?$query";
}
