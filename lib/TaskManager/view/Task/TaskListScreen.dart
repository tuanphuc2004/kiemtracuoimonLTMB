import 'package:flutter/material.dart';
import 'package:taskmanager/TaskManager/view/Task/AddTaskScreen.dart';
import 'package:taskmanager/TaskManager/view/Task/EditTaskScreen.dart';
import 'package:taskmanager/TaskManager/model/Task.dart';
import 'package:taskmanager/TaskManager/view/Task/TaskDetailScreen.dart';
import 'package:taskmanager/TaskManager/view/Authentication/LoginScreen.dart';
import 'package:taskmanager/TaskManager/db/TaskDatabaseHelper.dart';
import 'package:taskmanager/TaskManager/db/UserDatabaseHelper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TaskListScreen extends StatefulWidget {
  final String currentUserId;

  const TaskListScreen({Key? key, required this.currentUserId}) : super(key: key);

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  List<Task> tasks = [];
  List<Task> filteredTasks = [];
  bool isGrid = false;
  String selectedStatus = 'Tất cả';
  String searchKeyword = '';
  bool _isLoading = false;
  bool _dbInitialized = false;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _initializeDatabase();
  }

  Future<void> _initializeDatabase() async {
    try {
      setState(() => _isLoading = true);
      await TaskDatabaseHelper.instance.database;
      setState(() => _dbInitialized = true);

      final user = await UserDatabaseHelper.instance.getUserById(widget.currentUserId);
      _isAdmin = user?.isAdmin ?? false;

      await _loadTasks();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khởi tạo database: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadTasks() async {
    if (!_dbInitialized) return;

    try {
      setState(() => _isLoading = true);

      if (_isAdmin) {
        tasks = await TaskDatabaseHelper.instance.getAllTasks();
      } else {
        tasks = await TaskDatabaseHelper.instance.getTasksByUser(widget.currentUserId);
      }

      _applyFilters();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tải công việc: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    setState(() {
      filteredTasks = tasks.where((task) {
        final matchesStatus = selectedStatus == 'Tất cả' || task.status == selectedStatus;
        final matchesSearch = searchKeyword.isEmpty ||
            task.title.toLowerCase().contains(searchKeyword.toLowerCase()) ||
            (task.description?.toLowerCase().contains(searchKeyword.toLowerCase()) ?? false);
        return matchesStatus && matchesSearch;
      }).toList();

      filteredTasks.sort((a, b) => b.priority.compareTo(a.priority));
    });
  }

  Future<void> _deleteTask(String taskId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa công việc này không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        setState(() => _isLoading = true);
        await TaskDatabaseHelper.instance.deleteTask(taskId);
        await _loadTasks();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi xóa task: $e'), backgroundColor: Colors.red),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  bool _canDeleteTask(Task task) {
    if (_isAdmin) {
      return true; // Admin luôn được xóa
    }
    // Người dùng không phải admin chỉ xóa công việc do họ tạo
    return task.createdBy == widget.currentUserId;
  }

  void _showSearchDialog() {
    final TextEditingController searchController = TextEditingController(text: searchKeyword);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tìm kiếm công việc'),
        content: TextField(
          controller: searchController,
          decoration: const InputDecoration(
            hintText: 'Nhập tiêu đề hoặc mô tả...',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.search),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                searchKeyword = searchController.text.trim();
                _applyFilters();
              });
              Navigator.pop(context);
            },
            child: const Text('Tìm kiếm', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Hủy')),
          TextButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (route) => false,
              );
            },
            child: const Text('Đăng xuất', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor(int priority) {
    switch (priority) {
      case 1:
        return Colors.blueGrey.shade100;
      case 2:
        return Colors.blueGrey.shade200;
      case 3:
        return Colors.blueGrey.shade300;
      default:
        return Colors.grey;
    }
  }

  String _priorityText(int priority) {
    switch (priority) {
      case 1:
        return 'Thấp';
      case 2:
        return 'Trung bình';
      case 3:
        return 'Cao';
      default:
        return 'Không xác định';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'To do':
        return Colors.blue;
      case 'In progress':
        return Colors.orange;
      case 'Done':
        return Colors.green;
      case 'Cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue[300],
        title: const Text('Task Manager'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearchDialog,
          ),
          IconButton(
            icon: Icon(isGrid ? Icons.view_list : Icons.grid_view),
            onPressed: () => setState(() => isGrid = !isGrid),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                _showLogoutDialog();
              } else {
                setState(() {
                  selectedStatus = value;
                  _applyFilters();
                });
              }
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: 'Tất cả',
                child: Row(
                  children: [
                    Icon(Icons.filter_list, color: selectedStatus == 'Tất cả' ? Colors.blue : Colors.grey),
                    const SizedBox(width: 8),
                    Text('Tất cả trạng thái'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'To do',
                child: Row(
                  children: [
                    Icon(Icons.circle, color: selectedStatus == 'To do' ? Colors.blue : Colors.grey, size: 12),
                    const SizedBox(width: 8),
                    Text('To do'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'In progress',
                child: Row(
                  children: [
                    Icon(Icons.circle, color: selectedStatus == 'In progress' ? Colors.orange : Colors.grey, size: 12),
                    const SizedBox(width: 8),
                    Text('In progress'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'Done',
                child: Row(
                  children: [
                    Icon(Icons.circle, color: selectedStatus == 'Done' ? Colors.green : Colors.grey, size: 12),
                    const SizedBox(width: 8),
                    Text('Done'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'Cancelled',
                child: Row(
                  children: [
                    Icon(Icons.circle, color: selectedStatus == 'Cancelled' ? Colors.red : Colors.grey, size: 12),
                    const SizedBox(width: 8),
                    Text('Cancelled'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.exit_to_app, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Đăng xuất'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 16.0),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: Colors.blue.shade400))
                : isGrid
                ? _buildTaskGridView()
                : _buildTaskListView(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddTaskScreen(currentUserId: widget.currentUserId)),
          );
          if (result == true) await _loadTasks();
        },
        child: const Icon(Icons.add, color: Colors.black),
        backgroundColor: Colors.blue.shade400,
      ),
    );
  }

  Widget _buildTaskListView() {
    return ListView.builder(
      itemCount: filteredTasks.length,
      itemBuilder: (context, index) {
        final task = filteredTasks[index];
        return Card(
          color: _getPriorityColor(task.priority),
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            title: Text(task.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _getStatusColor(task.status),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      task.status,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Ưu tiên: ${_priorityText(task.priority)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'edit') {
                  final updatedTask = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditTaskScreen(task: task, currentUserId: widget.currentUserId),
                    ),
                  );
                  if (updatedTask != null) {
                    await TaskDatabaseHelper.instance.updateTask(updatedTask);
                    await _loadTasks();
                  }
                } else if (value == 'delete' && _canDeleteTask(task)) {
                  await _deleteTask(task.id);
                }
              },
              itemBuilder: (ctx) {
                List<PopupMenuEntry<String>> items = [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, color: Colors.blue),
                        SizedBox(width: 8),
                        Text('Chỉnh sửa'),
                      ],
                    ),
                  ),
                ];
                if (_canDeleteTask(task)) {
                  items.add(
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Xóa'),
                        ],
                      ),
                    ),
                  );
                }
                return items;
              },
            ),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TaskDetailScreen(
                    task: task,
                    currentUserId: widget.currentUserId,
                  ),
                ),
              );
              await _loadTasks();
            },
          ),
        );
      },
    );
  }

  Widget _buildTaskGridView() {
    return GridView.builder(
      padding: const EdgeInsets.all(10),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 4 / 3,
      ),
      itemCount: filteredTasks.length,
      itemBuilder: (context, index) {
        final task = filteredTasks[index];
        return GestureDetector(
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TaskDetailScreen(
                  task: task,
                  currentUserId: widget.currentUserId,
                ),
              ),
            );
            await _loadTasks();
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _getPriorityColor(task.priority),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.grey.shade300, blurRadius: 6, offset: const Offset(2, 2)),
              ],
            ),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _getStatusColor(task.status),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          task.status,
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ưu tiên: ${_priorityText(task.priority)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'edit') {
                        final updatedTask = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditTaskScreen(
                              task: task,
                              currentUserId: widget.currentUserId,
                            ),
                          ),
                        );
                        if (updatedTask != null) {
                          await TaskDatabaseHelper.instance.updateTask(updatedTask);
                          await _loadTasks();
                        }
                      } else if (value == 'delete' && _canDeleteTask(task)) {
                        await _deleteTask(task.id);
                      }
                    },
                    itemBuilder: (ctx) {
                      List<PopupMenuEntry<String>> items = [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, color: Colors.blue),
                              SizedBox(width: 8),
                              Text('Chỉnh sửa'),
                            ],
                          ),
                        ),
                      ];
                      if (_canDeleteTask(task)) {
                        items.add(
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Xóa'),
                              ],
                            ),
                          ),
                        );
                      }
                      return items;
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}