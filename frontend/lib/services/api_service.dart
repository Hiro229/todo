import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/task.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:8000';
  
  // iOSシミュレータの場合はlocalhost、Android エミュレータの場合は10.0.2.2を使用
  static String get apiUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000';
    }
    return baseUrl;
  }

  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
  };

  // 全タスクを取得
  static Future<List<Task>> getTasks() async {
    try {
      final response = await http.get(
        Uri.parse('$apiUrl/api/tasks'),
        headers: headers,
      );

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
}