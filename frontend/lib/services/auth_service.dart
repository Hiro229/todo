import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../config/app_config.dart';
import '../config/network_utils.dart';

class AuthService {
  static String get apiUrl => AppConfig.apiBaseUrl;

  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device),
  );

  static const String _tokenKey = 'jwt_token';
  static const String _sessionIdKey = 'session_id';

  static const Map<String, String> headers = {'Content-Type': 'application/json'};

  // 現在保存されているトークンを取得
  static Future<String?> getToken() async {
    try {
      return await _storage.read(key: _tokenKey);
    } catch (e) {
      if (AppConfig.enableLogging) print('Error reading token: $e');
      return null;
    }
  }

  // セッションIDを取得
  static Future<String?> getSessionId() async {
    try {
      return await _storage.read(key: _sessionIdKey);
    } catch (e) {
      if (AppConfig.enableLogging) print('Error reading session ID: $e');
      return null;
    }
  }

  // トークンを保存
  static Future<void> _saveToken(String token) async {
    try {
      await _storage.write(key: _tokenKey, value: token);

      // JWTからセッションIDを抽出
      final payload = JwtDecoder.decode(token);
      final sessionId = payload['session_id'] as String?;
      if (sessionId != null) {
        await _storage.write(key: _sessionIdKey, value: sessionId);
      }
    } catch (e) {
      if (AppConfig.enableLogging) print('Error saving token: $e');
      throw Exception('Failed to save authentication token');
    }
  }

  // トークンとセッション情報をクリア
  static Future<void> clearAuth() async {
    try {
      await _storage.delete(key: _tokenKey);
      await _storage.delete(key: _sessionIdKey);
    } catch (e) {
      if (AppConfig.enableLogging) print('Error clearing auth: $e');
    }
  }

  // トークンの有効性をチェック
  static Future<bool> isTokenValid() async {
    try {
      final token = await getToken();
      if (token == null) return false;

      // JWTの有効期限をチェック
      return !JwtDecoder.isExpired(token);
    } catch (e) {
      if (AppConfig.enableLogging) print('Error checking token validity: $e');
      return false;
    }
  }

  // シンプル認証を実行
  static Future<AuthResult> authenticate() async {
    try {
      final response = await http.post(Uri.parse('$apiUrl/auth/simple'), headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final token = data['access_token'] as String;
        final expiresIn = data['expires_in'] as int;

        await _saveToken(token);

        return AuthResult(success: true, token: token, expiresIn: expiresIn);
      } else {
        return AuthResult(success: false, error: 'Authentication failed: ${response.statusCode}');
      }
    } catch (e) {
      return AuthResult(success: false, error: 'Network error: $e');
    }
  }

  // 認証状態を確認
  static Future<AuthStatusResult> verifyAuth() async {
    try {
      final token = await getToken();
      if (token == null) {
        return AuthStatusResult(authenticated: false, error: 'No token found');
      }

      final response = await http.get(
        Uri.parse('$apiUrl/auth/verify'),
        headers: {...headers, 'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return AuthStatusResult(
          authenticated: true,
          sessionId: data['session_id'],
          expiresAt: data['expires_at'],
          issuedAt: data['issued_at'],
        );
      } else {
        // トークンが無効な場合はクリア
        await clearAuth();
        return AuthStatusResult(authenticated: false, error: 'Token verification failed');
      }
    } catch (e) {
      return AuthStatusResult(authenticated: false, error: 'Network error: $e');
    }
  }

  // 認証ヘッダーを取得
  static Future<Map<String, String>> getAuthHeaders() async {
    final token = await getToken();
    if (token == null) {
      throw Exception('No authentication token available');
    }

    return {...headers, 'Authorization': 'Bearer $token'};
  }

  // トークンの自動更新をチェック
  static Future<bool> refreshTokenIfNeeded() async {
    try {
      final token = await getToken();
      if (token == null) return false;

      // トークンの有効期限を確認
      final payload = JwtDecoder.decode(token);
      final exp = payload['exp'] as int;
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      // 有効期限の設定された時間前になったら更新
      final refreshThreshold = AppConfig.tokenRefreshThreshold;

      if (exp - now < refreshThreshold) {
        // トークンを更新
        final result = await authenticate();
        return result.success;
      }

      return true;
    } catch (e) {
      // エラーが発生した場合は新しく認証
      final result = await authenticate();
      return result.success;
    }
  }

  // 自動認証 - アプリ起動時に呼び出す
  static Future<bool> autoAuthenticate() async {
    try {
      if (AppConfig.enableLogging) print('AutoAuthenticate: Starting authentication process');

      // 開発環境では利用可能なサーバーを動的に検出
      if (AppConfig.environment == Environment.development) {
        if (AppConfig.enableLogging) print('AutoAuthenticate: Attempting to find available dev server');
        final dynamicApiUrl = await AppConfig.getAvailableDevApiUrl();

        if (dynamicApiUrl != null) {
          if (AppConfig.enableLogging) print('AutoAuthenticate: API URL = $dynamicApiUrl');

          // 静的URLと動的URLが異なる場合のみ特別に処理
          if (dynamicApiUrl != apiUrl) {
            if (AppConfig.enableLogging) print('AutoAuthenticate: Using dynamically detected server');
            final result = await _authenticateWithUrl(dynamicApiUrl);
            if (result.success) {
              if (AppConfig.enableLogging) print('AutoAuthenticate: Authentication successful with dynamic URL');
              return true;
            } else {
              if (AppConfig.enableLogging) print('AutoAuthenticate: Dynamic URL authentication failed: ${result.error}');
            }
          }
        } else {
          if (AppConfig.enableLogging) print('AutoAuthenticate: No available dev server found');
          if (AppConfig.enableLogging) print('AutoAuthenticate: Development server appears to be offline');
          return false; // サーバーが見つからない場合は認証をスキップ
        }
      }

      if (AppConfig.enableLogging) print('AutoAuthenticate: Using configured API URL = $apiUrl');

      // 既存のトークンをチェック
      if (await isTokenValid()) {
        if (AppConfig.enableLogging) print('AutoAuthenticate: Valid token found, verifying...');
        final status = await verifyAuth();
        if (status.authenticated) {
          if (AppConfig.enableLogging) print('AutoAuthenticate: Token verified successfully');
          // トークンの更新が必要かチェック
          await refreshTokenIfNeeded();
          return true;
        } else {
          if (AppConfig.enableLogging) print('AutoAuthenticate: Token verification failed: ${status.error}');
        }
      } else {
        if (AppConfig.enableLogging) print('AutoAuthenticate: No valid token found');
      }

      // 既存のトークンが無効な場合は新しく認証
      if (AppConfig.enableLogging) print('AutoAuthenticate: Attempting new authentication');
      final result = await authenticate();
      if (result.success) {
        if (AppConfig.enableLogging) print('AutoAuthenticate: New authentication successful');
        return true;
      } else {
        if (AppConfig.enableLogging) print('AutoAuthenticate: New authentication failed: ${result.error}');

        // 開発環境でネットワークエラーの場合は詳細情報を表示
        if (AppConfig.environment == Environment.development &&
            result.error != null &&
            result.error!.contains('Network error')) {
          if (AppConfig.enableLogging) print('AutoAuthenticate: Development server connection failed');
          if (AppConfig.enableLogging) print('AutoAuthenticate: Please ensure the backend server is running');
        }

        return false;
      }
    } catch (e) {
      if (AppConfig.enableLogging) print('AutoAuthenticate: Exception occurred: $e');
      return false;
    }
  }

  // 指定されたURLで認証を試行
  static Future<AuthResult> _authenticateWithUrl(String baseUrl) async {
    try {
      final response = await http.post(Uri.parse('$baseUrl/auth/simple'), headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final token = data['access_token'] as String;
        final expiresIn = data['expires_in'] as int;

        await _saveToken(token);

        return AuthResult(success: true, token: token, expiresIn: expiresIn);
      } else {
        return AuthResult(success: false, error: 'Authentication failed: ${response.statusCode}');
      }
    } catch (e) {
      return AuthResult(success: false, error: 'Network error: $e');
    }
  }

  // API呼び出し前にトークンの有効性をチェックして必要に応じて更新
  static Future<Map<String, String>> getValidatedAuthHeaders() async {
    // トークンの更新が必要かチェック
    final isValid = await refreshTokenIfNeeded();
    if (!isValid) {
      throw Exception('Authentication failed - please restart the app');
    }

    return await getAuthHeaders();
  }
}

class AuthResult {
  final bool success;
  final String? token;
  final int? expiresIn;
  final String? error;

  AuthResult({required this.success, this.token, this.expiresIn, this.error});
}

class AuthStatusResult {
  final bool authenticated;
  final String? sessionId;
  final int? expiresAt;
  final int? issuedAt;
  final String? error;

  AuthStatusResult({
    required this.authenticated,
    this.sessionId,
    this.expiresAt,
    this.issuedAt,
    this.error,
  });
}
