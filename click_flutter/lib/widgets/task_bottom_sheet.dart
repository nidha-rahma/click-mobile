import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:uuid/uuid.dart';
import '../models/task.dart';

class TaskBottomSheet extends StatefulWidget {
  final Task? existingTask;
  final Function(Task) onSave;

  const TaskBottomSheet({super.key, this.existingTask, required this.onSave});

  @override
  State<TaskBottomSheet> createState() => _TaskBottomSheetState();
}

class _TaskBottomSheetState extends State<TaskBottomSheet>
    with SingleTickerProviderStateMixin {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _notesController = TextEditingController();

  Priority _selectedPriority = Priority.medium;
  String _selectedCategory = 'Study';
  DateTime? _selectedDate;

  // Voice input state
  final SpeechToText _speech = SpeechToText();
  bool _isListening = false;
  bool _speechEnabled = false;
  String _liveTranscript = ''; // shown in UI (accumulated + current)
  String _accumulatedTranscript = ''; // words confirmed from previous sessions

  // Pulsing animation
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    if (widget.existingTask != null) {
      _titleController.text = widget.existingTask!.title;
      _descController.text = widget.existingTask!.description;
      _notesController.text = widget.existingTask!.notes;
      _selectedPriority = widget.existingTask!.priority;
      _selectedCategory = widget.existingTask!.category;
      _selectedDate = widget.existingTask!.deadline;
    }

    // Set up pulsing animation controller
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Initialize speech recognition
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    final available = await _speech.initialize(
      onError: (error) {
        // Only surface permanent errors; transient ones are ignored so the
        // continuous loop can recover on the next restart.
        if (!mounted || !error.permanent) return;
        _pulseController.stop();
        _pulseController.reset();
        setState(() {
          _isListening = false;
          _liveTranscript = '';
          _accumulatedTranscript = '';
        });
        final msg = error.errorMsg.isNotEmpty
            ? error.errorMsg
            : 'Speech recognition failed';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Voice input error: $msg'),
            duration: const Duration(seconds: 3),
          ),
        );
      },
      onStatus: (status) {
        // When the recognizer stops naturally ('done' or 'doneNoResult') but
        // the user hasn't tapped to stop, restart so recording continues.
        if (!mounted || !_isListening) return;
        if (status == 'done' || status == 'doneNoResult') {
          _restartListening();
        }
      },
    );
    if (mounted) {
      setState(() => _speechEnabled = available);
    }
  }

  Future<void> _startListening() async {
    setState(() {
      _isListening = true;
      _liveTranscript = '';
      _accumulatedTranscript = ''; // fresh session
    });
    _pulseController.repeat(reverse: true);
    await _listenOnce();
  }

  /// Starts (or restarts) a single recognition window.
  /// Combines [_accumulatedTranscript] with the current partial result in the UI.
  Future<void> _listenOnce() async {
    if (!mounted || !_isListening) return;
    await _speech.listen(
      onResult: (result) {
        if (!mounted || !_isListening) return;

        // Build the display string: confirmed words + current partial words
        final prefix = _accumulatedTranscript.isEmpty
            ? ''
            : '$_accumulatedTranscript ';
        final full = (prefix + result.recognizedWords).trim();

        setState(() {
          _liveTranscript = full;
          _titleController.text = full;
          _titleController.selection = TextSelection.fromPosition(
            TextPosition(offset: full.length),
          );
        });

        if (result.finalResult) {
          // Commit these words and restart — do NOT stop.
          _accumulatedTranscript = full;
          // _restartListening is called by onStatus 'done' so no need here.
        }
      },
      listenOptions: SpeechListenOptions(
        cancelOnError: false, // keep going on transient errors
        partialResults: true,
      ),
    );
  }

  /// Restarts the recognizer after a natural pause, keeping words accumulated.
  Future<void> _restartListening() async {
    if (!mounted || !_isListening) return;
    await _listenOnce();
  }

  /// Called when the user **manually taps** the mic button to stop.
  Future<void> _stopListening() async {
    if (!_isListening) return;
    // Capture the full accumulated transcript before clearing state
    final lastTranscript = _liveTranscript;
    // Mark stopped FIRST so any stale onResult / onStatus callbacks are ignored
    setState(() {
      _isListening = false;
      _liveTranscript = '';
      _accumulatedTranscript = '';
    });
    _pulseController.stop();
    _pulseController.reset();
    await _speech.stop();
    if (lastTranscript.isNotEmpty) {
      _parseTranscript(lastTranscript);
    }
  }

  /// Parses the spoken transcript to extract priority, deadline, and title.
  /// Mirrors the logic from the React web app's useVoiceInput hook.
  void _parseTranscript(String transcript) {
    final lower = transcript.toLowerCase().trim();
    String title = transcript.trim();

    // ── Priority detection ──────────────────────────────────────────────
    if (RegExp(r'\b(urgent|high priority|important)\b').hasMatch(lower)) {
      setState(() => _selectedPriority = Priority.high);
      title = title
          .replaceAll(RegExp(r'\burgent\b', caseSensitive: false), '')
          .replaceAll(RegExp(r'\bhigh priority\b', caseSensitive: false), '')
          .replaceAll(RegExp(r'\bimportant\b', caseSensitive: false), '');
    } else if (RegExp(r'\blow priority\b').hasMatch(lower)) {
      setState(() => _selectedPriority = Priority.low);
      title = title.replaceAll(
        RegExp(r'\blow priority\b', caseSensitive: false),
        '',
      );
    }

    // ── Deadline detection ──────────────────────────────────────────────
    final now = DateTime.now();

    if (RegExp(r'\btoday\b').hasMatch(lower)) {
      setState(() => _selectedDate = DateTime(now.year, now.month, now.day));
      title = title.replaceAll(RegExp(r'\btoday\b', caseSensitive: false), '');
    } else if (RegExp(r'\bday after tomorrow\b').hasMatch(lower)) {
      final dayAfterTomorrow = now.add(const Duration(days: 2));
      setState(
        () => _selectedDate = DateTime(
          dayAfterTomorrow.year,
          dayAfterTomorrow.month,
          dayAfterTomorrow.day,
        ),
      );
      title = title.replaceAll(
        RegExp(r'\bday after tomorrow\b', caseSensitive: false),
        '',
      );
    } else if (RegExp(r'\btomorrow\b').hasMatch(lower)) {
      final tomorrow = now.add(const Duration(days: 1));
      setState(
        () => _selectedDate = DateTime(
          tomorrow.year,
          tomorrow.month,
          tomorrow.day,
        ),
      );
      title = title.replaceAll(
        RegExp(r'\btomorrow\b', caseSensitive: false),
        '',
      );
    } else {
      // "next <weekday>"
      final weekdayMatch = RegExp(
        r'\bnext (monday|tuesday|wednesday|thursday|friday|saturday|sunday)\b',
      ).firstMatch(lower);
      if (weekdayMatch != null) {
        final weekdayName = weekdayMatch.group(1)!;
        const weekdays = {
          'monday': DateTime.monday,
          'tuesday': DateTime.tuesday,
          'wednesday': DateTime.wednesday,
          'thursday': DateTime.thursday,
          'friday': DateTime.friday,
          'saturday': DateTime.saturday,
          'sunday': DateTime.sunday,
        };
        final targetWeekday = weekdays[weekdayName]!;
        var daysAhead = targetWeekday - now.weekday;
        if (daysAhead <= 0) daysAhead += 7; // always go forward
        final targetDate = now.add(Duration(days: daysAhead));
        setState(
          () => _selectedDate = DateTime(
            targetDate.year,
            targetDate.month,
            targetDate.day,
          ),
        );
        title = title.replaceAll(
          RegExp(
            r'\bnext (monday|tuesday|wednesday|thursday|friday|saturday|sunday)\b',
            caseSensitive: false,
          ),
          '',
        );
      }
    }

    // ── Clean up title ──────────────────────────────────────────────────
    // Remove multiple spaces/leading-trailing whitespace
    title = title.replaceAll(RegExp(r'\s+'), ' ').trim();

    setState(() {
      _titleController.text = title;
      _titleController.selection = TextSelection.fromPosition(
        TextPosition(offset: title.length),
      );
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _notesController.dispose();
    _pulseController.dispose();
    _speech.cancel();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );

    if (date != null) {
      if (!mounted) return;

      final time = await showTimePicker(
        context: context,
        initialTime: _selectedDate != null
            ? TimeOfDay.fromDateTime(_selectedDate!)
            : TimeOfDay.now(),
      );

      if (time != null) {
        setState(() {
          _selectedDate = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  void _submit() {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Title is required')));
      return;
    }

    final task = Task(
      id: widget.existingTask?.id ?? const Uuid().v4(),
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      notes: _notesController.text.trim(),
      priority: _selectedPriority,
      category: _selectedCategory,
      deadline: _selectedDate,
      createdAt: widget.existingTask?.createdAt ?? DateTime.now(),
      completed: widget.existingTask?.completed ?? false,
      completedAt: widget.existingTask?.completedAt,
      subtasks: widget.existingTask?.subtasks ?? [],
    );

    widget.onSave(task);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header ─────────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.existingTask == null ? 'New Task' : 'Edit Task',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.x, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Title row with mic button ───────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary,
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextField(
                        controller: _titleController,
                        autofocus: widget.existingTask == null,
                        decoration: const InputDecoration(
                          hintText: 'Task title...',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Mic button — shown only when speech is available
                  if (_speechEnabled)
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _isListening ? _pulseAnimation.value : 1.0,
                          child: child,
                        );
                      },
                      child: GestureDetector(
                        onTap: () {
                          if (_isListening) {
                            _stopListening();
                          } else {
                            _startListening();
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _isListening
                                ? const Color(
                                    0xFF22C55E,
                                  ).withValues(alpha: 0.15)
                                : Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _isListening
                                  ? const Color(0xFF22C55E)
                                  : Theme.of(context).colorScheme.onSurface
                                        .withValues(alpha: 0.1),
                            ),
                          ),
                          child: Icon(
                            _isListening ? Icons.mic_off : Icons.mic,
                            size: 20,
                            color: _isListening
                                ? const Color(0xFF22C55E)
                                : Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                    )
                  else
                    // Fallback static container if speech not available
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Icon(
                        Icons.mic_off,
                        size: 20,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.3),
                      ),
                    ),
                ],
              ),

              // ── Live transcript card (visible while listening) ──────────
              if (_isListening)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) => Opacity(
                      opacity: _isListening
                          ? ((_pulseAnimation.value - 1.0) / 0.3).clamp(
                              0.6,
                              1.0,
                            )
                          : 1.0,
                      child: child,
                    ),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF22C55E).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFF22C55E).withValues(alpha: 0.4),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header row with pulsing mic icon
                          Row(
                            children: [
                              const Icon(
                                Icons.mic,
                                size: 16,
                                color: Color(0xFF22C55E),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'Listening',
                                style: TextStyle(
                                  color: Color(0xFF22C55E),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Live transcript text — wraps fully, no truncation
                          Text(
                            _liveTranscript.isEmpty
                                ? 'Start speaking…'
                                : _liveTranscript,
                            style: TextStyle(
                              color: _liveTranscript.isEmpty
                                  ? const Color(
                                      0xFF22C55E,
                                    ).withValues(alpha: 0.5)
                                  : Theme.of(context).colorScheme.onSurface,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 16),

              // ── Description ─────────────────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.1),
                  ),
                ),
                child: TextField(
                  controller: _descController,
                  decoration: const InputDecoration(
                    hintText: 'Description (optional)',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(16),
                  ),
                  maxLines: 3,
                ),
              ),
              const SizedBox(height: 16),

              // ── Priority & Category dropdowns ───────────────────────────
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.1),
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<Priority>(
                          value: _selectedPriority,
                          icon: const Icon(LucideIcons.chevronDown, size: 16),
                          items: Priority.values.map((p) {
                            Color color = Colors.white;
                            if (p == Priority.high) {
                              color = const Color(0xFFEF4444);
                            }
                            if (p == Priority.medium) {
                              color = const Color(0xFFF59E0B);
                            }
                            if (p == Priority.low) {
                              color = const Color(0xFF3B82F6);
                            }

                            return DropdownMenuItem(
                              value: p,
                              child: Row(
                                children: [
                                  Icon(
                                    LucideIcons.flag,
                                    size: 16,
                                    color: color,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    p.name[0].toUpperCase() +
                                        p.name.substring(1),
                                    style: TextStyle(
                                      color: color,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedPriority = val);
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.1),
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedCategory,
                          icon: const Icon(LucideIcons.chevronDown, size: 16),
                          items: AppConstants.categories.map((c) {
                            return DropdownMenuItem(value: c, child: Text(c));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedCategory = val);
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Deadline picker ─────────────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.1),
                  ),
                ),
                child: ListTile(
                  leading: const Icon(LucideIcons.calendar, size: 20),
                  title: Text(
                    _selectedDate == null
                        ? 'dd/mm/yyyy --:-- --'
                        : DateFormat(
                            'MMM d, yyyy h:mm a',
                          ).format(_selectedDate!),
                    style: TextStyle(
                      color: _selectedDate == null
                          ? Theme.of(context).colorScheme.onSurfaceVariant
                          : null,
                    ),
                  ),
                  trailing: const Icon(LucideIcons.maximize, size: 16),
                  onTap: _pickDate,
                ),
              ),
              const SizedBox(height: 16),

              // ── Notes ───────────────────────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.1),
                  ),
                ),
                child: TextField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    hintText: 'Notes (optional)',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(16),
                  ),
                  maxLines: 3,
                ),
              ),
              const SizedBox(height: 32),

              // ── Action buttons ──────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.2),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        widget.existingTask == null
                            ? 'Create Task'
                            : 'Save Changes',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
