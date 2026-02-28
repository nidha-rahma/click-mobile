import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/task.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Task>> getTasks() async {
    try {
      final response = await _client.from('tasks').select();
      return (response as List).map((json) => Task.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching tasks: $e');
      return [];
    }
  }

  Future<Task> addTask(Task task) async {
    final response = await _client
        .from('tasks')
        .insert(task.toJson())
        .select()
        .single();
    return Task.fromJson(response);
  }

  Future<Task> updateTask(Task task) async {
    final response = await _client
        .from('tasks')
        .update(task.toJson())
        .eq('id', task.id)
        .select()
        .single();
    return Task.fromJson(response);
  }

  Future<void> deleteTask(String id) async {
    await _client.from('tasks').delete().eq('id', id);
  }

  Future<Task> toggleTask(String id, bool completed) async {
    final updateData = {
      'completed': completed,
      'completedAt': completed ? DateTime.now().toIso8601String() : null,
    };
    final response = await _client
        .from('tasks')
        .update(updateData)
        .eq('id', id)
        .select()
        .single();
    return Task.fromJson(response);
  }
}

final supabaseService = SupabaseService();
