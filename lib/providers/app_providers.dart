import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import '../models/subject_model.dart';
import '../models/document_model.dart';
import '../services/storage_service.dart';
import '../services/file_service.dart';

// Services
final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) async {
  return await SharedPreferences.getInstance();
});

final storageServiceProvider = Provider<StorageService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider).value;
  if (prefs == null) {
    throw Exception('SharedPreferences not initialized');
  }
  return StorageService(prefs);
});

final fileServiceProvider = Provider<FileService>((ref) {
  return FileService();
});

// Subjects
final subjectsProvider = StateNotifierProvider<SubjectsNotifier, AsyncValue<List<SubjectModel>>>((ref) {
  final storageService = ref.watch(storageServiceProvider);
  return SubjectsNotifier(storageService);
});

class SubjectsNotifier extends StateNotifier<AsyncValue<List<SubjectModel>>> {
  final StorageService _storageService;

  SubjectsNotifier(this._storageService) : super(const AsyncValue.loading()) {
    loadSubjects();
  }

  Future<void> loadSubjects() async {
    state = const AsyncValue.loading();
    try {
      final subjects = await _storageService.getSubjects();
      state = AsyncValue.data(subjects);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addSubject(SubjectModel subject) async {
    await _storageService.addSubject(subject);
    await loadSubjects();
  }

  Future<void> updateSubject(SubjectModel subject) async {
    await _storageService.updateSubject(subject);
    await loadSubjects();
  }

  Future<void> deleteSubject(String subjectId) async {
    await _storageService.deleteSubject(subjectId);
    await loadSubjects();
  }
}

// Documents
final documentsProvider = StateNotifierProvider<DocumentsNotifier, AsyncValue<List<DocumentModel>>>((ref) {
  final storageService = ref.watch(storageServiceProvider);
  return DocumentsNotifier(storageService);
});

class DocumentsNotifier extends StateNotifier<AsyncValue<List<DocumentModel>>> {
  final StorageService _storageService;

  DocumentsNotifier(this._storageService) : super(const AsyncValue.loading()) {
    loadDocuments();
  }

  Future<void> loadDocuments() async {
    state = const AsyncValue.loading();
    try {
      final documents = await _storageService.getDocuments();
      state = AsyncValue.data(documents);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addDocument(DocumentModel document) async {
    await _storageService.addDocument(document);
    await loadDocuments();
  }

  Future<void> updateDocument(DocumentModel document) async {
    await _storageService.updateDocument(document);
    await loadDocuments();
  }

  Future<void> deleteDocument(String documentId) async {
    await _storageService.deleteDocument(documentId);
    await loadDocuments();
  }

  List<DocumentModel> getDocumentsBySubject(String subjectId) {
    return state.value?.where((d) => d.subjectId == subjectId).toList() ?? [];
  }
}
// Share State
class ShareState {
  final List<SharedMediaFile> sharedFiles;
  final bool isSaveLocationMode;
  final bool shareConsumed;

  ShareState({
    this.sharedFiles = const [],
    this.isSaveLocationMode = false,
    this.shareConsumed = false,
  });

  ShareState copyWith({
    List<SharedMediaFile>? sharedFiles,
    bool? isSaveLocationMode,
    bool? shareConsumed,
  }) {
    return ShareState(
      sharedFiles: sharedFiles ?? this.sharedFiles,
      isSaveLocationMode: isSaveLocationMode ?? this.isSaveLocationMode,
      shareConsumed: shareConsumed ?? this.shareConsumed,
    );
  }
}

class ShareStateNotifier extends StateNotifier<ShareState> {
  ShareStateNotifier() : super(ShareState());

  void setSharedFiles(List<SharedMediaFile> files) {
    // If share is already consumed, do not accept new files from the same intent session
    // unless we explicitly reset. But here we assume a new list means new intent.
    // However, to be safe, if we are in consumer mode, we might want to block.
    // But typically a new intent means we should process it.
    // Let's just set it.
    state = state.copyWith(
      sharedFiles: files,
      isSaveLocationMode: true,
      shareConsumed: false,
    );
  }

  void consumeShare() {
    // Mark as consumed and clear files
    state = state.copyWith(
      sharedFiles: [],
      isSaveLocationMode: false,
      shareConsumed: true,
    );
  }

  void cancelShare() {
    state = state.copyWith(
      sharedFiles: [],
      isSaveLocationMode: false,
      shareConsumed: true,
    );
  }
}

final shareStateProvider = StateNotifierProvider<ShareStateNotifier, ShareState>((ref) {
  return ShareStateNotifier();
});
