import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'chat_screen.dart';

class ChatsListScreen extends StatelessWidget {
  final bool showBackButton;
  
  const ChatsListScreen({super.key, this.showBackButton = false});

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '';

    final date = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return DateFormat('HH:mm').format(date);
    } else if (difference.inDays == 1) {
      return 'Ayer';
    } else if (difference.inDays < 7) {
      return DateFormat('EEEE').format(date);
    } else {
      return DateFormat('dd/MM/yy').format(date);
    }
  }

  Future<Map<String, dynamic>?> _getUserData(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      return doc.data();
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Usuario no autenticado')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: showBackButton
          ? AppBar(
              backgroundColor: AppColors.scaffoldBackground,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                'Mensajes',
                style: AppTextStyles.h6.copyWith(fontWeight: FontWeight.bold),
              ),
            )
          : null,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Modern Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              child: Text(
                'Mensajes',
                style: AppTextStyles.h2.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 32,
                ),
              ),
            ),

            // Chat List
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('chats')
                    .where('participantIds', arrayContains: currentUser.uid)
                    .orderBy('lastTimestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            size: 64,
                            color: AppColors.error.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Error al cargar chats',
                            style: AppTextStyles.h6,
                          ),
                        ],
                      ),
                    );
                  }

                  final chats = snapshot.data?.docs ?? [];

                  if (chats.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline_rounded,
                              size: 80,
                              color: AppColors.textSoft.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'No tienes conversaciones',
                              style: AppTextStyles.h5.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Postúlate a trabajos para comenzar a chatear',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textSoft,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    itemCount: chats.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final chat = chats[index];
                      final chatData = chat.data() as Map<String, dynamic>;
                      final chatId = chat.id;

                      final participantIds = List<String>.from(chatData['participantIds'] ?? []);
                      final otherUserId = participantIds.firstWhere(
                        (id) => id != currentUser.uid,
                        orElse: () => '',
                      );

                      final jobTitle = chatData['jobTitle'] ?? 'Trabajo';
                      final lastMessage = chatData['lastMessage'] ?? '';
                      final lastTimestamp = chatData['lastTimestamp'] as Timestamp?;

                      return FutureBuilder<Map<String, dynamic>?>(
                        future: _getUserData(otherUserId),
                        builder: (context, userSnapshot) {
                          String otherUserName = 'Usuario';
                          if (userSnapshot.hasData && userSnapshot.data != null) {
                            otherUserName = userSnapshot.data!['fullName'] ?? 
                                           userSnapshot.data!['name'] ?? 
                                           'Usuario';
                          }

                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChatScreen(
                                    chatId: chatId,
                                    otherUserName: otherUserName,
                                    jobTitle: jobTitle,
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 12,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  // Avatar
                                  CircleAvatar(
                                    radius: 28,
                                    backgroundColor: AppColors.primaryLight,
                                    child: Text(
                                      otherUserName.isNotEmpty 
                                          ? otherUserName[0].toUpperCase()
                                          : 'U',
                                      style: AppTextStyles.h5.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),

                                  const SizedBox(width: 16),

                                  // Content
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // User Name
                                        Text(
                                          otherUserName,
                                          style: AppTextStyles.bodyLarge.copyWith(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 6),

                                        // Last Message
                                        Text(
                                          lastMessage.isEmpty ? 'Sin mensajes' : lastMessage,
                                          style: AppTextStyles.bodySmall.copyWith(
                                            color: AppColors.textTertiary,
                                            fontSize: 14,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(width: 12),

                                  // Time
                                  Text(
                                    _formatTimestamp(lastTimestamp),
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.textTertiary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
