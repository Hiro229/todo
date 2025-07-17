import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../config/app_config.dart';
import '../models/user.dart';

class UserAuthService {
  static String get apiUrl => AppConfig.apiBaseUrl;

  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device),
  );

  static const String _tokenKey = 'jwt_token';
  static const String _userKey = 'current_user';

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

  // 現在のユーザー情報を取得
  static Future<User?> getCurrentUser() async {
    try {
      final userJson = await _storage.read(key: _userKey);
      if (userJson != null) {
        return User.fromJson(json.decode(userJson));
      }
      return null;
    } catch (e) {
      if (AppConfig.enableLogging) print('Error reading user: $e');
      return null;
    }
  }

  // トークンとユーザー情報を保存
  static Future<void> _saveAuthData(String token, User user) async {
    try {
      await _storage.write(key: _tokenKey, value: token);
      await _storage.write(key: _userKey, value: json.encode(user.toJson()));
    } catch (e) {
      if (AppConfig.enableLogging) print('Error saving auth data: $e');
      throw Exception('Failed to save authentication data');
    }
  }

  // 認証情報をクリア
  static Future<void> clearAuth() async {
    try {
      await _storage.delete(key: _tokenKey);
      await _storage.delete(key: _userKey);
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

  // ユーザー登録
  static Future<AuthResult> register(UserRegistration userRegistration) async {
    try {
      final response = await http.post(
        Uri.parse('$apiUrl/auth/register'),
        headers: headers,
        body: json.encode(userRegistration.toJson()),
      );

      if (response.statusCode == 200) {
        final authResponse = AuthResponse.fromJson(json.decode(response.body));
        await _saveAuthData(authResponse.accessToken, authResponse.user);
        
        return AuthResult(
          success: true,
          user: authResponse.user,
          token: authResponse.accessToken,
          expiresIn: authResponse.expiresIn,
          message: authResponse.message,
        );
      } else {
        final error = json.decode(response.body);
        String errorMessage = 'Registration failed';
        
        if (error['detail'] != null) {
          if (error['detail'] is List) {
            // バリデーションエラーの場合（422エラー）
            final details = error['detail'] as List;
            if (details.isNotEmpty) {
              errorMessage = details.first['msg'] ?? errorMessage;
            }
          } else {
            errorMessage = error['detail'];
          }
        }
        
        return AuthResult(
          success: false,
          error: errorMessage,
        );
      }
    } catch (e) {
      return AuthResult(success: false, error: 'Network error: $e');
    }
  }

  // ユーザーログイン
  static Future<AuthResult> login(UserLogin userLogin) async {
    try {
      final response = await http.post(
        Uri.parse('$apiUrl/auth/login'),
        headers: headers,
        body: json.encode(userLogin.toJson()),
      );

      if (response.statusCode == 200) {
        final authResponse = AuthResponse.fromJson(json.decode(response.body));
        await _saveAuthData(authResponse.accessToken, authResponse.user);
        
        return AuthResult(
          success: true,
          user: authResponse.user,
          token: authResponse.accessToken,
          expiresIn: authResponse.expiresIn,
          message: authResponse.message,
        );
      } else {
        final error = json.decode(response.body);
        String errorMessage = 'Login failed';
        
        if (error['detail'] != null) {
          if (error['detail'] is List) {
            // バリデーションエラーの場合（422エラー）
            final details = error['detail'] as List;
            if (details.isNotEmpty) {
              errorMessage = details.first['msg'] ?? errorMessage;
            }
          } else {
            errorMessage = error['detail'];
          }
        }
        
        return AuthResult(
          success: false,
          error: errorMessage,
        );
      }
    } catch (e) {
      return AuthResult(success: false, error: 'Network error: $e');
    }
  }

  // ログアウト
  static Future<void> logout() async {
    await clearAuth();
  }

  // トークン検証とユーザー情報取得
  static Future<AuthStatusResult> verifyToken() async {
    try {
      final token = await getToken();
      if (token == null) {
        return AuthStatusResult(authenticated: false, error: 'No token found');
      }

      final response = await http.post(
        Uri.parse('$apiUrl/auth/verify-token'),
        headers: {...headers, 'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final user = User.fromJson(json.decode(response.body));
        await _storage.write(key: _userKey, value: json.encode(user.toJson()));
        
        return AuthStatusResult(
          authenticated: true,
          user: user,
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

  // プロフィール更新
  static Future<UserUpdateResult> updateProfile(UserUpdate userUpdate) async {
    try {
      final token = await getToken();
      if (token == null) {
        return UserUpdateResult(success: false, error: 'Not authenticated');
      }

      final response = await http.put(
        Uri.parse('$apiUrl/auth/me'),
        headers: {...headers, 'Authorization': 'Bearer $token'},
        body: json.encode(userUpdate.toJson()),
      );

      if (response.statusCode == 200) {
        final user = User.fromJson(json.decode(response.body));
        await _storage.write(key: _userKey, value: json.encode(user.toJson()));
        
        return UserUpdateResult(
          success: true,
          user: user,
        );
      } else {
        final error = json.decode(response.body);
        String errorMessage = 'Profile update failed';
        
        if (error['detail'] != null) {
          if (error['detail'] is List) {
            // バリデーションエラーの場合（422エラー）
            final details = error['detail'] as List;
            if (details.isNotEmpty) {
              errorMessage = details.first['msg'] ?? errorMessage;
            }
          } else {
            errorMessage = error['detail'];
          }
        }
        
        return UserUpdateResult(
          success: false,
          error: errorMessage,
        );
      }
    } catch (e) {
      return UserUpdateResult(success: false, error: 'Network error: $e');
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

  // ログイン状態をチェック
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    final user = await getCurrentUser();
    
    if (token == null || user == null) return false;
    
    return await isTokenValid();
  }

  // 自動ログイン確認 - アプリ起動時に呼び出す
  static Future<bool> autoLogin() async {
    try {
      if (AppConfig.enableLogging) print('AutoLogin: Checking authentication status');

      // 保存されたトークンとユーザー情報を確認
      if (await isLoggedIn()) {
        if (AppConfig.enableLogging) print('AutoLogin: Valid session found, verifying...');
        
        final status = await verifyToken();
        if (status.authenticated) {
          if (AppConfig.enableLogging) print('AutoLogin: Authentication verified successfully');
          return true;
        } else {
          if (AppConfig.enableLogging) print('AutoLogin: Token verification failed: ${status.error}');
          await clearAuth();
          return false;
        }
      } else {
        if (AppConfig.enableLogging) print('AutoLogin: No valid session found');
        return false;
      }
    } catch (e) {
      if (AppConfig.enableLogging) print('AutoLogin: Exception occurred: $e');
      await clearAuth();
      return false;
    }
  }

  // トークンの有効期限をチェックして必要に応じてエラーを投げる
  static Future<Map<String, String>> getValidatedAuthHeaders() async {
    if (!await isTokenValid()) {
      await clearAuth();
      throw Exception('Authentication expired - please login again');
    }

    return await getAuthHeaders();
  }
}

class AuthResult {
  final bool success;
  final User? user;
  final String? token;
  final int? expiresIn;
  final String? message;
  final String? error;

  AuthResult({
    required this.success,
    this.user,
    this.token,
    this.expiresIn,
    this.message,
    this.error,
  });
}

class AuthStatusResult {
  final bool authenticated;
  final User? user;
  final String? error;

  AuthStatusResult({
    required this.authenticated,
    this.user,
    this.error,
  });
}

class UserUpdateResult {
  final bool success;
  final User? user;
  final String? error;

  UserUpdateResult({
    required this.success,
    this.user,
    this.error,
  });
}