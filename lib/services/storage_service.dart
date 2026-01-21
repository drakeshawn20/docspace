import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/subject_model.dart';
import '../models/document_model.dart';

class StorageService {
  static const String _subjectsKey = 'subjects';
  static const String _documentsKey = 'documents';

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  // Subjects
  Future<List<SubjectModel>> getSubjects() async {
    final String? subjectsJson = _prefs.getString(_subjectsKey);
    if (subjectsJson == null) return [];

    final List<dynamic> decoded = jsonDecode(subjectsJson);
    return decoded.map((json) => SubjectModel.fromJson(json)).toList();
  }

  Future<void> saveSubjects(List<SubjectModel> subjects) async {
    final String encoded = jsonEncode(subjects.map((s) => s.toJson()).toList());
    await _prefs.setString(_subjectsKey, encoded);
  }

  Future<void> addSubject(SubjectModel subject) async {
    final subjects = await getSubjects();
    subjects.add(subject);
    await saveSubjects(subjects);
  }

  Future<void> updateSubject(SubjectModel subject) async {
    final subjects = await getSubjects();
    final index = subjects.indexWhere((s) => s.id == subject.id);
    if (index != -1) {
      subjects[index] = subject;
      await saveSubjects(subjects);
    }
  }

  Future<void> deleteSubject(String subjectId) async {
    final subjects = await getSubjects();
    subjects.removeWhere((s) => s.id == subjectId);
    await saveSubjects(subjects);
    
    // Also delete all documents in this subject
    final documents = await getDocuments();
    documents.removeWhere((d) => d.subjectId == subjectId);
    await saveDocuments(documents);
  }

  // Documents
  Future<List<DocumentModel>> getDocuments() async {
    final String? documentsJson = _prefs.getString(_documentsKey);
    if (documentsJson == null) return [];

    final List<dynamic> decoded = jsonDecode(documentsJson);
    return decoded.map((json) => DocumentModel.fromJson(json)).toList();
  }

  Future<void> saveDocuments(List<DocumentModel> documents) async {
    final String encoded = jsonEncode(documents.map((d) => d.toJson()).toList());
    await _prefs.setString(_documentsKey, encoded);
  }

  Future<void> addDocument(DocumentModel document) async {
    final documents = await getDocuments();
    documents.add(document);
    await saveDocuments(documents);
  }

  Future<void> updateDocument(DocumentModel document) async {
    final documents = await getDocuments();
    final index = documents.indexWhere((d) => d.id == document.id);
    if (index != -1) {
      documents[index] = document;
      await saveDocuments(documents);
    }
  }

  Future<void> deleteDocument(String documentId) async {
    final documents = await getDocuments();
    documents.removeWhere((d) => d.id == documentId);
    await saveDocuments(documents);
  }

  Future<List<DocumentModel>> getDocumentsBySubject(String subjectId) async {
    final documents = await getDocuments();
    return documents.where((d) => d.subjectId == subjectId).toList();
  }
}
