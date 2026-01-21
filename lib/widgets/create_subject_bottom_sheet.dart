import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/subject_model.dart';
import '../providers/app_providers.dart';
import '../utils/blurred_dialog_utils.dart';

void showCreateSubjectDialog(BuildContext context, [String? parentId]) {
  showBlurredDialog(
    context: context,
    builder: (context) => CreateSubjectDialog(parentId: parentId),
  );
}

class CreateSubjectDialog extends ConsumerStatefulWidget {
  final String? parentId;

  const CreateSubjectDialog({
    super.key,
    this.parentId,
  });

  @override
  ConsumerState<CreateSubjectDialog> createState() => _CreateSubjectDialogState();
}

class _CreateSubjectDialogState extends ConsumerState<CreateSubjectDialog> {
  final _nameController = TextEditingController();
  bool _isCreating = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _createSubject() async {
    if (_nameController.text.trim().isEmpty) return;
    
    setState(() => _isCreating = true);
    
    try {
      final subject = SubjectModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        createdDate: DateTime.now(),
        parentId: widget.parentId,
      );
      
      await ref.read(subjectsProvider.notifier).addSubject(subject);
      
      if (mounted) {
        Navigator.pop(context);
      }
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSubFolder = widget.parentId != null;
    
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isSubFolder ? 'Create Sub-Folder' : 'Create Folder',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _nameController,
            autofocus: true,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            decoration: InputDecoration(
              labelText: 'Folder Name',
              labelStyle: const TextStyle(color: Colors.white70),
              hintText: 'e.g., Notes, PDFs',
              hintStyle: const TextStyle(color: Colors.white38),
              filled: true,
              fillColor: const Color(0xFF2C2C2C),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Colors.white, width: 2),
              ),
            ),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _createSubject(),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white70,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text('Cancel', style: TextStyle(fontSize: 16)),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _isCreating ? null : _createSubject,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: _isCreating
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                      )
                    : Text(
                        isSubFolder ? 'Create' : 'Create',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
