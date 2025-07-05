import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class ApiKeyScreen extends StatefulWidget {
  const ApiKeyScreen({super.key});

  @override
  State<ApiKeyScreen> createState() => _ApiKeyScreenState();
}

class _ApiKeyScreenState extends State<ApiKeyScreen> {
  final _nameController = TextEditingController();
  String? _currentApiKey;
  bool _isLoading = false;
  bool _hasApiKey = false;

  @override
  void initState() {
    super.initState();
    _checkApiKey();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _checkApiKey() async {
    final hasKey = await AuthService.hasApiKey();
    final apiKey = await AuthService.getApiKey();
    setState(() {
      _hasApiKey = hasKey;
      _currentApiKey = apiKey;
    });
  }

  Future<void> _createApiKey() async {
    if (_nameController.text.trim().isEmpty) {
      _showErrorDialog('API キー名を入力してください');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final apiKey = await ApiService.createApiKey(_nameController.text.trim());
      await AuthService.saveApiKey(apiKey);
      
      if (mounted) {
        await _showApiKeyDialog(apiKey);
        _nameController.clear();
        _checkApiKey();
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('API キーの作成に失敗しました: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _removeApiKey() async {
    final confirmed = await _showConfirmDialog(
      'API キーを削除',
      'APIキーを削除しますか？\n削除後は認証が無効になります。',
    );
    
    if (confirmed) {
      await AuthService.removeApiKey();
      _checkApiKey();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('API キーが削除されました')),
        );
      }
    }
  }

  Future<void> _showApiKeyDialog(String apiKey) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('API キーが作成されました'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '以下のAPI キーが生成されました。このキーは再表示されないため、安全な場所に保存してください。',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: SelectableText(
                apiKey,
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: apiKey));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('API キーがクリップボードにコピーされました')),
                      );
                    },
                    icon: const Icon(Icons.copy),
                    label: const Text('コピー'),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  Future<bool> _showConfirmDialog(String title, String content) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('削除'),
          ),
        ],
      ),
    ) ?? false;
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('エラー'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('API キー管理'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'API キーについて',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'API キーは、アプリとサーバー間の通信を認証するために使用されます。'
                      'API キーを設定することで、よりセキュアな通信が可能になります。',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (_hasApiKey) ...[
              Card(
                color: Colors.green[50],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green[700]),
                          const SizedBox(width: 8),
                          Text(
                            'API キーが設定されています',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_currentApiKey != null)
                        Text(
                          'キー: ${_currentApiKey!.substring(0, 8)}...',
                          style: const TextStyle(fontFamily: 'monospace'),
                        ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _removeApiKey,
                        icon: const Icon(Icons.delete),
                        label: const Text('API キーを削除'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              Card(
                color: Colors.orange[50],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.warning, color: Colors.orange[700]),
                          const SizedBox(width: 8),
                          Text(
                            'API キーが設定されていません',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text('現在は認証なしでAPIにアクセスしています。'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                '新しいAPI キーを作成',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'API キー名',
                  hintText: '例: My TODO App Key',
                  border: OutlineInputBorder(),
                ),
                enabled: !_isLoading,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _createApiKey,
                icon: _isLoading 
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add),
                label: Text(_isLoading ? '作成中...' : 'API キーを作成'),
              ),
            ],
            const Spacer(),
            const Card(
              color: Colors.blue,
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          '注意事項',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      '• API キーは一度しか表示されません\n'
                      '• API キーは安全な場所に保存してください\n'
                      '• API キーが漏洩した場合は、すぐに削除して新しいキーを作成してください',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}