import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';
import '../models/document_model.dart';
import '../models/subject_model.dart';
import '../providers/app_providers.dart';
import '../widgets/smart_grouped_card.dart';
import '../widgets/grouped_bottom_sheet_card.dart';
import '../utils/bottom_sheet_utils.dart';
import '../utils/blurred_dialog_utils.dart';
import 'package:uuid/uuid.dart';

class DocumentOptionsBottomSheet extends ConsumerStatefulWidget {
  final DocumentModel document;
  final List<SubjectModel> subjects;

  const DocumentOptionsBottomSheet({
    super.key,
    required this.document,
    required this.subjects,
  });

  @override
  ConsumerState<DocumentOptionsBottomSheet> createState() => _DocumentOptionsBottomSheetState();
}

class _DocumentOptionsBottomSheetState extends ConsumerState<DocumentOptionsBottomSheet> {
  bool _isLoading = false;

  Future<void> _openDocument() async {
    try {
      Navigator.of(context).pop();
      await OpenFilex.open(widget.document.path);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening document: $e')),
        );
      }
    }
  }


  Future<void> _renameDocument() async {
    final documentsNotifier = ref.read(documentsProvider.notifier);
    Navigator.of(context).pop();
    
    final nameController = TextEditingController(text: widget.document.name);
    
    showBlurredDialog(
      context: context,
      builder: (dialogContext) => Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Rename Document',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: nameController,
              autofocus: true,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              decoration: InputDecoration(
                labelText: 'Document Name',
                labelStyle: const TextStyle(color: Colors.white70),
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
              onSubmitted: (_) async {
                if (nameController.text.trim().isNotEmpty) {
                  final updatedDocument = widget.document.copyWith(
                    name: nameController.text.trim(),
                  );
                  await documentsNotifier.updateDocument(updatedDocument);
                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                }
              },
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white70,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: const Text('Cancel', style: TextStyle(fontSize: 16)),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.trim().isNotEmpty) {
                      final updatedDocument = widget.document.copyWith(
                        name: nameController.text.trim(),
                      );
                      await documentsNotifier.updateDocument(updatedDocument);
                      if (dialogContext.mounted) Navigator.pop(dialogContext);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: const Text('Rename', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareDocument() async {
    try {
      Navigator.of(context).pop();
      final file = File(widget.document.path);
      if (await file.exists()) {
        await Share.shareXFiles([XFile(widget.document.path)]);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sharing document: $e')),
        );
      }
    }
  }

  Future<void> _removeDocument() async {
    final documentsNotifier = ref.read(documentsProvider.notifier);
    Navigator.of(context).pop();
    
    showBlurredDialog(
      context: context,
      builder: (dialogContext) => Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Remove Document',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'This will remove the document from the app. The actual file will not be deleted.',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white70,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: const Text('Cancel', style: TextStyle(fontSize: 16)),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () async {
                    await documentsNotifier.deleteDocument(widget.document.id);
                    if (dialogContext.mounted) Navigator.pop(dialogContext);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: const Text('Remove', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Document name - larger text
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 20),
            child: Text(
              widget.document.name,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          
          // Grouped options cards
          GroupedBottomSheetCardList(
            children: [
              GroupedBottomSheetCard(
                position: getGroupedCardPosition(0, 4),
                onTap: _openDocument,
                child: const ListTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  leading: Icon(Icons.open_in_new, color: Colors.white),
                  title: Text('Open Document', style: TextStyle(fontSize: 16)),
                ),
              ),
              GroupedBottomSheetCard(
                position: getGroupedCardPosition(1, 4),
                onTap: _renameDocument,
                child: const ListTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  leading: Icon(Icons.edit, color: Colors.white),
                  title: Text('Rename', style: TextStyle(fontSize: 16)),
                ),
              ),
              GroupedBottomSheetCard(
                position: getGroupedCardPosition(2, 4),
                onTap: _shareDocument,
                child: const ListTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  leading: Icon(Icons.share, color: Colors.white),
                  title: Text('Share', style: TextStyle(fontSize: 16)),
                ),
              ),
              GroupedBottomSheetCard(
                position: getGroupedCardPosition(3, 4),
                onTap: _removeDocument,
                child: const ListTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  leading: Icon(Icons.delete_outline, color: Colors.red),
                  title: Text(
                    'Delete',
                    style: TextStyle(color: Colors.red, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

void showDocumentOptionsBottomSheet(
  BuildContext context,
  DocumentModel document,
  List<SubjectModel> subjects,
) {
  showBouncyBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF2C2C2C),
    builder: (context) => DocumentOptionsBottomSheet(
      document: document,
      subjects: subjects,
    ),
  );
}
