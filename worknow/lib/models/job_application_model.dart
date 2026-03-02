import 'package:cloud_firestore/cloud_firestore.dart';

class JobApplicationModel {
  final String id;
  final String userId;
  final String userName;
  final String employerId;
  final String jobId;
  final String jobTitle;
  final String status; // pending, accepted, assigned, in_progress, waiting_confirmation, completed, rejected
  final String? message;
  final Timestamp appliedAt;
  final Timestamp? updatedAt;
  final Timestamp? completedAt;
  final String? completionRequestedBy; // userId who requested completion
  final bool? autoRejected;
  final String? rejectionReason;

  JobApplicationModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.employerId,
    required this.jobId,
    required this.jobTitle,
    required this.status,
    this.message,
    required this.appliedAt,
    this.updatedAt,
    this.completedAt,
    this.completionRequestedBy,
    this.autoRejected,
    this.rejectionReason,
  });

  /// Create from Firestore document
  factory JobApplicationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return JobApplicationModel.fromMap(data, doc.id);
  }

  /// Create from Map
  factory JobApplicationModel.fromMap(Map<String, dynamic> map, String id) {
    return JobApplicationModel(
      id: id,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      employerId: map['employerId'] ?? '',
      jobId: map['jobId'] ?? '',
      jobTitle: map['jobTitle'] ?? '',
      status: map['status'] ?? 'pending',
      message: map['message'] as String?,
      appliedAt: map['appliedAt'] ?? Timestamp.now(),
      updatedAt: map['updatedAt'] as Timestamp?,
      completedAt: map['completedAt'] as Timestamp?,
      completionRequestedBy: map['completionRequestedBy'] as String?,
      autoRejected: map['autoRejected'] as bool?,
      rejectionReason: map['rejectionReason'] as String?,
    );
  }

  /// Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'employerId': employerId,
      'jobId': jobId,
      'jobTitle': jobTitle,
      'status': status,
      'message': message,
      'appliedAt': appliedAt,
      'updatedAt': updatedAt,
      'completedAt': completedAt,
      'completionRequestedBy': completionRequestedBy,
      'autoRejected': autoRejected,
      'rejectionReason': rejectionReason,
    };
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() => toMap();

  /// Create from JSON
  factory JobApplicationModel.fromJson(Map<String, dynamic> json, String id) {
    return JobApplicationModel.fromMap(json, id);
  }

  /// Copy with method
  JobApplicationModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? employerId,
    String? jobId,
    String? jobTitle,
    String? status,
    String? message,
    Timestamp? appliedAt,
    Timestamp? updatedAt,
    Timestamp? completedAt,
    String? completionRequestedBy,
    bool? autoRejected,
    String? rejectionReason,
  }) {
    return JobApplicationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      employerId: employerId ?? this.employerId,
      jobId: jobId ?? this.jobId,
      jobTitle: jobTitle ?? this.jobTitle,
      status: status ?? this.status,
      message: message ?? this.message,
      appliedAt: appliedAt ?? this.appliedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
      completionRequestedBy: completionRequestedBy ?? this.completionRequestedBy,
      autoRejected: autoRejected ?? this.autoRejected,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }

  /// Check if application is active (not rejected or completed)
  bool get isActive => status != 'rejected' && status != 'completed';

  /// Check if application is pending
  bool get isPending => status == 'pending';

  /// Check if application is accepted
  bool get isAccepted => status == 'accepted';

  /// Check if application is assigned
  bool get isAssigned => status == 'assigned';

  /// Check if application is in progress
  bool get isInProgress => status == 'in_progress';

  /// Check if application is waiting confirmation
  bool get isWaitingConfirmation => status == 'waiting_confirmation';

  /// Check if application is completed
  bool get isCompleted => status == 'completed';

  /// Check if application is rejected
  bool get isRejected => status == 'rejected';

  /// Get status display text
  String get statusDisplayText {
    switch (status) {
      case 'pending':
        return 'Pendiente';
      case 'accepted':
        return 'Aceptado';
      case 'assigned':
        return 'Asignado';
      case 'in_progress':
        return 'En Progreso';
      case 'waiting_confirmation':
        return 'Esperando Confirmación';
      case 'completed':
        return 'Completado';
      case 'rejected':
        return 'Rechazado';
      default:
        return status;
    }
  }
}

