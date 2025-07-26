import 'package:flutter/material.dart';

class ToDo extends StatefulWidget {
  const ToDo({super.key});

  @override
  State<ToDo> createState() => _ToDoState();
}

class _ToDoState extends State<ToDo> {
  final List<Map<String, dynamic>> _todos = [];
  final TextEditingController _controller = TextEditingController();
  int _taskLimit = 3; // Default limit is 3

  void _addTodo() {
    final text = _controller.text.trim();
    if (text.isNotEmpty && _todos.length < _taskLimit) {
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
    if (_todos.length == _taskLimit && _todos.every((item) => item['done'])) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pop(context, true); // or trigger animation before this
      });
    }
  }

  void _deleteTodo(int index) {
    setState(() {
      _todos.removeAt(index);
    });
  }

  void _setTaskLimit(int newLimit) {
    if (_todos.length <= newLimit) {
      setState(() {
        _taskLimit = newLimit;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            'Reduce tasks to ${newLimit} or fewer before changing the limit.'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLimitReached = _todos.length >= _taskLimit;

    return Scaffold(
      appBar: AppBar(title: const Text('')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: InputDecoration(
                          labelText: 'Enter task',
                          border: const OutlineInputBorder(),
                          errorText: isLimitReached ? 'Limit reached' : null,
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
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Select number of tasks: "),
                    DropdownButton<int>(
                      value: _taskLimit,
                      items: List.generate(
                        5,
                        (i) => DropdownMenuItem(
                          value: i + 1,
                          child: Text('${i + 1}'),
                        ),
                      ),
                      onChanged: (val) {
                        if (val != null) _setTaskLimit(val);
                      },
                    ),
                  ],
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
