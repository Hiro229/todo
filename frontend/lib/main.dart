import 'package:flutter/material.dart';
import 'config/app_config.dart';
import 'screens/splash_screen.dart';

void main() {
  // 環境設定を初期化
  AppConfig.initializeEnvironment();
  
  // 本番環境に設定
  AppConfig.setEnvironment(Environment.production);
  
  runApp(const TodoApp());
}

class TodoApp extends StatelessWidget {
  const TodoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: AppConfig.isDebug,
      home: const SplashScreen(),
    );
  }
}
