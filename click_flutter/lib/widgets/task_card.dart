import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/task.dart';

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
  Widget _buildTimeLeft(DateTime deadline) {
    final now = DateTime.now();
    final diff = deadline.difference(now);

    Color color = const Color(0xFF94A3B8); // Slate 400
    String text = '';

    if (diff.isNegative) {
      color = const Color(0xFFEF4444); // Red
      text = 'Overdue';
    } else if (diff.inDays == 0) {
      color = const Color(0xFFEF4444); // Red
      final hours = diff.inHours;
      if (hours > 0) {
        text = '${hours}h left';
      } else {
        text = '${diff.inMinutes}m left';
      }
    } else if (diff.inDays == 1) {
      color = const Color(0xFFF59E0B); // Orange
      text = '1d left';
    } else {
      color = const Color(0xFF94A3B8); // Muted
      text = '${diff.inDays}d left';
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(LucideIcons.clock, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => widget.onToggle(!widget.task.completed),
                  child: Container(
                    width: 22,
                    height: 22,
                    margin: const EdgeInsets.only(top: 2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: widget.task.completed
                            ? const Color(0xFF10B981)
                            : const Color(0xFF334155),
                        width: 2,
                      ),
                      color: widget.task.completed
                          ? const Color(0xFF10B981)
                          : Colors.transparent,
                    ),
                    child: widget.task.completed
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              widget.task.title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: widget.task.completed
                                    ? Theme.of(context).colorScheme.onSurface
                                    : Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                onTap: widget.onFocus,
                                child: Icon(
                                  LucideIcons.clock,
                                  size: 18,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(width: 16),
                              GestureDetector(
                                onTap: widget.onEdit,
                                child: Icon(
                                  LucideIcons.edit3,
                                  size: 18,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(width: 16),
                              GestureDetector(
                                onTap: widget.onDelete,
                                child: Icon(
                                  LucideIcons.trash2,
                                  size: 18,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.15),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              widget.task.category,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ),
                          if (widget.task.deadline != null) ...[
                            const SizedBox(width: 12),
                            _buildTimeLeft(widget.task.deadline!),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
