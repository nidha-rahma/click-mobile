import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class StatsCard extends StatelessWidget {
  final String title;
  final String value;
  final Widget icon;

  const StatsCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6.0),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.05),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).scaffoldBackgroundColor.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: icon,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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

class StatsBar extends StatelessWidget {
  final int doneToday;
  final int totalToday;
  final int totalPending;
  final int doneThisWeek;
  final int totalThisWeek;
  final int streak;

  const StatsBar({
    super.key,
    required this.doneToday,
    required this.totalToday,
    required this.totalPending,
    required this.doneThisWeek,
    required this.totalThisWeek,
    required this.streak,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            StatsCard(
              title: "Done Today",
              value: "$doneToday/$totalToday",
              icon: const Icon(
                LucideIcons.checkCircle2,
                color: Color(0xFF10B981),
                size: 20,
              ),
            ),
            StatsCard(
              title: "Pending",
              value: "$totalPending",
              icon: const Icon(
                LucideIcons.clock,
                color: Color(0xFFF59E0B),
                size: 20,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            StatsCard(
              title: "This Week",
              value: "$doneThisWeek/$totalThisWeek",
              icon: const Icon(
                LucideIcons.trendingUp,
                color: Color(0xFF10B981),
                size: 20,
              ),
            ),
            StatsCard(
              title: "Streak",
              value: "${streak}d",
              icon: const Icon(
                LucideIcons.flame,
                color: Color(0xFFEF4444),
                size: 20,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
