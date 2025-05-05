import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:taskmanager/TaskManager/model/Task.dart';
import 'package:taskmanager/TaskManager/model/User.dart';
import 'package:taskmanager/TaskManager/db/UserDatabaseHelper.dart';

class TaskDetailScreen extends StatefulWidget {
  final Task task;
  final String currentUserId; // Thêm currentUserId

  const TaskDetailScreen({Key? key, required this.task, required this.currentUserId}) : super(key: key);

  @override
  _TaskDetailScreenState createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  String? _assignedToUsername;
  bool _isLoading = false;

  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    _loadAssignedUser();
  }

  Future<void> _loadAssignedUser() async {
    if (widget.task.assignedTo != null) {
      setState(() => _isLoading = true);
      try {
        User? user = await UserDatabaseHelper.instance.getUserById(widget.task.assignedTo!);
        setState(() {
          _assignedToUsername = user?.username ?? 'Không xác định';
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi tải thông tin người dùng: $e'), backgroundColor: Colors.red),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Color _getPriorityColor(int priority) {
    switch (priority) {
      case 1:
        return Colors.green.shade100;
      case 2:
        return Colors.orange.shade100;
      case 3:
        return Colors.red.shade100;
      default:
        return Colors.grey.shade200;
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
        title: const Text('Chi tiết công việc'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.blue.shade400))
          : SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          children: [
            const SizedBox(height: 16.0),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 2,
              color: Colors.grey[200],
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tiêu đề
                    Text(
                      'Tiêu đề',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.task.title,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    // Mô tả
                    if (widget.task.description != null && widget.task.description!.isNotEmpty) ...[
                      Text(
                        'Mô tả',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.task.description!,
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                    ],
                    // Trạng thái
                    Text(
                      'Trạng thái',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _getStatusColor(widget.task.status),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.task.status,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Độ ưu tiên
                    Text(
                      'Độ ưu tiên',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _getPriorityColor(widget.task.priority),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.task.priority == 1
                              ? 'Thấp'
                              : widget.task.priority == 2
                              ? 'Trung bình'
                              : 'Cao',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Ngày đến hạn
                    if (widget.task.dueDate != null) ...[
                      Text(
                        'Ngày đến hạn',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _dateFormat.format(widget.task.dueDate!),
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                    ],
                    // Người được gán
                    if (widget.task.assignedTo != null && _assignedToUsername != null) ...[
                      Text(
                        'Người được gán',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: Colors.blue.shade100,
                            child: Text(
                              _assignedToUsername![0].toUpperCase(),
                              style: TextStyle(
                                color: Colors.blue.shade800,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _assignedToUsername!,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                    // Tệp đính kèm
                    if (widget.task.attachments != null && widget.task.attachments!.isNotEmpty) ...[
                      Text(
                        'Tệp đính kèm',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 4),
                      Column(
                        children: widget.task.attachments!.asMap().entries.map((entry) {
                          final path = entry.value;
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 1,
                            child: ListTile(
                              leading: Icon(Icons.insert_drive_file, color: Colors.blue.shade400),
                              title: Text(
                                path.split('/').last,
                                style: const TextStyle(fontSize: 14),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}