import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  info,
  warning,
  error,
  success,
  activity,
  budget,
}

class SystemNotification {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final NotificationType type;
  final String? relatedId; // ID of activity, budget line, etc.
  final String? userId; // If null, it's a global notification

  SystemNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    this.type = NotificationType.info,
    this.relatedId,
    this.userId,
  });

  factory SystemNotification.fromFirestore(Map<String, dynamic> data, String id) {
    return SystemNotification(
      id: id,
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['is_read'] ?? false,
      type: NotificationType.values.firstWhere(
        (e) => e.toString() == data['type'],
        orElse: () => NotificationType.info,
      ),
      relatedId: data['related_id'],
      userId: data['user_id'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'message': message,
      'timestamp': Timestamp.fromDate(timestamp),
      'is_read': isRead,
      'type': type.toString(),
      'related_id': relatedId,
      'user_id': userId,
    };
  }

  SystemNotification copyWith({
    String? id,
    String? title,
    String? message,
    DateTime? timestamp,
    bool? isRead,
    NotificationType? type,
    String? relatedId,
    String? userId,
  }) {
    return SystemNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      type: type ?? this.type,
      relatedId: relatedId ?? this.relatedId,
      userId: userId ?? this.userId,
    );
  }
}
