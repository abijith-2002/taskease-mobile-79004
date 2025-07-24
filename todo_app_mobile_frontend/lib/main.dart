import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  final dbHelper = await TodoDatabaseHelper.getInstance();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => TodoProvider(dbHelper),
        )
      ],
      child: const TodoApp(),
    )
  );
}

class TodoApp extends StatelessWidget {
  const TodoApp({super.key});
  @override
  Widget build(BuildContext context) {
    final Color primary = const Color(0xFF1976d2);
    final Color secondary = const Color(0xFF424242);
    final Color accent = const Color(0xFFFFCA28);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Minimalistic Dark Todo',
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: secondary,
        colorScheme: ColorScheme(
          brightness: Brightness.dark,
          primary: primary,
          onPrimary: Colors.white,
          secondary: accent,
          onSecondary: Colors.black,
          error: Colors.red,
          onError: Colors.white,
          surface: const Color(0xFF292929),
          onSurface: Colors.white,
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: accent,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        cardTheme: CardTheme(
          color: const Color(0xFF222222),
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: secondary,
          elevation: 0,
          titleTextStyle: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: primary,
          contentTextStyle: const TextStyle(color: Colors.white),
          actionTextColor: accent,
        ),
        checkboxTheme: CheckboxThemeData(
          fillColor: WidgetStateProperty.resolveWith<Color?>(
              (states) => states.contains(WidgetState.selected) ? accent : primary),
          checkColor: WidgetStateProperty.all(Colors.black),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
      home: const TodoHomeScreen(),
    );
  }
}

class TodoHomeScreen extends StatefulWidget {
  const TodoHomeScreen({super.key});
  @override
  State<TodoHomeScreen> createState() => _TodoHomeScreenState();
}

class _TodoHomeScreenState extends State<TodoHomeScreen> {
  int tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tasks"),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: "Settings (future)",
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settings coming soon!')),
              );
            },
          )
        ],
        automaticallyImplyLeading: false,
      ),
      body: Consumer<TodoProvider>(
        builder: (context, provider, _) {
          final List<TodoItem> displayTodos = tabIndex == 0
              ? provider.activeTodos
              : provider.completedTodos;

          if (displayTodos.isEmpty) {
            return Center(
              child: Text(
                tabIndex == 0
                    ? 'Nothing to do. Tap + to add a task!'
                    : 'No completed tasks.',
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(top: 12, bottom: 76),
            itemCount: displayTodos.length,
            itemBuilder: (context, idx) =>
                TodoCard(todo: displayTodos[idx]),
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: colorScheme.secondary,
        selectedItemColor: colorScheme.secondary,
        unselectedItemColor: Colors.white38,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        currentIndex: tabIndex,
        onTap: (i) {
          setState(() {
            tabIndex = i;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.radio_button_unchecked_outlined),
            label: 'Active',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.check_circle_outline),
            label: 'Completed',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddOrEditTodo(context),
        tooltip: "Add new task",
        child: const Icon(Icons.add, size: 32),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
    );
  }

  Future<void> _showAddOrEditTodo(BuildContext context, {TodoItem? editTodo}) async {
    final provider = Provider.of<TodoProvider>(context, listen: false);
    final isEditing = editTodo != null;
    final titleController =
        TextEditingController(text: isEditing ? editTodo!.title : "");
    final detailController =
        TextEditingController(text: isEditing ? editTodo!.details : "");
    final colorScheme = Theme.of(context).colorScheme;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
              left: 20, right: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 18, top: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isEditing ? "Edit Task" : "New Task",
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 20, color: colorScheme.primary),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: titleController,
                autofocus: !isEditing,
                decoration: InputDecoration(
                  labelText: 'Title',
                  border: const OutlineInputBorder(),
                  labelStyle: TextStyle(color: colorScheme.primary),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: colorScheme.primary),
                  ),
                ),
                maxLength: 60,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: detailController,
                decoration: InputDecoration(
                  labelText: 'Details (optional)',
                  border: const OutlineInputBorder(),
                  labelStyle: TextStyle(color: colorScheme.secondary),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: colorScheme.secondary),
                  ),
                ),
                maxLines: 2,
                maxLength: 120,
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (isEditing)
                    TextButton.icon(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      label: const Text("Delete", style: TextStyle(color: Colors.red)),
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await provider.deleteTodo(editTodo!.id);
                        // Show snackbar after context is popped
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Task deleted")),
                            );
                          }
                        });
                      },
                    )
                  else
                    const SizedBox(width: 0, height: 0),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: Colors.white,
                      elevation: 1,
                      minimumSize: const Size(104, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    icon: Icon(isEditing ? Icons.check : Icons.add),
                    label: Text(isEditing ? "Save" : "Add"),
                    onPressed: () async {
                      final title = titleController.text.trim();
                      final details = detailController.text.trim();
                      if (title.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Title cannot be empty!"))
                        );
                        return;
                      }
                      if (isEditing) {
                        await provider.updateTodo(
                          editTodo!.copyWith(title: title, details: details),
                        );
                        Navigator.pop(ctx);
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Task updated")),
                            );
                          }
                        });
                      } else {
                        await provider.addTodo(
                          TodoItem(
                            title: title,
                            details: details,
                          ));
                        Navigator.pop(ctx);
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Task added")),
                            );
                          }
                        });
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      }
    );
    titleController.dispose();
    detailController.dispose();
  }
}

class TodoCard extends StatelessWidget {
  final TodoItem todo;

  const TodoCard({super.key, required this.todo});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TodoProvider>(context, listen: false);
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () {
        final parentState = context.findAncestorStateOfType<_TodoHomeScreenState>();
        parentState?._showAddOrEditTodo(context, editTodo: todo);
      },
      child: Dismissible(
        key: ValueKey(todo.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24),
          color: Colors.red.shade700,
          child: const Icon(Icons.delete, color: Colors.white, size: 30),
        ),
        confirmDismiss: (direction) async {
          return await showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: Theme.of(ctx).scaffoldBackgroundColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              title: const Text("Delete Task"),
              content: const Text("Are you sure you want to delete this task?"),
              actions: [
                TextButton(
                  child: const Text("Cancel", style: TextStyle(color: Colors.white54)),
                  onPressed: () => Navigator.of(ctx).pop(false),
                ),
                TextButton(
                  child: const Text("Delete", style: TextStyle(color: Colors.red)),
                  onPressed: () => Navigator.of(ctx).pop(true),
                ),
              ],
            ),
          );
        },
        onDismissed: (direction) async {
          await provider.deleteTodo(todo.id!);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Task deleted")),
              );
            }
          });
        },
        child: Card(
          child: ListTile(
            leading: Checkbox(
              value: todo.isCompleted,
              onChanged: (checked) async {
                final updated = todo.copyWith(isCompleted: checked ?? false);
                await provider.updateTodo(updated);
              },
              shape: const CircleBorder(),
            ),
            title: Text(
              todo.title,
              style: TextStyle(
                decoration: todo.isCompleted ? TextDecoration.lineThrough : null,
                color: todo.isCompleted ? Colors.white60 : colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: todo.details.isNotEmpty
                ? Text(
                    todo.details,
                    style: TextStyle(
                      color: todo.isCompleted ? Colors.white38 : Colors.white60,
                      fontSize: 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  )
                : null,
            trailing: todo.isCompleted
                ? const Icon(Icons.check, color: Color(0xFFFFCA28))
                : null,
          ),
        ),
      ),
    );
  }
}

class TodoItem {
  int? id;
  final String title;
  final String details;
  final bool isCompleted;
  final DateTime createdAt;

  TodoItem({
    this.id,
    required this.title,
    this.details = "",
    this.isCompleted = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  TodoItem copyWith({
    int? id,
    String? title,
    String? details,
    bool? isCompleted,
    DateTime? createdAt,
  }) {
    return TodoItem(
      id: id ?? this.id,
      title: title ?? this.title,
      details: details ?? this.details,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'details': details,
      'isCompleted': isCompleted ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory TodoItem.fromMap(Map<String, dynamic> map) {
    return TodoItem(
      id: map['id'] as int?,
      title: map['title'] as String,
      details: map['details'] as String? ?? "",
      isCompleted: map['isCompleted'] == 1,
      createdAt: DateTime.tryParse(map['createdAt'] ?? "") ?? DateTime.now(),
    );
  }
}

class TodoDatabaseHelper {
  static const _dbName = "todo_app.db";
  static const _table = "todos";
  static const _version = 1;

  static TodoDatabaseHelper? _instance;
  late Database db;

  TodoDatabaseHelper._();

  static Future<TodoDatabaseHelper> getInstance() async {
    if (_instance != null) return _instance!;
    var helper = TodoDatabaseHelper._();
    await helper._init();
    _instance = helper;
    return helper;
  }

  Future<void> _init() async {
    final dbPath = await getDatabasesPath();
    db = await openDatabase(
      join(dbPath, _dbName),
      version: _version,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_table (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            details TEXT,
            isCompleted INTEGER NOT NULL DEFAULT 0,
            createdAt TEXT NOT NULL
          )
        ''');
      },
    );
  }

  Future<List<TodoItem>> getAllTodos() async {
    final List<Map<String, dynamic>> maps =
    await db.query(_table, orderBy: "createdAt DESC");
    return List.generate(maps.length, (i) => TodoItem.fromMap(maps[i]));
  }

  Future<int> addTodo(TodoItem todo) async {
    return await db.insert(_table, todo.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> updateTodo(TodoItem todo) async {
    return await db.update(
      _table,
      todo.toMap(),
      where: "id = ?",
      whereArgs: [todo.id],
    );
  }

  Future<int> deleteTodo(int id) async {
    return await db.delete(_table, where: "id = ?", whereArgs: [id]);
  }
}

class TodoProvider extends ChangeNotifier {
  final TodoDatabaseHelper dbHelper;

  List<TodoItem> _todos = [];
  TodoProvider(this.dbHelper) {
    _init();
  }

  Future<void> _init() async {
    await refreshTodos();
  }

  List<TodoItem> get allTodos => _todos;
  List<TodoItem> get activeTodos =>
      _todos.where((todo) => !todo.isCompleted).toList();
  List<TodoItem> get completedTodos =>
      _todos.where((todo) => todo.isCompleted).toList();

  Future<void> refreshTodos() async {
    _todos = await dbHelper.getAllTodos();
    notifyListeners();
  }

  Future<void> addTodo(TodoItem todo) async {
    await dbHelper.addTodo(todo);
    await refreshTodos();
  }

  Future<void> updateTodo(TodoItem todo) async {
    await dbHelper.updateTodo(todo);
    await refreshTodos();
  }

  Future<void> deleteTodo(int id) async {
    await dbHelper.deleteTodo(id);
    await refreshTodos();
  }
}
