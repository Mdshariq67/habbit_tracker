import 'package:flutter/material.dart';

class HabitDialogResult {
  const HabitDialogResult({required this.title, required this.description});

  final String title;
  final String description;
}

/// Shows a dialog for creating or editing a habit.
/// Returns [HabitDialogResult] or `null` if cancelled.
Future<HabitDialogResult?> showAddHabitDialog(
  BuildContext context, {
  String? initialTitle,
  String? initialDescription,
}) {
  final isEditing = initialTitle != null;
  return showDialog<HabitDialogResult>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: false,
    builder: (dialogContext) => _AddHabitDialog(
      isEditing: isEditing,
      initialTitle: initialTitle ?? '',
      initialDescription: initialDescription ?? '',
    ),
  );
}

class _AddHabitDialog extends StatefulWidget {
  const _AddHabitDialog({
    required this.isEditing,
    required this.initialTitle,
    required this.initialDescription,
  });

  final bool isEditing;
  final String initialTitle;
  final String initialDescription;

  @override
  State<_AddHabitDialog> createState() => _AddHabitDialogState();
}

class _AddHabitDialogState extends State<_AddHabitDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
    _descController = TextEditingController(text: widget.initialDescription);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _submit() {
    final raw = _titleController.text.trim();
    if (raw.isEmpty) {
      setState(() => _errorText = 'Enter a title');
      return;
    }
    Navigator.of(context).pop(
      HabitDialogResult(
        title: raw,
        description: _descController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.isEditing ? 'Edit habit' : 'New habit'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            key: const Key('add-habit-title-field'),
            controller: _titleController,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: 'Title',
              errorText: _errorText,
            ),
            onChanged: (_) {
              if (_errorText != null) setState(() => _errorText = null);
            },
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('add-habit-desc-field'),
            controller: _descController,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Description (optional)',
            ),
            maxLines: 2,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const Key('add-habit-submit'),
          onPressed: _submit,
          child: Text(widget.isEditing ? 'Save' : 'Add'),
        ),
      ],
    );
  }
}
