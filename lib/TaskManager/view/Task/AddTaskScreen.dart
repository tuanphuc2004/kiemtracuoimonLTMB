import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:taskmanager/TaskManager/model/Task.dart';
import 'package:taskmanager/TaskManager/model/User.dart';
import 'package:taskmanager/TaskManager/db/TaskDatabaseHelper.dart';
import 'package:taskmanager/TaskManager/db/UserDatabaseHelper.dart';

class AddTaskScreen extends StatefulWidget {
  final String currentUserId;

  const AddTaskScreen({Key? key, required this.currentUserId}) : super(key: key);

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _status = 'To do';
  int _priority = 1;
  DateTime? _dueDate;
  String? _assignedTo;
  List<String> _attachments = [];
  List<User> _users = [];
  bool _isLoading = false;
  bool _isAdmin = false;

  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  final List<String> _statusOptions = ['To do', 'In progress', 'Done', 'Cancelled'];
  final List<int> _priorityOptions = [1, 2, 3];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      User? currentUser = await UserDatabaseHelper.instance.getUserById(widget.currentUserId);
      _isAdmin = currentUser?.isAdmin ?? false;

      if (_isAdmin) {
        _users = await UserDatabaseHelper.instance.getAllUsers();
        _users.removeWhere((user) => user.id == widget.currentUserId);
      } else {
        _users = [];
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tải user: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _attachments.addAll(result.paths.where((path) => path != null).cast<String>());
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi chọn file: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _removeAttachment(int index) {
    setState(() {
      _attachments.removeAt(index);
    });
  }

  Future<void> _selectDueDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue.shade400,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue.shade400,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _dueDate) {
      setState(() {
        _dueDate = picked;
      });
    }
  }

  Future<void> _handleAddTask() async {
    if (_formKey.currentState!.validate()) {
      try {
        setState(() => _isLoading = true);
        final newTask = Task(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: _titleController.text,
          description: _descriptionController.text,
          status: _status,
          priority: _priority,
          dueDate: _dueDate,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          assignedTo: _isAdmin ? _assignedTo : widget.currentUserId,
          createdBy: widget.currentUserId,
          category: null,
          attachments: _attachments.isNotEmpty ? _attachments : null,
          completed: _status == 'Done',
        );
        await TaskDatabaseHelper.instance.createTask(newTask);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Thêm công việc thành công!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi thêm công việc: $e'), backgroundColor: Colors.red),
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
        title: const Text('Thêm công việc'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save, color: Colors.white),
            onPressed: _handleAddTask,
          ),
        ],
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
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tiêu đề
                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: 'Tiêu đề *',
                          labelStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Vui lòng nhập tiêu đề';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Mô tả
                      TextFormField(
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          labelText: 'Mô tả',
                          labelStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        maxLines: 4,
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      // Trạng thái
                      DropdownButtonFormField<String>(
                        value: _status,
                        decoration: InputDecoration(
                          labelText: 'Trạng thái',
                          labelStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          suffixIcon: Container(
                            margin: const EdgeInsets.only(right: 8),
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _getStatusColor(_status),
                            ),
                          ),
                        ),
                        items: _statusOptions
                            .map((status) => DropdownMenuItem(value: status, child: Text(status)))
                            .toList(),
                        onChanged: (value) => setState(() => _status = value!),
                      ),
                      const SizedBox(height: 16),
                      // Độ ưu tiên
                      DropdownButtonFormField<int>(
                        value: _priority,
                        decoration: InputDecoration(
                          labelText: 'Độ ưu tiên',
                          labelStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          suffixIcon: Container(
                            margin: const EdgeInsets.only(right: 8),
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _getPriorityColor(_priority),
                            ),
                          ),
                        ),
                        items: _priorityOptions
                            .map((priority) => DropdownMenuItem(
                          value: priority,
                          child: Text(
                            priority == 1 ? 'Thấp' : priority == 2 ? 'Trung bình' : 'Cao',
                          ),
                        ))
                            .toList(),
                        onChanged: (value) => setState(() => _priority = value!),
                      ),
                      const SizedBox(height: 16),
                      // Ngày đến hạn
                      InkWell(
                        onTap: () => _selectDueDate(context),
                        borderRadius: BorderRadius.circular(12),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Ngày đến hạn',
                            labelStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _dueDate == null ? 'Chọn ngày' : _dateFormat.format(_dueDate!),
                                style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                              ),
                              Icon(Icons.calendar_today, color: Colors.grey[600]),
                            ],
                          ),
                        ),
                      ),
                      // Gán cho người dùng (cho admin)
                      if (_users.isNotEmpty && _isAdmin) ...[
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _assignedTo,
                          decoration: InputDecoration(
                            labelText: 'Gán cho người dùng',
                            labelStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                          items: [
                            const DropdownMenuItem<String>(
                              value: null,
                              child: Text('Không gán'),
                            ),
                            ..._users.map((user) {
                              return DropdownMenuItem<String>(
                                value: user.id,
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 12,
                                      backgroundColor: Colors.blue.shade100,
                                      child: Text(
                                        user.username[0].toUpperCase(),
                                        style: TextStyle(
                                          color: Colors.blue.shade800,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(user.username, style: const TextStyle(fontSize: 14)),
                                  ],
                                ),
                              );
                            }),
                          ],
                          onChanged: (value) => setState(() => _assignedTo = value),
                        ),
                      ],
                      const SizedBox(height: 16),
                      // Tệp đính kèm
                      ElevatedButton.icon(
                        onPressed: _pickFiles,
                        icon: const Icon(Icons.attach_file, color: Colors.black),
                        label: const Text('Thêm tệp đính kèm', style: TextStyle(color: Colors.black)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade300,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      ),
                      if (_attachments.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Tệp đính kèm:',
                          style: TextStyle(color: Colors.grey[600], fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Column(
                          children: _attachments.asMap().entries.map((entry) {
                            final index = entry.key;
                            final path = entry.value;
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              elevation: 1,
                              child: ListTile(
                                leading: Icon(Icons.insert_drive_file, color: Colors.blue.shade300),
                                title: Text(
                                  path.split('/').last,
                                  style: const TextStyle(fontSize: 14),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: IconButton(
                                  icon: Icon(Icons.close, color: Colors.red.shade600),
                                  onPressed: () => _removeAttachment(index),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                      const SizedBox(height: 24),
                      // Nút thêm
                      Center(
                        child: ElevatedButton(
                          onPressed: _handleAddTask,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade300,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                          ),
                          child: const Text(
                            'Thêm công việc',
                            style: TextStyle(fontSize: 16, color: Colors.black),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}