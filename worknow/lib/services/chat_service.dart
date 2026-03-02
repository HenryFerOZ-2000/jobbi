import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/chat.dart';
import '../models/message.dart';

class ChatService {
  ChatService._();
  static final ChatService instance = ChatService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Generate unique chat ID
  String generateChatId({
    required String jobId,
    required String ownerId,
    required String candidateId,
  }) {
    return '${jobId}_${ownerId}_$candidateId';
  }

  // Check if chat exists
  Future<bool> chatExists(String chatId) async {
    try {
      final doc = await _firestore.collection('chats').doc(chatId).get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  // Check if user is participant
  Future<bool> isParticipant(String chatId, String userId) async {
    try {
      final doc = await _firestore.collection('chats').doc(chatId).get();
      if (!doc.exists) return false;

      final chat = Chat.fromFirestore(doc);
      return chat.isParticipant(userId);
    } catch (e) {
      return false;
    }
  }

  // Create chat channel
  Future<String> createChatChannel({
    required String jobId,
    required String ownerId,
    required String candidateId,
    required String jobTitle,
    required String ownerName,
    required String candidateName,
  }) async {
    try {
      final chatId = generateChatId(
        jobId: jobId,
        ownerId: ownerId,
        candidateId: candidateId,
      );

      // Check if exists
      final exists = await chatExists(chatId);
      if (exists) {
        return chatId;
      }

      // Create new chat
      final chat = Chat(
        chatId: chatId,
        jobId: jobId,
        jobTitle: jobTitle,
        ownerId: ownerId,
        ownerName: ownerName,
        candidateId: candidateId,
        candidateName: candidateName,
        participantIds: [ownerId, candidateId],
        createdAt: Timestamp.now(),
        lastMessage: '',
        lastTimestamp: null,
        status: 'active',
        unreadCount: {
          ownerId: 0,
          candidateId: 0,
        },
      );

      await _firestore.collection('chats').doc(chatId).set(chat.toMap());

      return chatId;
    } catch (e) {
      throw 'Error al crear chat: ${e.toString()}';
    }
  }

  // Send message
  Future<void> sendMessage({
    required String chatId,
    required String message,
    required String senderId,
  }) async {
    try {
      if (message.trim().isEmpty) {
        throw 'No se pueden enviar mensajes vacíos';
      }

      final newMessage = Message(
        senderId: senderId,
        message: message.trim(),
        timestamp: Timestamp.now(),
        seen: false,
        type: 'text',
      );

      // Add message to subcollection
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add(newMessage.toMap());

      // Update chat's last message
      final chatDoc = await _firestore.collection('chats').doc(chatId).get();
      final chatData = chatDoc.data();
      
      if (chatData != null) {
        final participantIds = List<String>.from(chatData['participantIds'] ?? []);
        final receiverId = participantIds.firstWhere(
          (id) => id != senderId,
          orElse: () => '',
        );

        final unreadCount = Map<String, dynamic>.from(chatData['unreadCount'] ?? {});
        unreadCount[receiverId] = (unreadCount[receiverId] ?? 0) + 1;

        await _firestore.collection('chats').doc(chatId).update({
          'lastMessage': message.trim(),
          'lastTimestamp': Timestamp.now(),
          'unreadCount': unreadCount,
        });
      }
    } catch (e) {
      throw 'Error al enviar mensaje: ${e.toString()}';
    }
  }

  // Get messages stream
  Stream<List<Message>> getMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Message.fromFirestore(doc)).toList();
    });
  }

  // Get chats stream
  Stream<List<Chat>> getChats(String userId) {
    return _firestore
        .collection('chats')
        .where('participantIds', arrayContains: userId)
        .orderBy('lastTimestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Chat.fromFirestore(doc)).toList();
    });
  }

  // Mark messages as read
  Future<void> markMessagesAsRead({
    required String chatId,
    required String currentUserId,
  }) async {
    try {
      final messagesSnapshot = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('senderId', isNotEqualTo: currentUserId)
          .where('seen', isEqualTo: false)
          .get();

      final batch = _firestore.batch();

      for (var doc in messagesSnapshot.docs) {
        batch.update(doc.reference, {'seen': true});
      }

      await batch.commit();

      // Reset unread count
      await _firestore.collection('chats').doc(chatId).update({
        'unreadCount.$currentUserId': 0,
      });
    } catch (e) {
      // Silent fail
    }
  }

  // Get chat by job and user
  Future<String?> getChatIdByJobAndUser({
    required String jobId,
    required String userId,
  }) async {
    try {
      final chatsSnapshot = await _firestore
          .collection('chats')
          .where('jobId', isEqualTo: jobId)
          .where('participantIds', arrayContains: userId)
          .limit(1)
          .get();

      if (chatsSnapshot.docs.isNotEmpty) {
        return chatsSnapshot.docs.first.id;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Create chat with automatic user data fetching
  Future<String> createChat({
    required String otherUserId,
    required String jobId,
    required String jobTitle,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw 'Usuario no autenticado';
    }

    try {
      // Check if chat already exists
      final existingChatId = await getChatIdByJobAndUser(
        jobId: jobId,
        userId: currentUser.uid,
      );

      if (existingChatId != null) {
        return existingChatId;
      }

      // Get current user data
      final currentUserDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();
      final currentUserData = currentUserDoc.data();
      final currentUserName = currentUserData?['fullName'] ??
          currentUserData?['name'] ??
          'Usuario';

      // Get other user data
      final otherUserDoc = await _firestore
          .collection('users')
          .doc(otherUserId)
          .get();
      final otherUserData = otherUserDoc.data();
      final otherUserName = otherUserData?['fullName'] ??
          otherUserData?['name'] ??
          'Usuario';

      // Get job data to determine who is owner and who is candidate
      final jobDoc = await _firestore.collection('jobs').doc(jobId).get();
      final jobData = jobDoc.data();
      final ownerId = jobData?['ownerId'] ?? '';

      String candidateId;
      String candidateName;
      String ownerName;

      if (ownerId == currentUser.uid) {
        // Current user is owner, other is candidate
        candidateId = otherUserId;
        candidateName = otherUserName;
        ownerName = currentUserName;
      } else {
        // Other user is owner, current is candidate
        candidateId = currentUser.uid;
        candidateName = currentUserName;
        ownerName = otherUserName;
      }

      // Create chat
      return await createChatChannel(
        jobId: jobId,
        ownerId: ownerId,
        candidateId: candidateId,
        jobTitle: jobTitle,
        ownerName: ownerName,
        candidateName: candidateName,
      );
    } catch (e) {
      throw 'Error al crear chat: ${e.toString()}';
    }
  }
}

