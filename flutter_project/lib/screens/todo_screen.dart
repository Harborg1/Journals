import 'package:flutter/material.dart';

class ToDo extends StatefulWidget {
  const ToDo({super.key});

  @override
  State<ToDo> createState() => _ToDoState();
}

class _ToDoState extends State<ToDo> {
  final List<Map<String, dynamic>> _todos = [];
  final TextEditingController _controller = TextEditingController();
  static const int maxItems = 5;

  void _addTodo() {
    final text = _controller.text.trim();
    if (text.isNotEmpty && _todos.length < maxItems) {
      setState(() {
        _todos.add({'text': text, 'done': false});
        _controller.clear();
      });
    }
  }

  void _toggleDone(int index) {
    setState(() {
      _todos[index]['done'] = !_todos[index]['done'];
    });

    // Check for completion
   if (_todos.length == maxItems && _todos.every((item) => item['done'])) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    Navigator.pop(context, true);
  });
}

  }

  void _deleteTodo(int index) {
    setState(() {
      _todos.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLimitReached = _todos.length >= maxItems;

    return Scaffold(
      appBar: AppBar(title: const Text('Your ToDo List')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      labelText: 'Enter task',
                      border: const OutlineInputBorder(),
                      errorText: isLimitReached ? 'Max 5 tasks' : null,
                    ),
                    onSubmitted: (_) => _addTodo(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: isLimitReached ? null : _addTodo,
                  child: const Icon(Icons.add),
                ),
              ],
            ),
          ),
          Expanded(
            child: _todos.isEmpty
                ? const Center(child: Text("No tasks added yet."))
                : ListView.builder(
                    itemCount: _todos.length,
                    itemBuilder: (context, index) {
                      final todo = _todos[index];
                      return ListTile(
                        leading: Checkbox(
                          value: todo['done'],
                          onChanged: (_) => _toggleDone(index),
                        ),
                        title: Text(
                          todo['text'],
                          style: TextStyle(
                            decoration: todo['done']
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _deleteTodo(index),
                        ),
                      );
                    },
                  ),
              ),
            ],
          ),
        );
      }
    }
