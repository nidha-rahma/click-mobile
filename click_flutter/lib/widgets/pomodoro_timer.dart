import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class PomodoroTimer extends StatefulWidget {
  final String taskId;
  final VoidCallback? onClose;

  const PomodoroTimer({super.key, required this.taskId, this.onClose});

  @override
  State<PomodoroTimer> createState() => _PomodoroTimerState();
}

class _PomodoroTimerState extends State<PomodoroTimer> {
  static const int defaultTime = 25 * 60; // 25 minutes
  int _secondsRemaining = defaultTime;
  bool _isRunning = false;
  Timer? _timer;

  void _startTimer() {
    setState(() {
      _isRunning = true;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        _stopTimer();
      }
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _secondsRemaining = defaultTime;
    });
  }

  String get _formattedTime {
    int minutes = _secondsRemaining ~/ 60;
    int seconds = _secondsRemaining % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  "Focus Timer",
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(LucideIcons.x),
                  iconSize: 24,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  onPressed: () {
                    if (widget.onClose != null) {
                      widget.onClose!();
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: CircularProgressIndicator(
                    value: _secondsRemaining / defaultTime,
                    strokeWidth: 8,
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                Text(
                  _formattedTime,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!_isRunning && _secondsRemaining > 0)
                  IconButton(
                    icon: const Icon(LucideIcons.play),
                    iconSize: 32,
                    color: Theme.of(context).colorScheme.primary,
                    onPressed: _startTimer,
                  )
                else
                  IconButton(
                    icon: const Icon(LucideIcons.pause),
                    iconSize: 32,
                    color: Theme.of(context).colorScheme.primary,
                    onPressed: _pauseTimer,
                  ),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(LucideIcons.rotateCcw),
                  iconSize: 32,
                  color: Theme.of(context).colorScheme.error,
                  onPressed: _stopTimer,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
