import 'dart:io';
import 'dart:async';

class NetworkUtils {
  // 開発用PCのIPアドレス候補リスト（実機接続に適したIPを優先）
  static const List<String> _devServerCandidates = [
    '192.168.10.178', // 現在のIPアドレス
    '192.168.10.173', // 現在のIPアドレス
    '192.168.10.175', // セカンダリIPアドレス
    '192.168.10.168', // 前回のIPアドレス
    '192.168.10.171',
    '192.168.1.100',
    '192.168.1.1',
    '192.168.0.1',
    '10.0.0.1',
    '127.0.0.1',
    'localhost',
  ];

  // 利用可能な開発用サーバーのIPアドレスを自動検出
  static Future<String?> findAvailableDevServer() async {
    try {
      // 並列でサーバーをチェック（効率化）
      final futures = _devServerCandidates.map((ip) => _checkServer(ip));

      // 最初に成功したサーバーを返す
      for (final future in futures) {
        final result = await future;
        if (result != null) {
          return result;
        }
      }
    } catch (e) {
      print('Error during server detection: $e');
    }

    return null;
  }

  // 特定のIPアドレスでサーバーが利用可能かチェック
  static Future<bool> isServerAvailable(String ip) async {
    final result = await _checkServer(ip);
    return result != null;
  }

  // 内部メソッド：サーバーの可用性をチェック
  static Future<String?> _checkServer(String ip) async {
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 2);

      final request = await client.getUrl(Uri.parse('http://$ip:8000/health'));
      request.headers.add('Connection', 'close');

      final response = await request.close();
      await response.drain(); // レスポンスボディを消費

      final success = response.statusCode == 200;
      client.close();

      return success ? ip : null;
    } catch (e) {
      // 接続失敗時はnullを返す
      return null;
    }
  }

  // デバッグ用：全てのサーバー候補の状態を確認
  static Future<Map<String, bool>> checkAllServers() async {
    final results = <String, bool>{};

    for (final ip in _devServerCandidates) {
      results[ip] = await isServerAvailable(ip);
    }

    return results;
  }
}
