import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';
import '../models/document_model.dart';

class FileService {
  final _uuid = const Uuid();

  /// Pick a document from the device
  Future<DocumentModel?> pickDocument(String subjectId) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        
        return DocumentModel(
          id: _uuid.v4(),
          name: file.name,
          path: file.path ?? '',
          mimeType: _getMimeType(file.extension ?? ''),
          subjectId: subjectId,
          addedDate: DateTime.now(),
        );
      }
      return null;
    } catch (e) {
      // Error is silently handled - file picker was cancelled or failed
      return null;
    }
  }

  /// Get mime type from extension
  String _getMimeType(String extension) {
    final mimeTypes = {
      'pdf': 'application/pdf',
      'doc': 'application/msword',
      'docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'xls': 'application/vnd.ms-excel',
      'xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'ppt': 'application/vnd.ms-powerpoint',
      'pptx': 'application/vnd.openxmlformats-officedocument.presentationml.presentation',
      'txt': 'text/plain',
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'gif': 'image/gif',
      'mp4': 'video/mp4',
      'mp3': 'audio/mpeg',
    };

    return mimeTypes[extension.toLowerCase()] ?? 'application/octet-stream';
  }
}
