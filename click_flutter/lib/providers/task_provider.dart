import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task.dart';
import '../services/supabase_service.dart';

final supabaseServiceProvider = Provider((ref) => supabaseService);

class TaskNotifier extends AsyncNotifier<List<Task>> {
  late SupabaseService _service;

  @override
  Future<List<Task>> build() async {
    _service = ref.watch(supabaseServiceProvider);
    return _service.getTasks();
  }

  Future<void> addTask(Task task) async {
    // Optimistic UI update: show task immediately
    update((tasks) => [...tasks, task]);
    try {
      await _service.addTask(task);
      // Re-fetch so the UI shows the authoritative DB record
      ref.invalidateSelf();
    } catch (e) {
      debugPrint('Failed to add task to DB (kept locally): $e');
    }
  }

  Future<void> updateTask(Task updatedTask) async {
    // Optimistic UI update
    update(
      (tasks) =>
          tasks.map((t) => t.id == updatedTask.id ? updatedTask : t).toList(),
    );
    try {
      await _service.updateTask(updatedTask);
      ref.invalidateSelf();
    } catch (e) {
      debugPrint('Failed to update task in DB: $e');
    }
  }

  Future<void> deleteTask(String id) async {
    // Optimistic UI update
    update((tasks) => tasks.where((t) => t.id != id).toList());
    try {
      await _service.deleteTask(id);
    } catch (e) {
      debugPrint('Failed to delete task from DB: $e');
    }
  }

  Future<void> toggleTask(String id, bool completed) async {
    // Optimistic UI update
    update(
      (tasks) => tasks.map((t) {
        if (t.id == id) {
          return t.copyWith(
            completed: completed,
            completedAt: completed ? DateTime.now() : null,
          );
        }
        return t;
      }).toList(),
    );
    try {
      await _service.toggleTask(id, completed);
    } catch (e) {
      debugPrint('Failed to toggle task in DB: $e');
    }
  }
}

final taskProvider = AsyncNotifierProvider<TaskNotifier, List<Task>>(() {
  return TaskNotifier();
});
