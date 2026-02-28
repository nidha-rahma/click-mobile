import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/task.dart';

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
    final hasSubtasks = widget.task.subtasks.isNotEmpty;

    return GestureDetector(
      onTap: () {
        if (hasSubtasks) {
          setState(() {
            _expanded = !_expanded;
          });
        } else {
          widget.onToggle(!widget.task.completed);
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF13151A), // Dark surface color matching image
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.05),
            width: 1,
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
                      shape: BoxShape.circle,
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
                                    ? Colors.white54
                                    : Colors.white,
                            
                              ),
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                onTap: widget.onFocus,
                                child: const Icon(
                                  LucideIcons.clock,
                                  size: 18,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                              const SizedBox(width: 16),
                              GestureDetector(
                                onTap: widget.onEdit,
                                child: const Icon(
                                  LucideIcons.edit3,
                                  size: 18,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                              const SizedBox(width: 16),
                              GestureDetector(
                                onTap: widget.onDelete,
                                child: const Icon(
                                  LucideIcons.trash2,
                                  size: 18,
                                  color: Color(0xFF94A3B8),
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
                              color: Colors.white.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              widget.task.category,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFE2E8F0),
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
            if (_expanded && hasSubtasks) ...[
              const SizedBox(height: 16),
              const Divider(color: Colors.white10, height: 1),
              const SizedBox(height: 8),
              ...widget.task.subtasks.map((subtask) {
                return CheckboxListTile(
                  title: Text(
                    subtask.title,
                    style: TextStyle(
                      color: Colors.white70,
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
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  activeColor: const Color(0xFF10B981),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}
