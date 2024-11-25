import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task.dart';

class TaskListScreen extends StatefulWidget {
  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final _auth = FirebaseAuth.instance;
  final _taskController = TextEditingController();
  final _detailController = TextEditingController();

  String _selectedDay = 'Monday';
  String _selectedTimeFrame = '9 am - 10 am';
  List<String> _taskDetails = [];

  // Days and time frames
  final List<String> days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];

  final List<String> timeFrames = [
    '9 am - 10 am',
    '10 am - 11 am',
    '11 am - 12 pm',
    '12 pm - 1 pm',
    '1 pm - 2 pm',
    '2 pm - 3 pm',
    '3 pm - 4 pm',
    '4 pm - 5 pm',
  ];

  // Logout method
  Future<void> _logout() async {
    await _auth.signOut();
    Navigator.pushReplacementNamed(context, '/login');
  }

  // Add task method
  void _addTask() {
    if (_taskController.text.isEmpty) return;

    Task task = Task(
      id: '',
      name: _taskController.text.trim(),
      isCompleted: false,
      day: _selectedDay,
      timeFrame: _selectedTimeFrame,
      details: _taskDetails,
    );

    FirebaseFirestore.instance
        .collection('users')
        .doc(_auth.currentUser!.uid)
        .collection('tasks')
        .add(task.toMap());

    _taskController.clear();
    _detailController.clear();
    _taskDetails.clear();
  }

  // Add detail to task
  void _addDetail() {
    if (_detailController.text.isNotEmpty) {
      setState(() {
        _taskDetails.add(_detailController.text.trim());
        _detailController.clear();
      });
    }
  }

  // Toggle task completion
  void _toggleTaskCompletion(Task task) {
    FirebaseFirestore.instance
        .collection('users')
        .doc(_auth.currentUser!.uid)
        .collection('tasks')
        .doc(task.id)
        .update({'isCompleted': !task.isCompleted});
  }

  // Delete task
  void _deleteTask(Task task) {
    FirebaseFirestore.instance
        .collection('users')
        .doc(_auth.currentUser!.uid)
        .collection('tasks')
        .doc(task.id)
        .delete();
  }

  // Dispose controllers
  @override
  void dispose() {
    _taskController.dispose();
    _detailController.dispose();
    super.dispose();
  }

  // Build method
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Task List'),
        actions: [
          IconButton(icon: Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: Column(
        children: [
          // Task input section
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                // Task name input
                TextField(
                  controller: _taskController,
                  decoration: InputDecoration(
                    labelText: 'Task Name',
                  ),
                ),
                SizedBox(height: 8),
                // Day and time frame selection
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedDay,
                        items: days
                            .map((day) => DropdownMenuItem(
                          value: day,
                          child: Text(day),
                        ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedDay = value!;
                          });
                        },
                        decoration: InputDecoration(labelText: 'Day'),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedTimeFrame,
                        items: timeFrames
                            .map((time) => DropdownMenuItem(
                          value: time,
                          child: Text(time),
                        ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedTimeFrame = value!;
                          });
                        },
                        decoration: InputDecoration(labelText: 'Time Frame'),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                // Task details input
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _detailController,
                        decoration: InputDecoration(
                          labelText: 'Task Detail',
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.add),
                      onPressed: _addDetail,
                    ),
                  ],
                ),
                // Display added details
                Wrap(
                  children: _taskDetails
                      .map((detail) => Chip(
                    label: Text(detail),
                    onDeleted: () {
                      setState(() {
                        _taskDetails.remove(detail);
                      });
                    },
                  ))
                      .toList(),
                ),
                SizedBox(height: 8),
                // Add task button
                ElevatedButton(
                  onPressed: _addTask,
                  child: Text('Add Task'),
                ),
              ],
            ),
          ),
          // Expanded task list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(_auth.currentUser!.uid)
                  .collection('tasks')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return CircularProgressIndicator();

                // Organize tasks into nested structure
                Map<String, Map<String, List<Task>>> nestedTasks = {};

                snapshot.data!.docs.forEach((doc) {
                  Task task =
                  Task.fromMap(doc.data() as Map<String, dynamic>, doc.id);
                  String day = task.day;
                  String timeFrame = task.timeFrame;

                  if (!nestedTasks.containsKey(day)) {
                    nestedTasks[day] = {};
                  }
                  if (!nestedTasks[day]!.containsKey(timeFrame)) {
                    nestedTasks[day]![timeFrame] = [];
                  }
                  nestedTasks[day]![timeFrame]!.add(task);
                });

                return ListView(
                  children: nestedTasks.entries.map((dayEntry) {
                    return ExpansionTile(
                      title: Text(dayEntry.key),
                      children: dayEntry.value.entries.map((timeFrameEntry) {
                        return ExpansionTile(
                          title: Text(timeFrameEntry.key),
                          children: timeFrameEntry.value.map((task) {
                            return ListTile(
                              title: Text(task.name),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Wrap(
                                    children: task.details
                                        .map((detail) => Chip(
                                      label: Text(detail),
                                    ))
                                        .toList(),
                                  ),
                                ],
                              ),
                              leading: Checkbox(
                                value: task.isCompleted,
                                onChanged: (value) {
                                  _toggleTaskCompletion(task);
                                },
                              ),
                              trailing: IconButton(
                                icon: Icon(Icons.delete),
                                onPressed: () {
                                  _deleteTask(task);
                                },
                              ),
                            );
                          }).toList(),
                        );
                      }).toList(),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
