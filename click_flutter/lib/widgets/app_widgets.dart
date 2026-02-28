import 'package:flutter/material.dart';
import '../models/task.dart';
import '../theme/app_theme.dart';

/// Shared, reusable widget building blocks used across the app.
/// Keeps individual widget files lean — import this instead of duplicating code.
class AppWidgets {
  AppWidgets._();

  // ── Form primitives ─────────────────────────────────────────────────────

  /// A rounded card used to wrap form fields and pickers.
  static Widget formCard({required Widget child, EdgeInsets? padding}) {
    return Builder(
      builder: (context) => Container(
        padding: padding,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.1),
          ),
        ),
        child: child,
      ),
    );
  }

  /// A standard text field wrapped inside a [formCard].
  static Widget formTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    bool autofocus = false,
    EdgeInsets contentPadding = const EdgeInsets.all(16),
  }) {
    return formCard(
      child: TextField(
        controller: controller,
        autofocus: autofocus,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hint,
          border: InputBorder.none,
          contentPadding: contentPadding,
        ),
      ),
    );
  }

  /// A small pill chip with icon + label.
  static Widget chip({
    required BuildContext context,
    required IconData icon,
    required String label,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: cs.surface.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: cs.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  // ── Priority helpers ────────────────────────────────────────────────────

  /// Returns the themed color for a [Priority].
  static Color priorityColor(Priority priority) => switch (priority) {
    Priority.high => AppTheme.highPriority,
    Priority.medium => AppTheme.mediumPriority,
    Priority.low => AppTheme.lowPriority,
  };

  /// Returns the capitalized display name for a [Priority].
  static String priorityLabel(Priority priority) =>
      priority.name[0].toUpperCase() + priority.name.substring(1);

  // ── Deadline helpers ────────────────────────────────────────────────────

  /// Returns the time-left color for a deadline [diff].
  static Color deadlineColor(Duration diff) {
    if (diff.isNegative || diff.inDays == 0) return AppTheme.urgentColor;
    if (diff.inDays == 1) return AppTheme.warningColor;
    return AppTheme.mutedColor;
  }

  /// Returns the time-left label for a deadline.
  static String deadlineLabel(Duration diff) {
    if (diff.isNegative) return 'Overdue';
    if (diff.inDays == 0) {
      final hours = diff.inHours;
      return hours > 0 ? '${hours}h left' : '${diff.inMinutes}m left';
    }
    return '${diff.inDays}d left';
  }
}
