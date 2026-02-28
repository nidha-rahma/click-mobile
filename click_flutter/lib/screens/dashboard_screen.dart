import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/pomodoro_timer.dart';
import '../widgets/stats_bar.dart';
import '../widgets/task_bottom_sheet.dart';
import '../widgets/task_card.dart';
import '../widgets/task_details.dart';

enum TaskFilter { today, thisWeek, all }

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  TaskFilter _currentFilter = TaskFilter.today;
  String? _focusedTaskId;

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

  void _showTaskDetails(Task task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return TaskDetails(task: task);
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

    return SafeArea(
      child: Scaffold(
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

            final streak = doneToday > 0 ? 1 : 0;

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => _showTaskBottomSheet(),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      LucideIcons.plus,
                                      size: 20,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Add',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: Icon(
                                Theme.of(context).brightness == Brightness.light
                                    ? LucideIcons.moon
                                    : LucideIcons.sun,
                              ),
                              onPressed: () {
                                final isLight =
                                    Theme.of(context).brightness ==
                                    Brightness.light;
                                ref
                                    .read(themeProvider.notifier)
                                    .setThemeMode(
                                      isLight
                                          ? ThemeMode.dark
                                          : ThemeMode.light,
                                    );
                              },
                            ),
                          ],
                        ),
                        Divider(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurfaceVariant.withValues(alpha: 0.1),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          totalPending == 0
                              ? "You're all caught up!"
                              : 'You have ${pendingTasks.length} pending task${pendingTasks.length == 1 ? '' : 's'}',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
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
                            onClose: () {
                              setState(() {
                                _focusedTaskId = null;
                              });
                            },
                          ),
                        ],
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.1),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildFilterButton(
                                TaskFilter.all,
                                'All Tasks',
                                LucideIcons.inbox,
                              ),
                              _buildFilterButton(
                                TaskFilter.today,
                                'Today',
                                LucideIcons.sun,
                              ),
                              _buildFilterButton(
                                TaskFilter.thisWeek,
                                'This Week',
                                LucideIcons.calendar,
                              ),
                            ],
                          ),
                        ),
                        if (allTasks.isEmpty) ...[
                          const SizedBox(height: 80),
                          Center(
                            child: Column(
                              children: [
                                Icon(
                                  LucideIcons.listTodo,
                                  size: 48,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant
                                      .withValues(alpha: 0.5),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  "No tasks yet",
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Tap + to create your first task",
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant
                                            .withValues(alpha: 0.7),
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (pendingTasks.isNotEmpty) ...[
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
                          fontSize: 16,
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
      onTap: () => _showTaskDetails(task),
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

  Widget _buildFilterButton(TaskFilter filter, String label, IconData icon) {
    final isSelected = _currentFilter == filter;
    return GestureDetector(
      onTap: () => setState(() => _currentFilter = filter),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? Theme.of(context).colorScheme.onSurface
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? Theme.of(context).colorScheme.onSurface
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
