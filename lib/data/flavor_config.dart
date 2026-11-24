/// Which build of the app this is (store, flavor), set once at start-up.
abstract final class FlavorConfig {
  static late String _flavor;
  static late String _appStore;
  static late bool _checkUpdates;

  /// e.g. "Google Play"; empty for a plain build.
  static String get flavor => _flavor;

  /// The store the app came from, if any.
  static String get appStore => _appStore;

  /// Whether looking for updates is on unless the user changes it.
  static bool get shouldCheckForUpdatesByDefault => _checkUpdates;

  static void setup({
    String flavor = '',
    String appStore = '',
    bool shouldCheckForUpdatesByDefault = true,
  }) {
    _flavor = flavor;
    _appStore = appStore;
    _checkUpdates = shouldCheckForUpdatesByDefault;
  }

  /// From the `--dart-define`s FLAVOR, APP_STORE and UPDATE_CHECK.
  static void setupFromEnvironment() => setup(
    flavor: const String.fromEnvironment('FLAVOR'),
    appStore: const String.fromEnvironment('APP_STORE'),
    shouldCheckForUpdatesByDefault: const bool.fromEnvironment(
      'UPDATE_CHECK',
      defaultValue: false,
    ),
  );
}
