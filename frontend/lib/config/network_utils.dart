import 'dart:io';

class NetworkUtils {
  // 開発用PCのIPアドレス候補リスト
  static const List<String> _devServerCandidates = [
    '192.168.10.173', // 現在のIPアドレス
    '192.168.10.175', // セカンダリIPアドレス
    '192.168.10.168', // 前回のIPアドレス
    '192.168.10.171',
    '192.168.1.100',
    '192.168.1.1',
    '10.0.0.1',
    'localhost',
  ];

  // 利用可能な開発用サーバーのIPアドレスを自動検出
  static Future<String?> findAvailableDevServer() async {
    for (final ip in _devServerCandidates) {
      try {
        final client = HttpClient();
        client.connectionTimeout = const Duration(seconds: 3);

        final request = await client.getUrl(Uri.parse('http://$ip:8000/health'));

        final response = await request.close();

        if (response.statusCode == 200) {
          client.close();
          return ip;
        }

        client.close();
      } catch (e) {
        // 接続失敗時は次のIPを試す
        continue;
      }
    }

    return null;
  }

  // 特定のIPアドレスでサーバーが利用可能かチェック
  static Future<bool> isServerAvailable(String ip) async {
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 3);

      final request = await client.getUrl(Uri.parse('http://$ip:8000/health'));

      final response = await request.close();
      client.close();

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
