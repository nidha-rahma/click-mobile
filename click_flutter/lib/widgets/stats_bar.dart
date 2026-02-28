import 'package:flutter/material.dart';

class StatsCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;

  const StatsCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle = '',
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 4.0),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(subtitle, style: Theme.of(context).textTheme.labelSmall),
              ],
            ],
          ),
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
    return Row(
      children: [
        StatsCard(
          title: "Done Today",
          value: "$doneToday",
          subtitle: "of $totalToday",
        ),
        StatsCard(title: "Pending", value: "$totalPending"),
        StatsCard(
          title: "This Week",
          value: "$doneThisWeek",
          subtitle: "of $totalThisWeek",
        ),
        StatsCard(title: "Streak", value: "$streak", subtitle: "days"),
      ],
    );
  }
}
