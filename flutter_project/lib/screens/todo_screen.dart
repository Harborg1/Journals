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
                  const Text("Set task limit (1–10): "),
                  SizedBox(
                    width: 60,
                    child: TextField(
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      ),
                      onSubmitted: (value) {
                        final newLimit = int.tryParse(value);
                        if (newLimit != null && newLimit >= 1 && newLimit <= 10) {
                          _setTaskLimit(newLimit);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content: Text('Please enter a number between 1 and 10.'),
                          ));
                        }
                      },
                    ),
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
