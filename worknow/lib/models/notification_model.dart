import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final String? jobId;
  final Timestamp createdAt;
  final bool read;
  final String type;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    this.jobId,
    required this.createdAt,
    required this.read,
    required this.type,
  });

  // Create from Firestore document
  factory NotificationModel.fromMap(Map<String, dynamic> map, String id) {
    return NotificationModel(
      id: id,
      title: map['title'] ?? 'Notificación',
      body: map['body'] ?? '',
      jobId: map['jobId'],
      createdAt: map['createdAt'] ?? Timestamp.now(),
      read: map['read'] ?? false,
      type: map['type'] ?? 'general',
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'body': body,
      'jobId': jobId,
      'createdAt': createdAt,
      'read': read,
      'type': type,
    };
  }

  // Copy with method for updates
  NotificationModel copyWith({
    String? title,
    String? body,
    String? jobId,
    Timestamp? createdAt,
    bool? read,
    String? type,
  }) {
    return NotificationModel(
      id: id,
      title: title ?? this.title,
      body: body ?? this.body,
      jobId: jobId ?? this.jobId,
      createdAt: createdAt ?? this.createdAt,
      read: read ?? this.read,
      type: type ?? this.type,
    );
  }
}
