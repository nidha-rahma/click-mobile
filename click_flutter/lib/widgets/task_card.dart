import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../theme/app_theme.dart';

class TaskCard extends StatefulWidget {
  final Task task;
  final ValueChanged<bool?> onToggle;
  final VoidCallback onFocus;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<Subtask> onSubtaskToggle;

  const TaskCard({
    super.key,
    required this.task,
    required this.onToggle,
    required this.onFocus,
    required this.onEdit,
    required this.onDelete,
    required this.onSubtaskToggle,
  });

  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard> {
  bool _expanded = false;

  Color _getPriorityColor(Priority priority) {
    switch (priority) {
      case Priority.high:
        return AppTheme.highPriority;
      case Priority.medium:
        return AppTheme.mediumPriority;
      case Priority.low:
        return AppTheme.lowPriority;
    }
  }

  @override
  Widget build(BuildContext context) {
    final completedSubtasks = widget.task.subtasks
        .where((s) => s.completed)
        .length;
    final totalSubtasks = widget.task.subtasks.length;
    final isOverdue =
        widget.task.deadline != null &&
        widget.task.deadline!.isBefore(DateTime.now()) &&
        !widget.task.completed;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: widget.task.completed
          ? Theme.of(context).colorScheme.surface.withValues(alpha: 0.6)
          : null,
      child: ExpansionTile(
        initiallyExpanded: _expanded,
        onExpansionChanged: (val) {
          setState(() {
            _expanded = val;
          });
        },
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Checkbox(
          value: widget.task.completed,
          onChanged: widget.onToggle,
          shape: const CircleBorder(),
          activeColor: Theme.of(context).colorScheme.primary,
        ),
        title: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _getPriorityColor(widget.task.priority),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.task.title,
                style: TextStyle(
                  decoration: widget.task.completed
                      ? TextDecoration.lineThrough
                      : null,
                  color: widget.task.completed
                      ? Theme.of(context).colorScheme.onSurfaceVariant
                      : Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.task.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                widget.task.description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _buildChip(context, widget.task.category, LucideIcons.tag),
                if (widget.task.deadline != null)
                  _buildChip(
                    context,
                    DateFormat('MMM d, yyyy').format(widget.task.deadline!),
                    LucideIcons.calendar,
                    color: isOverdue
                        ? Theme.of(context).colorScheme.error
                        : null,
                  ),
                if (totalSubtasks > 0)
                  _buildChip(
                    context,
                    '$completedSubtasks/$totalSubtasks',
                    LucideIcons.listTodo,
                  ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(LucideIcons.clock),
              tooltip: 'Focus Mode',
              onPressed: widget.onFocus,
              color: Theme.of(context).colorScheme.primary,
            ),
            PopupMenuButton<String>(
              icon: const Icon(LucideIcons.moreVertical),
              onSelected: (value) {
                if (value == 'edit') widget.onEdit();
                if (value == 'delete') widget.onDelete();
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(LucideIcons.edit3, size: 16),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(LucideIcons.trash2, size: 16, color: Colors.red),
                      const SizedBox(width: 8),
                      const Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        children: [
          if (widget.task.subtasks.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Column(
                children: widget.task.subtasks.map((subtask) {
                  return CheckboxListTile(
                    title: Text(
                      subtask.title,
                      style: TextStyle(
                        decoration: subtask.completed
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    value: subtask.completed,
                    onChanged: (val) {
                      final updatedSubtask = subtask.copyWith(completed: val);
                      widget.onSubtaskToggle(updatedSubtask);
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    dense: true,
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChip(
    BuildContext context,
    String label,
    IconData icon, {
    Color? color,
  }) {
    final chipColor = color ?? Theme.of(context).colorScheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: chipColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: chipColor),
          ),
        ],
      ),
    );
  }
}
