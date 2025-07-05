import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/task.dart';
import 'auth_service.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:8000';
  
  // iOSシミュレータの場合はlocalhost、Android エミュレータの場合は10.0.2.2を使用
  static String get apiUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000';
    }
    return baseUrl;
  }

  static Future<Map<String, String>> _getHeaders() async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    
    final apiKey = await AuthService.getApiKey();
    if (apiKey != null && apiKey.isNotEmpty) {
      headers['X-API-Key'] = apiKey;
    }
    
    return headers;
  }

  // 全タスクを取得（フィルタリング・検索対応）
  static Future<List<Task>> getTasks({
    String? search,
    int? categoryId,
    Priority? priority,
    bool? isCompleted,
  }) async {
    try {
      final Map<String, String> queryParams = {};
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (categoryId != null) {
        queryParams['category_id'] = categoryId.toString();
      }
      if (priority != null) {
        queryParams['priority'] = priority.value.toString();
      }
      if (isCompleted != null) {
        queryParams['is_completed'] = isCompleted.toString();
      }

      final uri = Uri.parse('$apiUrl/api/tasks').replace(queryParameters: queryParams);
      final headers = await _getHeaders();
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        return jsonData.map((json) => Task.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load tasks: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // 新規タスクを作成
  static Future<Task> createTask(TaskCreate taskCreate) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$apiUrl/api/tasks'),
        headers: headers,
        body: json.encode(taskCreate.toJson()),
      );

      if (response.statusCode == 200) {
        return Task.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to create task: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // 特定のタスクを取得
  static Future<Task> getTask(int id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$apiUrl/api/tasks/$id'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return Task.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to load task: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // タスクを更新
  static Future<Task> updateTask(int id, TaskUpdate taskUpdate) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$apiUrl/api/tasks/$id'),
        headers: headers,
        body: json.encode(taskUpdate.toJson()),
      );

      if (response.statusCode == 200) {
        return Task.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to update task: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // タスクを削除
  static Future<bool> deleteTask(int id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$apiUrl/api/tasks/$id'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Failed to delete task: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // カテゴリ関連のAPI
  static Future<List<Category>> getCategories() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$apiUrl/api/categories'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        return jsonData.map((json) => Category.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load categories: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<Category> createCategory(CategoryCreate categoryCreate) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$apiUrl/api/categories'),
        headers: headers,
        body: json.encode(categoryCreate.toJson()),
      );

      if (response.statusCode == 200) {
        return Category.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to create category: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<bool> deleteCategory(int id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$apiUrl/api/categories/$id'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Failed to delete category: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // API Key management
  static Future<String> createApiKey(String name) async {
    try {
      final response = await http.post(
        Uri.parse('$apiUrl/api/auth/keys'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'name': name}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['key'];
      } else {
        throw Exception('Failed to create API key: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}