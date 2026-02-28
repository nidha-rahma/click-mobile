import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task.dart';
import '../services/supabase_service.dart';

final supabaseServiceProvider = Provider((ref) => supabaseService);

class TaskNotifier extends AsyncNotifier<List<Task>> {
  late final SupabaseService _service;

  @override
  Future<List<Task>> build() async {
    _service = ref.watch(supabaseServiceProvider);
    return _service.getTasks();
  }

  Future<void> addTask(Task task) async {
    try {
      final newTask = await _service.addTask(task);
      update((tasks) => [...tasks, newTask]);
    } catch (e) {
      // Handle error (e.g., show snackbar in UI)
      debugPrint('Failed to add task: $e');
    }
  }

  Future<void> updateTask(Task updatedTask) async {
    try {
      final task = await _service.updateTask(updatedTask);
      update((tasks) => tasks.map((t) => t.id == task.id ? task : t).toList());
    } catch (e) {
      debugPrint('Failed to update task: $e');
    }
  }

  Future<void> deleteTask(String id) async {
    try {
      await _service.deleteTask(id);
      update((tasks) => tasks.where((t) => t.id != id).toList());
    } catch (e) {
      debugPrint('Failed to delete task: $e');
    }
  }

  Future<void> toggleTask(String id, bool completed) async {
    try {
      final updatedTask = await _service.toggleTask(id, completed);
      update(
        (tasks) => tasks.map((t) => t.id == id ? updatedTask : t).toList(),
      );
    } catch (e) {
      debugPrint('Failed to toggle task: $e');
    }
  }
}

final taskProvider = AsyncNotifierProvider<TaskNotifier, List<Task>>(() {
  return TaskNotifier();
});
