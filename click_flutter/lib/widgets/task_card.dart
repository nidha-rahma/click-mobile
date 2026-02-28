import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/task.dart';
import '../theme/app_theme.dart';
import 'app_widgets.dart';

class TaskCard extends StatefulWidget {
  final Task task;
  final ValueChanged<bool?> onToggle;
  final VoidCallback onTap;
  final VoidCallback onFocus;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<Subtask> onSubtaskToggle;

  const TaskCard({
    super.key,
    required this.task,
    required this.onToggle,
    required this.onTap,
    required this.onFocus,
    required this.onEdit,
    required this.onDelete,
    required this.onSubtaskToggle,
  });

  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard> {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final task = widget.task;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.onSurface.withValues(alpha: 0.1)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Checkbox
            GestureDetector(
              onTap: () => widget.onToggle(!task.completed),
              child: Container(
                width: 22,
                height: 22,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: task.completed
                        ? AppTheme.primaryLight
                        : cs.onSurface.withValues(alpha: 0.4),
                    width: 2,
                  ),
                  color: task.completed
                      ? AppTheme.primaryLight
                      : Colors.transparent,
                ),
                child: task.completed
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(width: 16),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          task.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface,
                            decoration: task.completed
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                      ),
                      // Action icons
                      _ActionIcon(
                        icon: LucideIcons.clock,
                        onTap: widget.onFocus,
                      ),
                      const SizedBox(width: 14),
                      _ActionIcon(
                        icon: LucideIcons.edit3,
                        onTap: widget.onEdit,
                      ),
                      const SizedBox(width: 14),
                      _ActionIcon(
                        icon: LucideIcons.trash2,
                        onTap: widget.onDelete,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      AppWidgets.chip(
                        context: context,
                        icon: LucideIcons.tag,
                        label: task.category,
                      ),
                      if (task.deadline != null) ...[
                        const SizedBox(width: 10),
                        _DeadlineChip(deadline: task.deadline!),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tiny icon button used in the task card action row.
class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _ActionIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(
        icon,
        size: 18,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }
}

/// Shows time-remaining for a task deadline with semantic colour.
class _DeadlineChip extends StatelessWidget {
  final DateTime deadline;
  const _DeadlineChip({required this.deadline});

  @override
  Widget build(BuildContext context) {
    final diff = deadline.difference(DateTime.now());
    final color = AppWidgets.deadlineColor(diff);
    final label = AppWidgets.deadlineLabel(diff);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(LucideIcons.clock, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }
}
