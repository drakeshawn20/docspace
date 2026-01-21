import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../models/subject_model.dart';
import '../providers/app_providers.dart';
import '../widgets/smart_grouped_card.dart';
import '../widgets/grouped_bottom_sheet_card.dart';
import '../utils/bottom_sheet_utils.dart';
import '../utils/blurred_dialog_utils.dart';

import 'package:animations/animations.dart';
import 'package:uuid/uuid.dart';
import '../screens/document_list_screen.dart';

class SubjectOptionsBottomSheet extends ConsumerWidget {
  final SubjectModel subject;

  const SubjectOptionsBottomSheet({
    super.key,
    required this.subject,
  });

  Future<void> _openFolder(BuildContext context, WidgetRef ref) async {
    Navigator.of(context).pop();
    
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            DocumentListScreen(subject: subject),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SharedAxisTransition(
            animation: animation,
            secondaryAnimation: secondaryAnimation,
            transitionType: SharedAxisTransitionType.horizontal,
            fillColor: Colors.black,
            child: child,
          );
        },
      ),
    );
  }


  Future<void> _renameSubject(BuildContext context, WidgetRef ref) async {
    final subjectsNotifier = ref.read(subjectsProvider.notifier);
    Navigator.of(context).pop();
    
    final nameController = TextEditingController(text: subject.name);
    
    showBlurredDialog(
      context: context,
      builder: (dialogContext) => Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Rename Folder',
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
                labelText: 'Folder Name',
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
                  final updatedSubject = subject.copyWith(
                    name: nameController.text.trim(),
                  );
                  await subjectsNotifier.updateSubject(updatedSubject);
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
                      final updatedSubject = subject.copyWith(
                        name: nameController.text.trim(),
                      );
                      await subjectsNotifier.updateSubject(updatedSubject);
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

  Future<void> _shareFolder(BuildContext context, WidgetRef ref) async {
    Navigator.of(context).pop();
    
    try {
      // Get all documents in this folder
      final documents = ref.read(documentsProvider).value ?? [];
      final folderDocs = documents.where((d) => d.subjectId == subject.id).toList();
      
      if (folderDocs.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No documents to share in this folder')),
          );
        }
        return;
      }
      
      // Share all document paths
      final filePaths = folderDocs.map((d) => d.path).toList();
      await Share.shareXFiles(filePaths.map((path) => XFile(path)).toList());
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sharing folder: $e')),
        );
      }
    }
  }

  void _moveToFolder(BuildContext context, WidgetRef ref) {
    Navigator.of(context).pop();
    
    final allSubjects = ref.read(subjectsProvider).value ?? [];
    final otherSubjects = allSubjects.where((s) => s.id != subject.id).toList();
    
    if (otherSubjects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No other folders available')),
      );
      return;
    }
    
    showBouncyBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Text(
                'Move to Folder',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 8),
            SmartGroupedCardList(
              children: otherSubjects.map((targetSubject) {
                final position = getCardPosition(
                  otherSubjects.indexOf(targetSubject),
                  otherSubjects.length,
                );
                
                return SmartGroupedCard(
                  position: position,
                  onTap: () async {
                    Navigator.of(context).pop();
                    // Update subject's parentId to move it
                    final updatedSubject = subject.copyWith(parentId: targetSubject.id);
                    await ref.read(subjectsProvider.notifier).updateSubject(updatedSubject);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Moved to ${targetSubject.name}')),
                      );
                    }
                  },
                  child: ListTile(
                    leading: const Icon(Icons.folder, color: Colors.white),
                    title: Text(targetSubject.name),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _copyToFolder(BuildContext context, WidgetRef ref) {
    Navigator.of(context).pop();
    
    final allSubjects = ref.read(subjectsProvider).value ?? [];
    final otherSubjects = allSubjects.where((s) => s.id != subject.id).toList();
    
    if (otherSubjects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No other folders available')),
      );
      return;
    }
    
    showBouncyBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Text(
                'Copy to Folder',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 8),
            SmartGroupedCardList(
              children: otherSubjects.map((targetSubject) {
                final position = getCardPosition(
                  otherSubjects.indexOf(targetSubject),
                  otherSubjects.length,
                );
                
                return SmartGroupedCard(
                  position: position,
                  onTap: () async {
                    Navigator.of(context).pop();
                    // Copy all documents from this folder to target folder
                    final documents = ref.read(documentsProvider).value ?? [];
                    final folderDocs = documents.where((d) => d.subjectId == subject.id).toList();
                    const uuid = Uuid();
                    
                    for (var doc in folderDocs) {
                      final copiedDoc = doc.copyWith(
                        id: uuid.v4(),
                        subjectId: targetSubject.id,
                        addedDate: DateTime.now(),
                      );
                      await ref.read(documentsProvider.notifier).addDocument(copiedDoc);
                    }
                    
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${folderDocs.length} documents copied to ${targetSubject.name}')),
                      );
                    }
                  },
                  child: ListTile(
                    leading: const Icon(Icons.folder, color: Colors.white),
                    title: Text(targetSubject.name),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteSubject(BuildContext context, WidgetRef ref) async {
    final subjectsNotifier = ref.read(subjectsProvider.notifier);
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
              'Delete Folder',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'This will delete the folder and remove all its documents from the app. The actual files will not be deleted.',
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
                    await subjectsNotifier.deleteSubject(subject.id);
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
                  child: const Text('Delete', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Folder name - larger text
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 20),
            child: Text(
              subject.name,
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
                onTap: () => _openFolder(context, ref),
                child: const ListTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  leading: Icon(Icons.folder_open, color: Colors.white),
                  title: Text('Open Folder', style: TextStyle(fontSize: 16)),
                ),
              ),
              GroupedBottomSheetCard(
                position: getGroupedCardPosition(1, 4),
                onTap: () => _renameSubject(context, ref),
                child: const ListTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  leading: Icon(Icons.edit, color: Colors.white),
                  title: Text('Rename', style: TextStyle(fontSize: 16)),
                ),
              ),
              GroupedBottomSheetCard(
                position: getGroupedCardPosition(2, 4),
                onTap: () => _shareFolder(context, ref),
                child: const ListTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  leading: Icon(Icons.share, color: Colors.white),
                  title: Text('Share', style: TextStyle(fontSize: 16)),
                ),
              ),
              GroupedBottomSheetCard(
                position: getGroupedCardPosition(3, 4),
                onTap: () => _deleteSubject(context, ref),
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

void showSubjectOptionsBottomSheet(
  BuildContext context,
  SubjectModel subject,
) {
  showBouncyBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF2C2C2C),
    builder: (context) => SubjectOptionsBottomSheet(subject: subject),
  );
}
