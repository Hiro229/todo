import 'dart:io';
import 'network_utils.dart';

enum Environment { development, staging, production }

class AppConfig {
  static Environment _environment = Environment.development;

  static Environment get environment => _environment;

  static void setEnvironment(Environment env) {
    _environment = env;
  }

  // API Base URL based on environment
  static String get apiBaseUrl {
    switch (_environment) {
      case Environment.development:
        return _getDevApiUrl();
      case Environment.staging:
        return 'https://todo-app-api-staging.onrender.com';
      case Environment.production:
        return 'https://todo-2ui9.onrender.com';
    }
  }

  // Development API URL with platform detection
  static String _getDevApiUrl() {
    // 環境変数から開発用サーバーのIPを取得
    const devServerHost = String.fromEnvironment('DEV_SERVER_HOST');

    if (devServerHost.isNotEmpty) {
      return 'http://$devServerHost:8000';
    }

    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000';
    } else if (Platform.isIOS) {
      // iOS実機の場合はデフォルトで動的検出を使用
      // 静的IPはフォールバック用として保持
      return 'http://192.168.10.178:8000';
    } else {
      return 'http://localhost:8000';
    }
  }

  // 動的に利用可能な開発用サーバーを検出
  static Future<String?> getAvailableDevApiUrl() async {
    // 環境変数から開発用サーバーのIPを取得
    const devServerHost = String.fromEnvironment('DEV_SERVER_HOST');

    if (devServerHost.isNotEmpty) {
      if (await NetworkUtils.isServerAvailable(devServerHost)) {
        return 'http://$devServerHost:8000';
      }
    }

    // iOS実機の場合は必ず動的検出を実行
    if (Platform.isIOS) {
      final availableIp = await NetworkUtils.findAvailableDevServer();
      if (availableIp != null) {
        return 'http://$availableIp:8000';
      }
    }

    // Android以外のプラットフォームでも動的検出を試行
    if (!Platform.isAndroid) {
      final availableIp = await NetworkUtils.findAvailableDevServer();
      if (availableIp != null) {
        return 'http://$availableIp:8000';
      }
    }

    // フォールバック: 静的設定を使用
    return _getDevApiUrl();
  }

  // App Name based on environment
  static String get appName {
    switch (_environment) {
      case Environment.development:
        return 'HAKADORI (Dev)';
      case Environment.staging:
        return 'HAKADORI (Staging)';
      case Environment.production:
        return 'HAKADORI';
    }
  }

  // Debug mode
  static bool get isDebug {
    switch (_environment) {
      case Environment.development:
        return true;
      case Environment.staging:
        return false;
      case Environment.production:
        return false;
    }
  }

  // Logging level
  static bool get enableLogging {
    switch (_environment) {
      case Environment.development:
        return true;
      case Environment.staging:
        return true;
      case Environment.production:
        return false;
    }
  }

  // Error reporting
  static bool get enableErrorReporting {
    switch (_environment) {
      case Environment.development:
        return false;
      case Environment.staging:
        return true;
      case Environment.production:
        return true;
    }
  }

  // Token refresh threshold (in seconds before expiry)
  static int get tokenRefreshThreshold {
    switch (_environment) {
      case Environment.development:
        return 3600; // 1 hour
      case Environment.staging:
        return 1800; // 30 minutes
      case Environment.production:
        return 3600; // 1 hour
    }
  }

  // API timeout configuration
  static Duration get apiTimeout {
    switch (_environment) {
      case Environment.development:
        return const Duration(seconds: 30);
      case Environment.staging:
        return const Duration(seconds: 15);
      case Environment.production:
        return const Duration(seconds: 10);
    }
  }

  // Initialize environment from compile-time constants
  static void initializeEnvironment() {
    const env = String.fromEnvironment('FLUTTER_ENV', defaultValue: 'development');

    switch (env.toLowerCase()) {
      case 'staging':
        _environment = Environment.staging;
        break;
      case 'production':
        _environment = Environment.production;
        break;
      default:
        _environment = Environment.development;
        break;
    }
  }
}
