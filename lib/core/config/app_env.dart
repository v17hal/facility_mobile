enum AppEnvironment { dev, devsc, qa, stage, prod }

class AppEnvConfig {
  AppEnvConfig._();

  static const AppEnvironment defaultEnv = AppEnvironment.dev;

  static const Map<AppEnvironment, String> baseUrls = {
    AppEnvironment.dev: "https://apollo.dev.goagalia.com/",
    AppEnvironment.devsc: "https://apollo987.devsc.goagalia.com/",
    AppEnvironment.qa: "https://apollo987.qa.goagalia.com/",
    AppEnvironment.stage: "https://apollo.stage.goagalia.com/",
    AppEnvironment.prod: "https://apollo.goagalia.com/",
  };

  static String apiBaseUrl(AppEnvironment env) {
    final base = baseUrls[env] ?? baseUrls[defaultEnv]!;
    return "${_ensureTrailingSlash(base)}api/v1/";
  }

  static String _ensureTrailingSlash(String value) {
    if (value.endsWith("/")) {
      return value;
    }
    return "$value/";
  }
}
