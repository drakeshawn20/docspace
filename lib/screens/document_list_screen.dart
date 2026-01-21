import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:animations/animations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';
import '../models/subject_model.dart';
import '../models/document_model.dart';
import '../providers/app_providers.dart';
import '../widgets/smart_grouped_card.dart';
import '../widgets/document_options_bottom_sheet.dart';
import '../widgets/create_subject_bottom_sheet.dart';
import '../widgets/subject_options_bottom_sheet.dart';

class DocumentListScreen extends ConsumerStatefulWidget {
  final SubjectModel subject;

  const DocumentListScreen({
    super.key,
    required this.subject,
  });

  @override
  ConsumerState<DocumentListScreen> createState() => _DocumentListScreenState();
}

class _DocumentListScreenState extends ConsumerState<DocumentListScreen> {
  Future<void> _saveSharedFiles() async {
    final shareState = ref.read(shareStateProvider);
    if (shareState.sharedFiles.isEmpty) return;
    
    final appDir = await getApplicationDocumentsDirectory();
    const uuid = Uuid();
    
    int savedCount = 0;
    for (var file in shareState.sharedFiles) {
      try {
        final originalFile = File(file.path);
        if (!await originalFile.exists()) continue;

        final fileName = file.path.split('/').last;
        final newPath = '${appDir.path}/${widget.subject.id}_${DateTime.now().millisecondsSinceEpoch}_$fileName';
        
        await originalFile.copy(newPath);
        
        final document = DocumentModel(
          id: uuid.v4(),
          name: fileName,
          path: newPath,
          mimeType: _getMimeType(fileName),
          subjectId: widget.subject.id,
          addedDate: DateTime.now(),
        );
        
        await ref.read(documentsProvider.notifier).addDocument(document);
        savedCount++;
      } catch (e) {
        print('Error saving shared file: $e');
      }
    }

    // Call the callback to clear state globally and consume the share intent
    if (mounted) {
      ref.read(shareStateProvider.notifier).consumeShare();
      ReceiveSharingIntent.instance.reset(); // Also reset intent here to be double safe
    }
  }

  String _getMimeType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf': return 'application/pdf';
      case 'jpg':
      case 'jpeg': return 'image/jpeg';
      case 'png': return 'image/png';
      case 'doc':
      case 'docx': return 'application/msword';
      default: return 'application/octet-stream';
    }
  }

  @override
  Widget build(BuildContext context) {
    final documentsAsync = ref.watch(documentsProvider);
    final subjectsAsync = ref.watch(subjectsProvider);
    final shareState = ref.watch(shareStateProvider);
    
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        toolbarHeight: 0,
      ),
      body: documentsAsync.when(
        data: (allDocuments) {
          final subFolders = subjectsAsync.value
                  ?.where((s) => s.parentId == widget.subject.id)
                  .toList() ?? [];
          final documents = allDocuments
              .where((d) => d.subjectId == widget.subject.id)
              .toList();
          
          return ListView(
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            padding: EdgeInsets.zero,
            children: [
              // Header Section
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Navigation Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Back Button (Circle)
                        Container(
                          width: 48,
                          height: 48,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.black, size: 24),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                        
                        // Cancel Button (in Save Location Mode) OR Sub-Folder Button (Normal Mode)
                        if (shareState.isSaveLocationMode)
                          SizedBox(
                            height: 48,
                            child: TextButton.icon(
                              onPressed: () {
                                ref.read(shareStateProvider.notifier).cancelShare();
                                ReceiveSharingIntent.instance.reset(); // Reset intent on cancel
                              },
                              style: TextButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              icon: const Icon(Icons.close, size: 20),
                              label: const Text(
                                'Cancel',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                          )
                        else
                          SizedBox(
                            height: 48,
                            child: TextButton.icon(
                              onPressed: () => showCreateSubjectDialog(context, widget.subject.id),
                              style: TextButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              icon: const Icon(Icons.create_new_folder, size: 20),
                              label: const Text(
                                'Sub-Folder',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    
                    Text(
                      widget.subject.name,
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'Cursive',
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Content
                    _buildContentList(context, ref, subFolders, documents),
                    
                    // Bottom Spacing
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error: $error'),
        ),
      ),
      floatingActionButton: shareState.isSaveLocationMode
          ? (shareState.sharedFiles.isNotEmpty
              ? FloatingActionButton.extended(
                  onPressed: _saveSharedFiles,
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  icon: const Icon(Icons.save),
                  label: Text(
                    shareState.sharedFiles.length == 1
                        ? 'Save Here'
                        : 'Save (${shareState.sharedFiles.length})',
                  ),
                )
              : null)
          : FloatingActionButton.extended(
              onPressed: () => _pickDocument(context, ref),
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              icon: const Icon(Icons.upload_file),
              label: const Text('Import Document'),
            ),
    );
  }

  Widget _buildContentList(
    BuildContext context,
    WidgetRef ref,
    List<SubjectModel> subFolders,
    List<DocumentModel> documents,
  ) {
    if (subFolders.isEmpty && documents.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.only(top: 60),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.folder_open,
                size: 64,
                color: Colors.white38,
              ),
              SizedBox(height: 16),
              Text(
                'Empty folder',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white60,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final List<Widget> allItems = [];
    
    // Add sub-folders first
    if (subFolders.isNotEmpty) {
      allItems.addAll(
        subFolders.map((subFolder) {
          final position = getCardPosition(
            allItems.length,
            subFolders.length + documents.length,
          );
          
          return SmartGroupedCard(
            position: position,
            onTap: () => _navigateToSubFolder(context, subFolder),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.folder_outlined,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                title: Text(
                  subFolder.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                subtitle: Consumer(
                  builder: (context, ref, child) {
                    final documentsAsync = ref.watch(documentsProvider);
                    final count = documentsAsync.value
                            ?.where((d) => d.subjectId == subFolder.id)
                            .length ??
                        0;
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '$count files',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.6),
                        ),
                      ),
                    );
                  },
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.more_horiz, color: Colors.white70),
                  onPressed: () {
                    showSubjectOptionsBottomSheet(context, subFolder);
                  },
                ),
              ),
            ),
          );
        }),
      );
    }
    
    // Add documents
    if (documents.isNotEmpty) {
      allItems.addAll(
        documents.map((document) {
          final position = getCardPosition(
            allItems.length,
            subFolders.length + documents.length,
          );
          
          return SmartGroupedCard(
            position: position,
            onTap: () => _openDocument(context, document),
            onLongPress: () => _showDocumentOptions(context, ref, document),
            child: Padding(
               padding: const EdgeInsets.symmetric(vertical: 6),
               child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getDocumentIcon(document.mimeType),
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                title: Text(
                  document.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _formatDate(document.addedDate),
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.more_horiz, color: Colors.white70),
                  onPressed: () => _showDocumentOptions(context, ref, document),
                ),
              ),
            ),
          );
        }),
      );
    }

    return SmartGroupedCardList(
      spacing: 2,
      children: allItems,
    );
  }

  void _navigateToSubFolder(BuildContext context, SubjectModel subFolder) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            DocumentListScreen(subject: subFolder),
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

  IconData _getDocumentIcon(String mimeType) {
    if (mimeType.contains('pdf')) {
      return Icons.picture_as_pdf;
    } else if (mimeType.contains('word') || mimeType.contains('document')) {
      return Icons.description;
    } else if (mimeType.contains('sheet') || mimeType.contains('excel')) {
      return Icons.table_chart;
    } else if (mimeType.contains('presentation') || mimeType.contains('powerpoint')) {
      return Icons.slideshow;
    } else if (mimeType.contains('image')) {
      return Icons.image;
    } else if (mimeType.contains('video')) {
      return Icons.video_file;
    } else if (mimeType.contains('audio')) {
      return Icons.audio_file;
    } else if (mimeType.contains('text')) {
      return Icons.text_snippet;
    } else {
      return Icons.insert_drive_file;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Future<void> _pickDocument(BuildContext context, WidgetRef ref) async {
    try {
      final fileService = ref.read(fileServiceProvider);
      final document = await fileService.pickDocument(widget.subject.id);
      
      if (document != null) {
        await ref.read(documentsProvider.notifier).addDocument(document);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Document added successfully')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding document: $e')),
        );
      }
    }
  }

  Future<void> _openDocument(BuildContext context, DocumentModel document) async {
    try {
      final result = await OpenFilex.open(document.path);
      if (result.type != ResultType.done && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${result.message}')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening document: $e')),
        );
      }
    }
  }

  void _showDocumentOptions(
    BuildContext context,
    WidgetRef ref,
    DocumentModel document,
  ) {
    final subjects = ref.read(subjectsProvider).value ?? [];
    showDocumentOptionsBottomSheet(context, document, subjects);
  }
}
