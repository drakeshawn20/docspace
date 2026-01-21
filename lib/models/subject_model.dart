class SubjectModel {
  final String id;
  final String name;
  final String? parentId; // null means root level, otherwise it's a sub-folder
  final DateTime createdDate;

  SubjectModel({
    required this.id,
    required this.name,
    this.parentId,
    required this.createdDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'parentId': parentId,
      'createdDate': createdDate.toIso8601String(),
    };
  }

  factory SubjectModel.fromJson(Map<String, dynamic> json) {
    return SubjectModel(
      id: json['id'] as String,
      name: json['name'] as String,
      parentId: json['parentId'] as String?,
      createdDate: DateTime.parse(json['createdDate'] as String),
    );
  }

  SubjectModel copyWith({
    String? id,
    String? name,
    String? parentId,
    DateTime? createdDate,
  }) {
    return SubjectModel(
      id: id ?? this.id,
      name: name ?? this.name,
      parentId: parentId ?? this.parentId,
      createdDate: createdDate ?? this.createdDate,
    );
  }
}
