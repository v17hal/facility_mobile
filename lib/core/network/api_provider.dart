import "package:flutter_riverpod/flutter_riverpod.dart";

import "../config/env_controller.dart";
import "../storage/secure_store.dart";
import "api_client.dart";

final secureStoreProvider = Provider<SecureStore>((ref) {
  return SecureStore.create();
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final env = ref.watch(envControllerProvider);
  final secureStore = ref.watch(secureStoreProvider);
  return ApiClient(env: env, secureStore: secureStore);
});
