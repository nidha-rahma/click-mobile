import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../models/task.dart';
import '../providers/task_provider.dart';
import '../widgets/pomodoro_timer.dart';
import '../widgets/stats_bar.dart';
import '../widgets/task_bottom_sheet.dart';
import '../widgets/task_card.dart';

enum TaskFilter { today, thisWeek, all }

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  TaskFilter _currentFilter = TaskFilter.today;
  String? _focusedTaskId;

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  void _showTaskBottomSheet([Task? task]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return TaskBottomSheet(
          existingTask: task,
          onSave: (newTask) {
            if (task == null) {
              ref.read(taskProvider.notifier).addTask(newTask);
            } else {
              ref.read(taskProvider.notifier).updateTask(newTask);
            }
          },
        );
      },
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  bool _isThisWeek(DateTime date) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    return date.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
        date.isBefore(endOfWeek.add(const Duration(days: 1)));
  }

  List<Task> _filterAndSortTasks(List<Task> tasks) {
    List<Task> filtered = tasks.where((task) {
      final dateToCheck = task.deadline ?? task.createdAt;
      switch (_currentFilter) {
        case TaskFilter.today:
          return _isToday(dateToCheck);
        case TaskFilter.thisWeek:
          return _isThisWeek(dateToCheck);
        case TaskFilter.all:
          return true;
      }
    }).toList();

    filtered.sort((a, b) {
      if (a.completed && !b.completed) return 1;
      if (!a.completed && b.completed) return -1;

      if (a.priority.index < b.priority.index) return -1;
      if (a.priority.index > b.priority.index) return 1;

      if (a.deadline != null && b.deadline != null) {
        return a.deadline!.compareTo(b.deadline!);
      }
      return 0;
    });

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(taskProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'TaskMate',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              LucideIcons.sun,
            ), // Static for now, could toggle theme
            onPressed: () {},
          ),
        ],
      ),
      body: tasksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (allTasks) {
          final tasks = _filterAndSortTasks(allTasks);

          final pendingTasks = tasks.where((t) => !t.completed).toList();
          final completedTasks = tasks.where((t) => t.completed).toList();

          final todayTasks = allTasks.where(
            (t) => _isToday(t.deadline ?? t.createdAt),
          );
          final doneToday = todayTasks.where((t) => t.completed).length;

          final weekTasks = allTasks.where(
            (t) => _isThisWeek(t.deadline ?? t.createdAt),
          );
          final doneThisWeek = weekTasks.where((t) => t.completed).length;

          final totalPending = allTasks.where((t) => !t.completed).length;

          // Simple mock streak calculation
          final streak = doneToday > 0 ? 1 : 0;

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getGreeting(),
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'You have ${pendingTasks.length} pending tasks',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),
                      StatsBar(
                        doneToday: doneToday,
                        totalToday: todayTasks.length,
                        totalPending: totalPending,
                        doneThisWeek: doneThisWeek,
                        totalThisWeek: weekTasks.length,
                        streak: streak,
                      ),
                      if (_focusedTaskId != null) ...[
                        const SizedBox(height: 16),
                        PomodoroTimer(
                          key: ValueKey(_focusedTaskId),
                          taskId: _focusedTaskId!,
                        ),
                      ],
                      const SizedBox(height: 16),
                      SegmentedButton<TaskFilter>(
                        segments: const [
                          ButtonSegment(
                            value: TaskFilter.today,
                            label: Text('Today'),
                          ),
                          ButtonSegment(
                            value: TaskFilter.thisWeek,
                            label: Text('This Week'),
                          ),
                          ButtonSegment(
                            value: TaskFilter.all,
                            label: Text('All Tasks'),
                          ),
                        ],
                        selected: <TaskFilter>{_currentFilter},
                        onSelectionChanged: (Set<TaskFilter> newSelection) {
                          setState(() {
                            _currentFilter = newSelection.first;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              if (pendingTasks.isNotEmpty) ...[
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: Text(
                      'Pending',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildTaskCard(pendingTasks[index]),
                    childCount: pendingTasks.length,
                  ),
                ),
              ],
              if (completedTasks.isNotEmpty) ...[
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: Text(
                      'Completed',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => Opacity(
                      opacity: 0.6,
                      child: _buildTaskCard(completedTasks[index]),
                    ),
                    childCount: completedTasks.length,
                  ),
                ),
              ],
              const SliverToBoxAdapter(
                child: SizedBox(height: 80),
              ), // FAB padding
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTaskBottomSheet(),
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: Theme.of(context).brightness == Brightness.light
                ? const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF047857)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
          ),
          child: const Icon(LucideIcons.plus),
        ),
      ),
    );
  }

  Widget _buildTaskCard(Task task) {
    return TaskCard(
      key: ValueKey(task.id),
      task: task,
      onToggle: (val) {
        if (val != null) {
          ref.read(taskProvider.notifier).toggleTask(task.id, val);
        }
      },
      onFocus: () {
        setState(() {
          _focusedTaskId = _focusedTaskId == task.id ? null : task.id;
        });
      },
      onEdit: () => _showTaskBottomSheet(task),
      onDelete: () {
        ref.read(taskProvider.notifier).deleteTask(task.id);
        if (_focusedTaskId == task.id) {
          setState(() => _focusedTaskId = null);
        }
      },
      onSubtaskToggle: (subtask) {
        final updatedSubtasks = task.subtasks
            .map((s) => s.id == subtask.id ? subtask : s)
            .toList();
        final updatedTask = task.copyWith(subtasks: updatedSubtasks);
        ref.read(taskProvider.notifier).updateTask(updatedTask);
      },
    );
  }
}
