import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/task.dart';
import 'app_widgets.dart';

class TaskDetails extends StatelessWidget {
  final Task task;

  const TaskDetails({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    task.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(LucideIcons.x),
                ),
              ],
            ),
            Divider(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.1),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                AppWidgets.chip(
                  context: context,
                  icon: LucideIcons.tag,
                  label: task.category,
                ),
              ],
            ),
            if (task.description.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Description',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: double.infinity,
                child: Text(
                  task.description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
