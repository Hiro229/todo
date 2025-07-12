import 'package:flutter/material.dart';
import '../models/task.dart';
import '../services/api_service.dart';

class TaskFormScreen extends StatefulWidget {
  final Task? task;

  const TaskFormScreen({super.key, this.task});

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  Priority _selectedPriority = Priority.medium;
  DateTime? _selectedDueDate;
  Category? _selectedCategory;
  List<Category> _categories = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.task != null) {
      _titleController.text = widget.task!.title;
      _descriptionController.text = widget.task!.description ?? '';
      _selectedPriority = widget.task!.priority;
      _selectedDueDate = widget.task!.dueDate;
      // カテゴリは_loadCategories()完了後に設定
    }
    _loadCategories();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await ApiService.getCategories();
      setState(() {
        _categories = categories;
        // 編集時：タスクのカテゴリIDに基づいて正しいインスタンスを設定
        if (widget.task != null && widget.task!.category != null) {
          try {
            _selectedCategory = _categories.firstWhere(
              (cat) => cat.id == widget.task!.category!.id,
            );
          } catch (e) {
            // カテゴリが見つからない場合はnullに設定
            _selectedCategory = null;
          }
        }
      });
    } catch (e) {
      // エラーは無視して空のリストを使用
    }
  }

  Future<void> _selectDueDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDueDate ?? DateTime.now()),
      );
      if (time != null) {
        setState(() {
          _selectedDueDate = DateTime(date.year, date.month, date.day, time.hour, time.minute);
        });
      }
    }
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (widget.task == null) {
        // 新規作成
        await ApiService.createTask(
          TaskCreate(
            title: _titleController.text.trim(),
            description:
                _descriptionController.text.trim().isEmpty
                    ? null
                    : _descriptionController.text.trim(),
            priority: _selectedPriority,
            dueDate: _selectedDueDate,
            categoryId: _selectedCategory?.id,
          ),
        );
      } else {
        // 更新
        await ApiService.updateTask(
          widget.task!.id,
          TaskUpdate(
            title: _titleController.text.trim(),
            description:
                _descriptionController.text.trim().isEmpty
                    ? null
                    : _descriptionController.text.trim(),
            priority: _selectedPriority,
            dueDate: _selectedDueDate,
            categoryId: _selectedCategory?.id,
          ),
        );
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('タスクの保存に失敗しました: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.task == null ? 'タスクを追加' : 'タスクを編集'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (_isLoading)
            const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(icon: const Icon(Icons.save), onPressed: _saveTask),
        ],
      ),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'タイトル',
                    hintText: 'タスクのタイトルを入力',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'タイトルは必須です';
                    }
                    if (value.trim().length > 255) {
                      return 'タイトルは255文字以内で入力してください';
                    }
                    return null;
                  },
                  maxLength: 255,
                  enabled: !_isLoading,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: '説明（オプション）',
                    hintText: 'タスクの説明を入力',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 4,
                  enabled: !_isLoading,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<Priority>(
                  value: _selectedPriority,
                  decoration: const InputDecoration(labelText: '優先度', border: OutlineInputBorder()),
                  items:
                      Priority.values.map((priority) {
                        return DropdownMenuItem(
                          value: priority,
                          child: Row(
                            children: [
                              Icon(Icons.circle, color: _getPriorityColor(priority), size: 16),
                              const SizedBox(width: 8),
                              Text(priority.label),
                            ],
                          ),
                        );
                      }).toList(),
                  onChanged:
                      _isLoading
                          ? null
                          : (priority) {
                            setState(() {
                              _selectedPriority = priority!;
                            });
                          },
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: _isLoading ? null : _selectDueDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: '期限',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      _selectedDueDate != null
                          ? '${_selectedDueDate!.year}/${_selectedDueDate!.month}/${_selectedDueDate!.day} ${_selectedDueDate!.hour}:${_selectedDueDate!.minute.toString().padLeft(2, '0')}'
                          : '期限を設定',
                      style: TextStyle(
                        color:
                            _selectedDueDate != null
                                ? Theme.of(context).textTheme.bodyLarge?.color
                                : Theme.of(context).hintColor,
                      ),
                    ),
                  ),
                ),
                if (_selectedDueDate != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Spacer(),
                      TextButton(
                        onPressed:
                            _isLoading
                                ? null
                                : () {
                                  setState(() {
                                    _selectedDueDate = null;
                                  });
                                },
                        child: const Text('期限をクリア'),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                DropdownButtonFormField<Category?>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'カテゴリ',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<Category?>(value: null, child: Text('カテゴリなし')),
                    ..._categories.map(
                      (category) => DropdownMenuItem(
                        value: category,
                        child: Row(
                          children: [
                            if (category.color != null)
                              Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: Color(
                                    int.parse(category.color!.substring(1), radix: 16) + 0xFF000000,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                              )
                            else
                              const Icon(Icons.category, size: 16),
                            const SizedBox(width: 8),
                            Text(category.name),
                          ],
                        ),
                      ),
                    ),
                  ],
                  onChanged:
                      _isLoading
                          ? null
                          : (category) {
                            setState(() {
                              _selectedCategory = category;
                            });
                          },
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _saveTask,
                  child:
                      _isLoading
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : Text(widget.task == null ? '作成' : '更新'),
                ),
                if (widget.task != null) ...[
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                    child: const Text('キャンセル'),
                  ),
                ],
              ],
            ),
          ),
        ),
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
