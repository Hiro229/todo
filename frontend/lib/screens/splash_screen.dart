import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../config/app_config.dart';
import 'task_list_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String _statusMessage = 'Initializing...';

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      setState(() {
        _statusMessage = 'Authenticating...';
      });

      // 自動認証を実行
      final success = await AuthService.autoAuthenticate();

      if (success) {
        setState(() {
          _statusMessage = 'Authentication successful!';
        });

        // 短い遅延の後、メイン画面に遷移
        await Future.delayed(const Duration(milliseconds: 500));

        if (mounted) {
          Navigator.of(
            context,
          ).pushReplacement(MaterialPageRoute(builder: (context) => const TaskListScreen()));
        }
      } else {
        // 開発環境でサーバーが利用できない場合の処理
        if (AppConfig.environment == Environment.development) {
          setState(() {
            _statusMessage = 'Development server offline - Working offline';
          });

          // 開発環境ではオフラインモードで続行
          await Future.delayed(const Duration(milliseconds: 1000));

          if (mounted) {
            Navigator.of(
              context,
            ).pushReplacement(MaterialPageRoute(builder: (context) => const TaskListScreen()));
          }
        } else {
          setState(() {
            _statusMessage = 'Authentication failed';
          });
          _showError('Failed to authenticate. Please check your connection and try again.');
        }
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error occurred';
      });
      _showError('An error occurred during initialization: $e');
    }
  }

  void _showError(String message) {
    if (mounted) {
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('接続エラー'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(message),
                  const SizedBox(height: 16),
                  const Text('トラブルシューティング：', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('• WiFi接続を確認してください'),
                  const Text('• 開発用サーバーが起動していることを確認'),
                  const Text('• PCとデバイスが同じネットワークにいることを確認'),
                  const Text('• ファイアウォールの設定を確認'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('閉じる'),
                ),
                if (AppConfig.environment == Environment.development)
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      // 開発環境ではオフラインモードで続行
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (context) => const TaskListScreen()),
                      );
                    },
                    child: const Text('オフラインで続行'),
                  ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _initializeApp(); // 再試行
                  },
                  child: const Text('再試行'),
                ),
              ],
            ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.task_alt, size: 80, color: Theme.of(context).colorScheme.onPrimary),
            const SizedBox(height: 24),
            Text(
              'TODO App',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: Theme.of(context).colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 48),
            CircularProgressIndicator(color: Theme.of(context).colorScheme.onPrimary),
            const SizedBox(height: 16),
            Text(
              _statusMessage,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
