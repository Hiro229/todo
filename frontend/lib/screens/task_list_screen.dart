import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../services/api_service.dart';
import '../services/user_auth_service.dart';
import '../models/user.dart';
import 'task_form_screen.dart';
import 'profile_screen.dart';
import 'auth_screen.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  List<Task> _tasks = [];
  List<Category> _categories = [];
  bool _isLoading = true;
  String? _error;
  User? _currentUser;

  // フィルタリング状態
  String _searchQuery = '';
  Priority? _selectedPriority;
  Category? _selectedCategory;
  bool? _selectedCompletionStatus;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadCurrentUser();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = await UserAuthService.getCurrentUser();
      setState(() {
        _currentUser = user;
      });
    } catch (e) {
      // ユーザー情報の取得に失敗した場合はログイン画面に遷移
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const AuthScreen()),
          (route) => false,
        );
      }
    }
  }

  Future<void> _loadData() async {
    await Future.wait([_loadTasks(), _loadCategories()]);
  }

  Future<void> _loadTasks() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final tasks = await ApiService.getTasks(
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        categoryId: _selectedCategory?.id,
        priority: _selectedPriority,
        isCompleted: _selectedCompletionStatus,
      );
      setState(() {
        _tasks = tasks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await ApiService.getCategories();
      setState(() {
        _categories = categories;
      });
    } catch (e) {
      // エラーは無視して空のリストを使用
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _loadTasks();
  }

  void _onFilterChanged() {
    _loadTasks();
  }

  void _clearFilters() {
    setState(() {
      _searchQuery = '';
      _selectedPriority = null;
      _selectedCategory = null;
      _selectedCompletionStatus = null;
      _searchController.clear();
    });
    _loadTasks();
  }

  Future<void> _toggleTaskCompletion(Task task) async {
    try {
      final updatedTask = await ApiService.updateTask(
        task.id,
        TaskUpdate(isCompleted: !task.isCompleted),
      );

      setState(() {
        final index = _tasks.indexWhere((t) => t.id == task.id);
        if (index != -1) {
          _tasks[index] = updatedTask;
        }
      });
    } catch (e) {
      _showErrorDialog('タスクの更新に失敗しました: $e');
    }
  }

  Future<void> _deleteTask(Task task) async {
    final confirmed = await _showDeleteConfirmation(task);
    if (!confirmed) return;

    try {
      await ApiService.deleteTask(task.id);
      setState(() {
        _tasks.removeWhere((t) => t.id == task.id);
      });
    } catch (e) {
      _showErrorDialog('タスクの削除に失敗しました: $e');
    }
  }

  Future<bool> _showDeleteConfirmation(Task task) async {
    return await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('タスクを削除'),
                content: Text('「${task.title}」を削除しますか？'),
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
        ) ??
        false;
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('エラー'),
            content: Text(message),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK')),
            ],
          ),
    );
  }

  Future<void> _navigateToTaskForm([Task? task]) async {
    final result = await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => TaskFormScreen(task: task)));

    if (result == true) {
      _loadTasks();
    }
  }

  Future<void> _navigateToProfile() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const ProfileScreen()),
    );
    // プロフィール画面から戻ってきたらユーザー情報を再読み込み
    _loadCurrentUser();
  }

  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await UserAuthService.logout();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const AuthScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('HAKADORI'),
            if (_currentUser != null) ...[
              const Spacer(),
              Text(
                'Hello, ${_currentUser!.username}',
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(icon: const Icon(Icons.filter_list), onPressed: _showFilterDialog),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
          PopupMenuButton<String>(
            icon: _currentUser != null
                ? CircleAvatar(
                    radius: 16,
                    backgroundColor: Theme.of(context).primaryColor,
                    child: Text(
                      _currentUser!.username.substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                : const Icon(Icons.account_circle),
            onSelected: (value) {
              switch (value) {
                case 'profile':
                  _navigateToProfile();
                  break;
                case 'logout':
                  _logout();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person),
                    SizedBox(width: 8),
                    Text('Profile'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 8),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [_buildSearchBar(), _buildFilterChips(), Expanded(child: _buildBody())],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToTaskForm(),
        tooltip: 'タスクを追加',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('エラーが発生しました', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _error!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadTasks, child: const Text('再試行')),
          ],
        ),
      );
    }

    if (_tasks.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.task_alt, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('タスクがありません', style: TextStyle(fontSize: 18, color: Colors.grey)),
            SizedBox(height: 8),
            Text('右下の + ボタンでタスクを追加してください', style: TextStyle(fontSize: 14, color: Colors.grey)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        itemCount: _tasks.length,
        itemBuilder: (context, index) {
          final task = _tasks[index];
          return _buildTaskItem(task);
        },
      ),
    );
  }

  Widget _buildTaskItem(Task task) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Checkbox(value: task.isCompleted, onChanged: (_) => _toggleTaskCompletion(task)),
        title: Text(
          task.title,
          style: TextStyle(
            decoration: task.isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
            color: task.isCompleted ? Colors.grey : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (task.description != null && task.description!.isNotEmpty)
              Text(
                task.description!,
                style: TextStyle(color: task.isCompleted ? Colors.grey : null),
              ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.circle, color: _getPriorityColor(task.priority), size: 12),
                const SizedBox(width: 4),
                Text(task.priority.label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                if (task.category != null) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.category, size: 12, color: Colors.grey[600]),
                  const SizedBox(width: 2),
                  Text(
                    task.category!.name,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ],
            ),
            if (task.dueDate != null) ...[
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 12,
                    color: task.isOverdue ? Colors.red : Colors.grey[600],
                  ),
                  const SizedBox(width: 2),
                  Text(
                    DateFormat('MM/dd HH:mm').format(task.dueDate!),
                    style: TextStyle(
                      fontSize: 12,
                      color: task.isOverdue ? Colors.red : Colors.grey[600],
                      fontWeight: task.isOverdue ? FontWeight.bold : null,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 2),
            Text(
              '作成: ${DateFormat('yyyy/MM/dd HH:mm').format(task.createdAt)}',
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'edit':
                _navigateToTaskForm(task);
                break;
              case 'delete':
                _deleteTask(task);
                break;
            }
          },
          itemBuilder:
              (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: ListTile(leading: Icon(Icons.edit), title: Text('編集')),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: ListTile(leading: Icon(Icons.delete), title: Text('削除')),
                ),
              ],
        ),
        onTap: () => _navigateToTaskForm(task),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'タスクを検索...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon:
              _searchQuery.isNotEmpty
                  ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      _onSearchChanged('');
                    },
                  )
                  : null,
          border: const OutlineInputBorder(),
          filled: true,
          fillColor: Colors.grey[50],
        ),
        onChanged: _onSearchChanged,
      ),
    );
  }

  Widget _buildFilterChips() {
    final hasFilters =
        _selectedPriority != null || _selectedCategory != null || _selectedCompletionStatus != null;

    if (!hasFilters) return const SizedBox.shrink();

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                if (_selectedPriority != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text('優先度: ${_selectedPriority!.label}'),
                      onSelected: (selected) {},
                      onDeleted: () {
                        setState(() {
                          _selectedPriority = null;
                        });
                        _onFilterChanged();
                      },
                      avatar: Icon(
                        Icons.circle,
                        color: _getPriorityColor(_selectedPriority!),
                        size: 16,
                      ),
                    ),
                  ),
                if (_selectedCategory != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text('カテゴリ: ${_selectedCategory!.name}'),
                      onSelected: (selected) {},
                      onDeleted: () {
                        setState(() {
                          _selectedCategory = null;
                        });
                        _onFilterChanged();
                      },
                      avatar: const Icon(Icons.category, size: 16),
                    ),
                  ),
                if (_selectedCompletionStatus != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(_selectedCompletionStatus! ? '完了タスク' : '未完了タスク'),
                      onSelected: (selected) {},
                      onDeleted: () {
                        setState(() {
                          _selectedCompletionStatus = null;
                        });
                        _onFilterChanged();
                      },
                      avatar: Icon(
                        _selectedCompletionStatus!
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        size: 16,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          TextButton(onPressed: _clearFilters, child: const Text('クリア')),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('フィルター'),
            content: StatefulBuilder(
              builder:
                  (context, setDialogState) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<Priority?>(
                        value: _selectedPriority,
                        decoration: const InputDecoration(
                          labelText: '優先度',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem<Priority?>(value: null, child: Text('すべて')),
                          ...Priority.values.map(
                            (priority) => DropdownMenuItem(
                              value: priority,
                              child: Row(
                                children: [
                                  Icon(Icons.circle, color: _getPriorityColor(priority), size: 16),
                                  const SizedBox(width: 8),
                                  Text(priority.label),
                                ],
                              ),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setDialogState(() {
                            _selectedPriority = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<Category?>(
                        value: _selectedCategory,
                        decoration: const InputDecoration(
                          labelText: 'カテゴリ',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem<Category?>(value: null, child: Text('すべて')),
                          ..._categories.map(
                            (category) => DropdownMenuItem(
                              value: category,
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.category,
                                    color:
                                        category.color != null
                                            ? Color(
                                              int.parse(category.color!.substring(1), radix: 16) +
                                                  0xFF000000,
                                            )
                                            : Colors.grey,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(category.name),
                                ],
                              ),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setDialogState(() {
                            _selectedCategory = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<bool?>(
                        value: _selectedCompletionStatus,
                        decoration: const InputDecoration(
                          labelText: '完了状態',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem<bool?>(value: null, child: Text('すべて')),
                          DropdownMenuItem(
                            value: false,
                            child: Row(
                              children: [
                                Icon(Icons.radio_button_unchecked, size: 16),
                                SizedBox(width: 8),
                                Text('未完了'),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: true,
                            child: Row(
                              children: [
                                Icon(Icons.check_circle, size: 16),
                                SizedBox(width: 8),
                                Text('完了済み'),
                              ],
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setDialogState(() {
                            _selectedCompletionStatus = value;
                          });
                        },
                      ),
                    ],
                  ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  _clearFilters();
                  Navigator.of(context).pop();
                },
                child: const Text('クリア'),
              ),
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('キャンセル')),
              TextButton(
                onPressed: () {
                  setState(() {
                    // ダイアログの状態をメインの状態に反映
                  });
                  _onFilterChanged();
                  Navigator.of(context).pop();
                },
                child: const Text('適用'),
              ),
            ],
          ),
    );
  }

  Color _getPriorityColor(Priority priority) {
    switch (priority) {
      case Priority.high:
        return Colors.red;
      case Priority.medium:
        return Colors.orange;
      case Priority.low:
        return Colors.green;
    }
  }
}
