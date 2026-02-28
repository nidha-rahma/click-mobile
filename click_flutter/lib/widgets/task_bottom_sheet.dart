import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:uuid/uuid.dart';
import '../models/task.dart';
import '../services/transcript_parser.dart';
import '../services/voice_input_service.dart';
import '../theme/app_theme.dart';
import 'app_widgets.dart';

class TaskBottomSheet extends StatefulWidget {
  final Task? existingTask;
  final Function(Task) onSave;

  const TaskBottomSheet({super.key, this.existingTask, required this.onSave});

  @override
  State<TaskBottomSheet> createState() => _TaskBottomSheetState();
}

class _TaskBottomSheetState extends State<TaskBottomSheet>
    with SingleTickerProviderStateMixin {
  // Form controllers
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _notesController = TextEditingController();

  Priority _selectedPriority = Priority.medium;
  String _selectedCategory = 'Study';
  DateTime? _selectedDate;

  // Voice service
  late final VoiceInputService _voice;

  // Pulse animation (owned here so we can sync it with _voice.isListening)
  late final AnimationController _pulse;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();

    // Pre-fill when editing
    final t = widget.existingTask;
    if (t != null) {
      _titleController.text = t.title;
      _descController.text = t.description;
      _notesController.text = t.notes;
      _selectedPriority = t.priority;
      _selectedCategory = t.category;
      _selectedDate = t.deadline;
    }

    // Pulse animation
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulseAnim = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));

    // Voice service
    _voice = VoiceInputService();
    _voice.addListener(_onVoiceChanged);
    _voice.initialize(
      onPermanentError: (msg) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Voice error: $msg'),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      },
    );
  }

  /// Sync animation and title field whenever VoiceInputService notifies.
  void _onVoiceChanged() {
    if (!mounted) return;

    if (_voice.isListening) {
      if (!_pulse.isAnimating) _pulse.repeat(reverse: true);
      // Only overwrite the title while actually recording
      final words = _voice.liveTranscript;
      if (words != _titleController.text) {
        _titleController.text = words;
        _titleController.selection = TextSelection.fromPosition(
          TextPosition(offset: words.length),
        );
      }
    } else {
      _pulse.stop();
      _pulse.reset();
    }

    setState(() {}); // rebuild for mic button + transcript card
  }

  Future<void> _toggleMic() async {
    if (_voice.isListening) {
      final transcript = await _voice.stopListening();
      if (transcript.isNotEmpty) _applyTranscript(transcript);
    } else {
      await _voice.startListening();
    }
  }

  void _applyTranscript(String transcript) {
    final result = TranscriptParser.parse(transcript);
    setState(() {
      _titleController.text = result.title;
      _titleController.selection = TextSelection.fromPosition(
        TextPosition(offset: result.title.length),
      );
      if (result.priority != null) _selectedPriority = result.priority!;
      if (result.deadline != null) _selectedDate = result.deadline!;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _notesController.dispose();
    _pulse.dispose();
    _voice.removeListener(_onVoiceChanged);
    _voice.dispose();
    super.dispose();
  }

  // ── Date picker ──────────────────────────────────────────────────────────

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (date == null || !mounted) return;

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

  // ── Submit ───────────────────────────────────────────────────────────────

  void _submit() {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Title is required')));
      return;
    }
    widget.onSave(
      Task(
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
      ),
    );
    Navigator.of(context).pop();
  }

  // ── Build helpers ────────────────────────────────────────────────────────

  Widget _buildMicButton() {
    if (!_voice.speechEnabled) {
      return Container(
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
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (_, child) => Transform.scale(
        scale: _voice.isListening ? _pulseAnim.value : 1.0,
        child: child,
      ),
      child: GestureDetector(
        onTap: _toggleMic,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _voice.isListening
                ? AppTheme.voiceAccent.withValues(alpha: 0.15)
                : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _voice.isListening
                  ? AppTheme.voiceAccent
                  : Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.1),
            ),
          ),
          child: Icon(
            _voice.isListening ? Icons.mic_off : Icons.mic,
            size: 20,
            color: _voice.isListening
                ? AppTheme.voiceAccent
                : Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  Widget _buildTranscriptCard() {
    if (!_voice.isListening) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: AnimatedBuilder(
        animation: _pulseAnim,
        builder: (_, child) => Opacity(
          opacity: ((_pulseAnim.value - 1.0) / 0.3).clamp(0.6, 1.0),
          child: child,
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.voiceAccent.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppTheme.voiceAccent.withValues(alpha: 0.4),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.mic, size: 16, color: AppTheme.voiceAccent),
                  const SizedBox(width: 6),
                  const Text(
                    'Listening',
                    style: TextStyle(
                      color: AppTheme.voiceAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _voice.liveTranscript.isEmpty
                    ? 'Start speaking…'
                    : _voice.liveTranscript,
                style: TextStyle(
                  color: _voice.liveTranscript.isEmpty
                      ? AppTheme.voiceAccent.withValues(alpha: 0.5)
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
    );
  }

  Widget _buildPriorityDropdown() {
    return AppWidgets.formCard(
      child: DropdownButtonHideUnderline(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: DropdownButton<Priority>(
            value: _selectedPriority,
            icon: const Icon(LucideIcons.chevronDown, size: 16),
            isExpanded: true,
            items: Priority.values.map((p) {
              final color = AppWidgets.priorityColor(p);
              return DropdownMenuItem(
                value: p,
                child: Row(
                  children: [
                    Icon(LucideIcons.flag, size: 16, color: color),
                    const SizedBox(width: 12),
                    Text(
                      AppWidgets.priorityLabel(p),
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (v) {
              if (v != null) setState(() => _selectedPriority = v);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return AppWidgets.formCard(
      child: DropdownButtonHideUnderline(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: DropdownButton<String>(
            value: _selectedCategory,
            icon: const Icon(LucideIcons.chevronDown, size: 16),
            isExpanded: true,
            items: AppConstants.categories
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => _selectedCategory = v);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDeadlinePicker() {
    return AppWidgets.formCard(
      child: ListTile(
        leading: const Icon(LucideIcons.calendar, size: 20),
        title: Text(
          _selectedDate == null
              ? 'dd/mm/yyyy --:-- --'
              : DateFormat('MMM d, yyyy h:mm a').format(_selectedDate!),
          style: TextStyle(
            color: _selectedDate == null
                ? Theme.of(context).colorScheme.onSurfaceVariant
                : null,
          ),
        ),
        trailing: const Icon(LucideIcons.maximize, size: 16),
        onTap: _pickDate,
      ),
    );
  }

  // ── Main build ───────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
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
              // Header
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

              // Title + mic
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: cs.primary, width: 1.5),
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
                  _buildMicButton(),
                ],
              ),

              // Live transcript card
              _buildTranscriptCard(),

              const SizedBox(height: 16),

              // Description
              AppWidgets.formTextField(
                controller: _descController,
                hint: 'Description (optional)',
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // Priority + Category
              Row(
                children: [
                  Expanded(child: _buildPriorityDropdown()),
                  const SizedBox(width: 16),
                  Expanded(child: _buildCategoryDropdown()),
                ],
              ),
              const SizedBox(height: 16),

              // Deadline
              _buildDeadlinePicker(),
              const SizedBox(height: 16),

              // Notes
              AppWidgets.formTextField(
                controller: _notesController,
                hint: 'Notes (optional)',
                maxLines: 3,
              ),
              const SizedBox(height: 32),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: cs.onSurface.withValues(alpha: 0.2),
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
                        backgroundColor: cs.primary,
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
