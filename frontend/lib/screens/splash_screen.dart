import 'package:flutter/material.dart';
import '../services/user_auth_service.dart';
import '../config/app_config.dart';
import 'task_list_screen.dart';
import 'auth_screen.dart';

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
        _statusMessage = 'Checking authentication...';
      });

      if (AppConfig.enableLogging) {
        print('SplashScreen: Starting initialization');
        print('SplashScreen: Environment = ${AppConfig.environment}');
        print('SplashScreen: API URL = ${AppConfig.apiBaseUrl}');
      }

      // 自動ログインを確認
      final isLoggedIn = await UserAuthService.autoLogin();

      if (AppConfig.enableLogging) {
        print('SplashScreen: AutoLogin result = $isLoggedIn');
      }

      if (isLoggedIn) {
        setState(() {
          _statusMessage = 'Welcome back!';
        });

        // 短い遅延の後、メイン画面に遷移
        await Future.delayed(const Duration(milliseconds: 500));

        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const TaskListScreen()),
          );
        }
      } else {
        setState(() {
          _statusMessage = 'Please login to continue';
        });

        // 短い遅延の後、認証画面に遷移
        await Future.delayed(const Duration(milliseconds: 500));

        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const AuthScreen()),
          );
        }
      }
    } catch (e) {
      if (AppConfig.enableLogging) {
        print('SplashScreen: Exception during initialization: $e');
      }
      setState(() {
        _statusMessage = 'Error occurred';
      });
      
      // エラーダイアログを表示するか、直接認証画面に遷移
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const AuthScreen()),
        );
      }
    }
  }

  void _showError(String message) {
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message),
              const SizedBox(height: 16),
              const Text('Troubleshooting:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('• Check your internet connection'),
              const Text('• Ensure the server is running'),
              const Text('• Check network settings'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // エラー時は認証画面に遷移
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const AuthScreen()),
                );
              },
              child: const Text('Go to Login'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _initializeApp(); // 再試行
              },
              child: const Text('Retry'),
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
              AppConfig.appName,
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
