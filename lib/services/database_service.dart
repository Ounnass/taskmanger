import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/task.dart';

class DatabaseService {
  DatabaseService._();
  static final DatabaseService instance = DatabaseService._();

  static const _databaseName = 'task_manager.db';
  static const _databaseVersion = 1;
  static const tableTasks = 'tasks';

  Database? _database;
  final Map<String, Task> _webTasks = {};

  Future<Database> get database async {
    if (_database != null) return _database!;
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/$_databaseName';
    _database = await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $tableTasks(
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            description TEXT NOT NULL,
            date TEXT NOT NULL,
            userId TEXT NOT NULL,
            status TEXT NOT NULL,
            isSynced INTEGER NOT NULL DEFAULT 0
          )
        ''');
      },
    );
    return _database!;
  }

  Future<void> upsertTask(Task task) async {
    if (kIsWeb) {
      _webTasks[task.id ?? 'local_${DateTime.now().microsecondsSinceEpoch}'] = task;
      return;
    }
    final db = await database;
    await db.insert(
      tableTasks,
      task.toDb(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> upsertTasks(List<Task> tasks) async {
    if (kIsWeb) {
      for (final task in tasks) {
        _webTasks[task.id ?? 'local_${DateTime.now().microsecondsSinceEpoch}'] = task;
      }
      return;
    }
    final db = await database;
    final batch = db.batch();
    for (final task in tasks) {
      batch.insert(
        tableTasks,
        task.toDb(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<Task>> getTasks() async {
    if (kIsWeb) {
      final tasks = _webTasks.values.toList();
      tasks.sort((a, b) => a.date.compareTo(b.date));
      return tasks;
    }
    final db = await database;
    final rows = await db.query(tableTasks, orderBy: 'date ASC');
    return rows.map(Task.fromDb).toList();
  }

  Future<List<Task>> getUnsyncedTasks() async {
    if (kIsWeb) {
      return _webTasks.values.where((task) => !task.isSynced).toList();
    }
    final db = await database;
    final rows = await db.query(tableTasks, where: 'isSynced = ?', whereArgs: [0]);
    return rows.map(Task.fromDb).toList();
  }

  Future<void> deleteTask(String id) async {
    if (kIsWeb) {
      _webTasks.remove(id);
      return;
    }
    final db = await database;
    await db.delete(tableTasks, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearTasks() async {
    if (kIsWeb) {
      _webTasks.clear();
      return;
    }
    final db = await database;
    await db.delete(tableTasks);
  }
}
