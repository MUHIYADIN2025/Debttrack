// lib/config/app_config.dart
// Central configuration — change BASE_URL to your server address

class AppConfig {
  AppConfig._();

  // ── API ──────────────────────────────────────────────────────
  // Development: use your machine's local IP (not localhost) so
  // the Android emulator / physical device can reach it.
  // Example: 'http://192.168.1.42:3000/api'
  static const String baseUrl = 'http://10.0.2.2:3000/api'; // Android emulator default

  // Production: replace with your deployed server
  // static const String baseUrl = 'https://api.yourdebttrack.com/api';

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // ── App ──────────────────────────────────────────────────────
  static const String appName     = 'DebtTrack';
  static const String appVersion  = '1.0.0';
  static const String currency    = 'SOS';
  static const String currencySymbol = 'SOS';
  static const String locale      = 'so-SO';

  // ── Storage Keys ─────────────────────────────────────────────
  static const String keyAuthToken = 'auth_token';
  static const String keyAuthUser  = 'auth_user';
  static const String keyThemeMode = 'theme_mode';
  static const String keyLanguage  = 'language';

  // ── Pagination ───────────────────────────────────────────────
  static const int defaultPageSize = 20;

  // ── Colors ───────────────────────────────────────────────────
  static const int colorPrimary  = 0xFF4F8EF7;
  static const int colorSuccess  = 0xFF22C55E;
  static const int colorDanger   = 0xFFEF4444;
  static const int colorWarning  = 0xFFF59E0B;
  static const int colorBg       = 0xFF0F1117;
  static const int colorSurface  = 0xFF1E2230;
  static const int colorSurface2 = 0xFF252A3A;
}


// lib/config/app_routes.dart
// Named route definitions

class AppRoutes {
  AppRoutes._();

  static const String login          = '/login';
  static const String register       = '/register';
  static const String dashboard      = '/dashboard';
  static const String customers      = '/customers';
  static const String customerDetail = '/customers/detail';
  static const String addCustomer    = '/customers/add';
  static const String editCustomer   = '/customers/edit';
  static const String debts          = '/debts';
  static const String addDebt        = '/debts/add';
  static const String payments       = '/payments';
  static const String addPayment     = '/payments/add';
  static const String reports        = '/reports';
  static const String profile        = '/profile';
  static const String settings       = '/settings';
}
