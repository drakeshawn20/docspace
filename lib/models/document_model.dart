class DocumentModel {
  final String id;
  final String name;
  final String path; // File URI
  final String mimeType;
  final String subjectId;
  final DateTime addedDate;

  DocumentModel({
    required this.id,
    required this.name,
    required this.path,
    required this.mimeType,
    required this.subjectId,
    required this.addedDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'path': path,
      'mimeType': mimeType,
      'subjectId': subjectId,
      'addedDate': addedDate.toIso8601String(),
    };
  }

  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    return DocumentModel(
      id: json['id'] as String,
      name: json['name'] as String,
      path: json['path'] as String,
      mimeType: json['mimeType'] as String,
      subjectId: json['subjectId'] as String,
      addedDate: DateTime.parse(json['addedDate'] as String),
    );
  }

  DocumentModel copyWith({
    String? id,
    String? name,
    String? path,
    String? mimeType,
    String? subjectId,
    DateTime? addedDate,
  }) {
    return DocumentModel(
      id: id ?? this.id,
      name: name ?? this.name,
      path: path ?? this.path,
      mimeType: mimeType ?? this.mimeType,
      subjectId: subjectId ?? this.subjectId,
      addedDate: addedDate ?? this.addedDate,
    );
  }
}
