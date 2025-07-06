import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class AuthService {
  static const String baseUrl = 'http://localhost:8000';
  
  static String get apiUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000';
    }
    return baseUrl;
  }

  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  static const String _tokenKey = 'jwt_token';
  static const String _sessionIdKey = 'session_id';

  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
  };

  // 現在保存されているトークンを取得
  static Future<String?> getToken() async {
    try {
      return await _storage.read(key: _tokenKey);
    } catch (e) {
      print('Error reading token: $e');
      return null;
    }
  }

  // セッションIDを取得
  static Future<String?> getSessionId() async {
    try {
      return await _storage.read(key: _sessionIdKey);
    } catch (e) {
      print('Error reading session ID: $e');
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
      print('Error saving token: $e');
      throw Exception('Failed to save authentication token');
    }
  }

  // トークンとセッション情報をクリア
  static Future<void> clearAuth() async {
    try {
      await _storage.delete(key: _tokenKey);
      await _storage.delete(key: _sessionIdKey);
    } catch (e) {
      print('Error clearing auth: $e');
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
      print('Error checking token validity: $e');
      return false;
    }
  }

  // シンプル認証を実行
  static Future<AuthResult> authenticate() async {
    try {
      final response = await http.post(
        Uri.parse('$apiUrl/auth/simple'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final token = data['access_token'] as String;
        final expiresIn = data['expires_in'] as int;

        await _saveToken(token);

        return AuthResult(
          success: true,
          token: token,
          expiresIn: expiresIn,
        );
      } else {
        return AuthResult(
          success: false,
          error: 'Authentication failed: ${response.statusCode}',
        );
      }
    } catch (e) {
      return AuthResult(
        success: false,
        error: 'Network error: $e',
      );
    }
  }

  // 認証状態を確認
  static Future<AuthStatusResult> verifyAuth() async {
    try {
      final token = await getToken();
      if (token == null) {
        return AuthStatusResult(
          authenticated: false,
          error: 'No token found',
        );
      }

      final response = await http.get(
        Uri.parse('$apiUrl/auth/verify'),
        headers: {
          ...headers,
          'Authorization': 'Bearer $token',
        },
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
        return AuthStatusResult(
          authenticated: false,
          error: 'Token verification failed',
        );
      }
    } catch (e) {
      return AuthStatusResult(
        authenticated: false,
        error: 'Network error: $e',
      );
    }
  }

  // 認証ヘッダーを取得
  static Future<Map<String, String>> getAuthHeaders() async {
    final token = await getToken();
    if (token == null) {
      throw Exception('No authentication token available');
    }

    return {
      ...headers,
      'Authorization': 'Bearer $token',
    };
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
      
      // 有効期限の1時間前になったら更新
      const refreshThreshold = 3600; // 1時間（秒）
      
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
      // 既存のトークンをチェック
      if (await isTokenValid()) {
        final status = await verifyAuth();
        if (status.authenticated) {
          // トークンの更新が必要かチェック
          await refreshTokenIfNeeded();
          return true;
        }
      }

      // 既存のトークンが無効な場合は新しく認証
      final result = await authenticate();
      return result.success;
    } catch (e) {
      // エラーログは本番環境では適切なログフレームワークを使用すべき
      return false;
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

  AuthResult({
    required this.success,
    this.token,
    this.expiresIn,
    this.error,
  });
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