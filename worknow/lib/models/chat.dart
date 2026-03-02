import 'package:cloud_firestore/cloud_firestore.dart';

class Chat {
  final String chatId;
  final String jobId;
  final String jobTitle;
  final String ownerId;
  final String ownerName;
  final String candidateId;
  final String candidateName;
  final List<String> participantIds;
  final Timestamp createdAt;
  final String lastMessage;
  final Timestamp? lastTimestamp;
  final String status;
  final Map<String, int> unreadCount;

  Chat({
    required this.chatId,
    required this.jobId,
    required this.jobTitle,
    required this.ownerId,
    required this.ownerName,
    required this.candidateId,
    required this.candidateName,
    required this.participantIds,
    required this.createdAt,
    required this.lastMessage,
    this.lastTimestamp,
    required this.status,
    required this.unreadCount,
  });

  factory Chat.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return Chat(
      chatId: doc.id,
      jobId: data['jobId'] ?? '',
      jobTitle: data['jobTitle'] ?? 'Trabajo',
      ownerId: data['ownerId'] ?? '',
      ownerName: data['ownerName'] ?? 'Usuario',
      candidateId: data['candidateId'] ?? '',
      candidateName: data['candidateName'] ?? 'Usuario',
      participantIds: List<String>.from(data['participantIds'] ?? []),
      createdAt: data['createdAt'] ?? Timestamp.now(),
      lastMessage: data['lastMessage'] ?? '',
      lastTimestamp: data['lastTimestamp'],
      status: data['status'] ?? 'active',
      unreadCount: Map<String, int>.from(
        (data['unreadCount'] as Map<String, dynamic>?)?.map(
          (key, value) => MapEntry(key, value as int? ?? 0),
        ) ?? {},
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'chatId': chatId,
      'jobId': jobId,
      'jobTitle': jobTitle,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'candidateId': candidateId,
      'candidateName': candidateName,
      'participantIds': participantIds,
      'createdAt': createdAt,
      'lastMessage': lastMessage,
      'lastTimestamp': lastTimestamp,
      'status': status,
      'unreadCount': unreadCount,
    };
  }

  bool isParticipant(String userId) {
    return participantIds.contains(userId);
  }

  String getOtherUserName(String currentUserId) {
    return currentUserId == ownerId ? candidateName : ownerName;
  }

  bool isActive() {
    return status == 'active';
  }
}

