class Todo {
  final int id;
  final String todo;
  final bool completed;
  final int userId;

  const Todo({
    required this.id,
    required this.todo,
    required this.completed,
    required this.userId,
  });

  factory Todo.fromJson(Map<String, dynamic> json) => Todo(
        id: json['id'] as int,
        todo: json['todo'] as String,
        completed: json['completed'] as bool,
        userId: json['userId'] as int,
      );
}
