import "package:flutter_riverpod/flutter_riverpod.dart";

import "app_env.dart";
import "env_store.dart";

final envStoreProvider = FutureProvider<EnvStore>((ref) async {
  return EnvStore.init();
});

final envControllerProvider =
    StateNotifierProvider<EnvController, AppEnvironment>((ref) {
  final storeAsync = ref.watch(envStoreProvider);
  return storeAsync.when(
    data: (store) => EnvController(store),
    loading: () => EnvController(null),
    error: (_, __) => EnvController(null),
  );
});

class EnvController extends StateNotifier<AppEnvironment> {
  EnvController(this._store) : super(AppEnvConfig.defaultEnv) {
    _load();
  }

  final EnvStore? _store;

  Future<void> _load() async {
    if (_store == null) return;
    state = _store!.readEnv();
  }

  Future<void> setEnv(AppEnvironment env) async {
    state = env;
    if (_store == null) return;
    await _store!.writeEnv(env);
  }
}
