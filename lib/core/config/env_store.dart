import "package:shared_preferences/shared_preferences.dart";

import "app_env.dart";

class EnvStore {
  EnvStore(this._prefs);

  static const _key = "app_env";
  final SharedPreferences _prefs;

  static Future<EnvStore> init() async {
    final prefs = await SharedPreferences.getInstance();
    return EnvStore(prefs);
  }

  AppEnvironment readEnv() {
    final value = _prefs.getString(_key);
    return _fromString(value) ?? AppEnvConfig.defaultEnv;
  }

  Future<void> writeEnv(AppEnvironment env) async {
    await _prefs.setString(_key, env.name);
  }

  AppEnvironment? _fromString(String? value) {
    if (value == null) return null;
    return AppEnvironment.values.where((e) => e.name == value).firstOrNull;
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
