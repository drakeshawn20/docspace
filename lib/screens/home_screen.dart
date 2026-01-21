import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animations/animations.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/subject_model.dart';
import '../models/document_model.dart';
import '../providers/app_providers.dart';
import '../widgets/smart_grouped_card.dart';
import '../widgets/create_subject_bottom_sheet.dart';
import '../widgets/subject_options_bottom_sheet.dart';
import '../utils/bottom_sheet_utils.dart';
import 'document_list_screen.dart';
import 'search_screen.dart';

import 'dart:async';
import 'dart:io';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late StreamSubscription _intentDataStreamSubscription;

  @override
  void initState() {
    super.initState();
    _initShareIntent();
  }

  void _initShareIntent() {
    // For sharing images coming from outside the app while the app is in the memory
    _intentDataStreamSubscription = ReceiveSharingIntent.instance.getMediaStream().listen((value) {
      if (value.isNotEmpty) {
        // The provider handles logic to reject if already consumed
        ref.read(shareStateProvider.notifier).setSharedFiles(value);
      }
    }, onError: (err) {
      print("getIntentDataStream error: $err");
    });

    // For sharing images coming from outside the app while the app is closed
    ReceiveSharingIntent.instance.getInitialMedia().then((value) {
      if (value.isNotEmpty) {
        ref.read(shareStateProvider.notifier).setSharedFiles(value);
      }
    });
  }

  @override
  void dispose() {
    _intentDataStreamSubscription.cancel();
    super.dispose();
  }

  void _cancelSaveLocationMode() {
    ref.read(shareStateProvider.notifier).cancelShare();
    // Clear the Android share intent
    ReceiveSharingIntent.instance.reset();
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
    final subjectsAsync = ref.watch(subjectsProvider);
    
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        toolbarHeight: 0, // Hide AppBar but keep status bar color
      ),
      body: subjectsAsync.when(
        data: (subjects) => ListView(
          padding: EdgeInsets.zero,
          children: [
            // Header Section
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Centered Title
                  Center(
                    child: Text(
                      'docspace',
                      style: const TextStyle(
                        fontSize: 50,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'Cursive',
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Search Bar
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (context, animation, secondaryAnimation) =>
                              const SearchScreen(),
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
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2C2C2C),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.search, color: Colors.white70, size: 24),
                          SizedBox(width: 12),
                          Text(
                            'Search documents...',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Recent Folders Header
                  Text(
                    'Recent Folders',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'Cursive',
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Folders Content (non-scrollable list)
                  _buildContent(context, subjects),
                  
                  // Bottom spacing for FAB
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error: $error'),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showCreateSubjectDialog(context, null),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text('Create Folder'),
      ),
    );
  }

  Widget _buildContent(BuildContext context, List<SubjectModel> subjects) {
    // Filter to show only root-level folders (no parent)
    final rootSubjects = subjects.where((s) => s.parentId == null).toList();
    
    if (rootSubjects.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_outlined,
              size: 64,
              color: Colors.white38,
            ),
            SizedBox(height: 16),
            Text(
              'No folders yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.white60,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Tap + to create your first folder',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white38,
              ),
            ),
          ],
        ),
      );
    }

    return SmartGroupedCardList(
      spacing: 2, // Tighter spacing
      children: List.generate(
          rootSubjects.length,
          (index) {
            final subject = rootSubjects[index];
            final position = getCardPosition(index, rootSubjects.length);
            
            return SmartGroupedCard(
              position: position,
              onTap: () => _navigateToDocumentList(context, subject),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6), // Vertical padding for taller cards
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
                    subject.name,
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
                              ?.where((d) => d.subjectId == subject.id)
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
                      showSubjectOptionsBottomSheet(context, subject);
                    },
                  ),
                ),
              ),
            );
          },
        ),
    );
  }

  void _navigateToDocumentList(BuildContext context, SubjectModel subject) {
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
}
