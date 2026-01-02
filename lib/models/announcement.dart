/// Announcement model for developer broadcast messages
class Announcement {
  final String id;
  final String title;
  final String description;
  final String? downloadLink;
  final String createdBy;
  final bool isActive;
  final DateTime? announcedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  Announcement({
    required this.id,
    required this.title,
    required this.description,
    this.downloadLink,
    required this.createdBy,
    required this.isActive,
    this.announcedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      downloadLink: json['download_link'] as String?,
      createdBy: json['created_by'] as String,
      isActive: json['is_active'] as bool? ?? true,
      announcedAt: json['announced_at'] != null 
          ? DateTime.parse(json['announced_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'download_link': downloadLink,
      'created_by': createdBy,
      'is_active': isActive,
      'announced_at': announcedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Announcement copyWith({
    String? id,
    String? title,
    String? description,
    String? downloadLink,
    String? createdBy,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Announcement(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      downloadLink: downloadLink ?? this.downloadLink,
      createdBy: createdBy ?? this.createdBy,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
