import '../models/task.dart';

/// Result of parsing a voice transcript.
class TranscriptResult {
  final String title;
  final Priority? priority; // null = no change
  final DateTime? deadline; // null = no change

  const TranscriptResult({required this.title, this.priority, this.deadline});
}

/// Stateless NLP parser that extracts task metadata from a spoken transcript.
/// Has zero Flutter/widget dependencies — fully unit-testable.
class TranscriptParser {
  TranscriptParser._();

  static const Map<String, int> _weekdays = {
    'monday': DateTime.monday,
    'tuesday': DateTime.tuesday,
    'wednesday': DateTime.wednesday,
    'thursday': DateTime.thursday,
    'friday': DateTime.friday,
    'saturday': DateTime.saturday,
    'sunday': DateTime.sunday,
  };

  /// Parses [transcript] and returns a [TranscriptResult] with extracted fields.
  /// Keywords detected are stripped from the returned [TranscriptResult.title].
  static TranscriptResult parse(String transcript) {
    if (transcript.trim().isEmpty) {
      return const TranscriptResult(title: '');
    }

    final lower = transcript.toLowerCase().trim();
    String title = transcript.trim();
    Priority? priority;
    DateTime? deadline;

    // ── Priority ────────────────────────────────────────────────────────
    if (RegExp(r'\b(urgent|high priority|important)\b').hasMatch(lower)) {
      priority = Priority.high;
      title = title
          .replaceAll(RegExp(r'\burgent\b', caseSensitive: false), '')
          .replaceAll(RegExp(r'\bhigh priority\b', caseSensitive: false), '')
          .replaceAll(RegExp(r'\bimportant\b', caseSensitive: false), '');
    } else if (RegExp(r'\blow priority\b').hasMatch(lower)) {
      priority = Priority.low;
      title = title.replaceAll(
        RegExp(r'\blow priority\b', caseSensitive: false),
        '',
      );
    }

    // ── Deadline ─────────────────────────────────────────────────────────
    // Order matters: check longer phrases before shorter substrings.
    final now = DateTime.now();

    if (RegExp(r'\btoday\b').hasMatch(lower)) {
      deadline = DateTime(now.year, now.month, now.day);
      title = title.replaceAll(RegExp(r'\btoday\b', caseSensitive: false), '');
    } else if (RegExp(r'\bday after tomorrow\b').hasMatch(lower)) {
      final d = now.add(const Duration(days: 2));
      deadline = DateTime(d.year, d.month, d.day);
      title = title.replaceAll(
        RegExp(r'\bday after tomorrow\b', caseSensitive: false),
        '',
      );
    } else if (RegExp(r'\btomorrow\b').hasMatch(lower)) {
      final d = now.add(const Duration(days: 1));
      deadline = DateTime(d.year, d.month, d.day);
      title = title.replaceAll(
        RegExp(r'\btomorrow\b', caseSensitive: false),
        '',
      );
    } else {
      // "next <weekday>"
      final match = RegExp(
        r'\bnext (monday|tuesday|wednesday|thursday|friday|saturday|sunday)\b',
      ).firstMatch(lower);
      if (match != null) {
        final dayName = match.group(1)!;
        final target = _weekdays[dayName]!;
        var ahead = target - now.weekday;
        if (ahead <= 0) ahead += 7;
        final d = now.add(Duration(days: ahead));
        deadline = DateTime(d.year, d.month, d.day);
        title = title.replaceAll(
          RegExp(
            r'\bnext (monday|tuesday|wednesday|thursday|friday|saturday|sunday)\b',
            caseSensitive: false,
          ),
          '',
        );
      }
    }

    // ── Clean title ───────────────────────────────────────────────────────
    title = title.replaceAll(RegExp(r'\s+'), ' ').trim();

    return TranscriptResult(
      title: title,
      priority: priority,
      deadline: deadline,
    );
  }
}
