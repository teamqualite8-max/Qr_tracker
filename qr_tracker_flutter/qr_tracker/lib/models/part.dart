// lib/models/part.dart

enum PartStatus {
  notProcessed,
  post1Done,
  post2Done,
}

extension PartStatusExtension on PartStatus {
  String get label {
    switch (this) {
      case PartStatus.notProcessed:
        return 'NOT PROCESSED';
      case PartStatus.post1Done:
        return 'POST1_DONE';
      case PartStatus.post2Done:
        return 'POST2_DONE';
    }
  }

  String get displayLabel {
    switch (this) {
      case PartStatus.notProcessed:
        return 'Not Processed';
      case PartStatus.post1Done:
        return 'Control 1 Done';
      case PartStatus.post2Done:
        return 'Fully Completed';
    }
  }

  static PartStatus fromString(String value) {
    switch (value) {
      case 'POST1_DONE':
        return PartStatus.post1Done;
      case 'POST2_DONE':
        return PartStatus.post2Done;
      default:
        return PartStatus.notProcessed;
    }
  }
}

class Part {
  final String partId;
  PartStatus status;
  DateTime? post1Timestamp;
  String? post1ImagePath;
  DateTime? post2Timestamp;
  String? post2ImagePath;

  Part({
    required this.partId,
    this.status = PartStatus.notProcessed,
    this.post1Timestamp,
    this.post1ImagePath,
    this.post2Timestamp,
    this.post2ImagePath,
  });

  Duration? get delayBetweenPosts {
    if (post1Timestamp != null && post2Timestamp != null) {
      return post2Timestamp!.difference(post1Timestamp!);
    }
    return null;
  }

  Map<String, dynamic> toMap() {
    return {
      'part_id': partId,
      'status': status.label,
      'post1_timestamp': post1Timestamp?.toIso8601String(),
      'post1_image_path': post1ImagePath,
      'post2_timestamp': post2Timestamp?.toIso8601String(),
      'post2_image_path': post2ImagePath,
    };
  }

  factory Part.fromMap(Map<String, dynamic> map) {
    return Part(
      partId: map['part_id'] as String,
      status: PartStatusExtension.fromString(map['status'] as String? ?? ''),
      post1Timestamp: map['post1_timestamp'] != null
          ? DateTime.parse(map['post1_timestamp'] as String)
          : null,
      post1ImagePath: map['post1_image_path'] as String?,
      post2Timestamp: map['post2_timestamp'] != null
          ? DateTime.parse(map['post2_timestamp'] as String)
          : null,
      post2ImagePath: map['post2_image_path'] as String?,
    );
  }

  Part copyWith({
    PartStatus? status,
    DateTime? post1Timestamp,
    String? post1ImagePath,
    DateTime? post2Timestamp,
    String? post2ImagePath,
  }) {
    return Part(
      partId: partId,
      status: status ?? this.status,
      post1Timestamp: post1Timestamp ?? this.post1Timestamp,
      post1ImagePath: post1ImagePath ?? this.post1ImagePath,
      post2Timestamp: post2Timestamp ?? this.post2Timestamp,
      post2ImagePath: post2ImagePath ?? this.post2ImagePath,
    );
  }
}
