import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:ui' as ui;
import 'package:hamaltekk/screens/chat_screen.dart';

class PilgrimChatListScreen extends StatelessWidget {
  const PilgrimChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/black.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),

              Expanded(
                // 1. جلب بيانات الحاج لمعرفة مجموعته
                child: FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('Users')
                      .doc(currentUserId)
                      .get(),
                  builder: (context, userSnapshot) {
                    if (userSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFA07B4F),
                        ),
                      );
                    }

                    var userData =
                        userSnapshot.data?.data() as Map<String, dynamic>?;
                    String? groupId = userData?['group_id'];

                    if (groupId == null) {
                      return const Center(
                        child: Text(
                          'لم يتم تعيينك في مجموعة بعد',
                          style: TextStyle(color: Colors.white54),
                        ),
                      );
                    }

                    // 2. جلب المشرف الأساسي للمجموعة
                    return FutureBuilder<QuerySnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('Users')
                          .where('type', isEqualTo: 's')
                          .where('group_id', isEqualTo: groupId)
                          .limit(1)
                          .get(),
                      builder: (context, supervisorSnapshot) {
                        if (supervisorSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFFA07B4F),
                            ),
                          );
                        }

                        String? mainSupervisorId;
                        String mainSupervisorName = 'المشرف';

                        if (supervisorSnapshot.hasData &&
                            supervisorSnapshot.data!.docs.isNotEmpty) {
                          var supervisorDoc =
                              supervisorSnapshot.data!.docs.first;
                          mainSupervisorId = supervisorDoc.id;
                          mainSupervisorName =
                              (supervisorDoc.data()
                                  as Map<String, dynamic>)['info']?['name'] ??
                              'المشرف الأساسي';
                        }

                        // 3. جلب كل المحادثات النشطة الخاصة بالحاج
                        return StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('Chats')
                              .orderBy('last_time', descending: true)
                              .snapshots(),
                          builder: (context, chatSnapshot) {
                            List<Widget> chatCards = [];

                            // 🌟 أولاً: إضافة كارت المشرف الأساسي (دائماً في الأعلى)
                            if (mainSupervisorId != null) {
                              String mainChatId =
                                  '${mainSupervisorId}_$currentUserId';
                              chatCards.add(
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 15),
                                  child: _buildChatCard(
                                    context,
                                    mainChatId,
                                    mainSupervisorName,
                                    currentUserId,
                                  ),
                                ),
                              );
                            }

                            // 🌟 ثانياً: إضافة محادثات مشرفي الباصات (إذا وجدت) وتحت المشرف الأساسي
                            if (chatSnapshot.hasData &&
                                chatSnapshot.data!.docs.isNotEmpty) {
                              var otherChats = chatSnapshot.data!.docs.where((
                                doc,
                              ) {
                                bool involvesCurrentUser = doc.id.contains(
                                  currentUserId,
                                );
                                bool isNotMainSupervisor =
                                    mainSupervisorId == null ||
                                    !doc.id.contains(mainSupervisorId);
                                return involvesCurrentUser &&
                                    isNotMainSupervisor;
                              }).toList();

                              for (var doc in otherChats) {
                                String chatId = doc.id;
                                List<String> ids = chatId.split('_');
                                String otherUserId = ids[0] == currentUserId
                                    ? ids[1]
                                    : ids[0];

                                chatCards.add(
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 15),
                                    child: FutureBuilder<DocumentSnapshot>(
                                      future: FirebaseFirestore.instance
                                          .collection('Users')
                                          .doc(otherUserId)
                                          .get(),
                                      builder: (context, otherUserSnap) {
                                        if (!otherUserSnap.hasData)
                                          return const SizedBox();
                                        String otherName =
                                            (otherUserSnap.data!.data()
                                                as Map<
                                                  String,
                                                  dynamic
                                                >?)?['info']?['name'] ??
                                            'مشرف الرحلة';

                                        return _buildChatCard(
                                          context,
                                          chatId,
                                          otherName,
                                          currentUserId,
                                        );
                                      },
                                    ),
                                  ),
                                );
                              }
                            }

                            return ListView(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 25,
                                vertical: 10,
                              ),
                              children: chatCards,
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
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.only(top: 30, bottom: 20),
      child: Column(
        children: [
          const Text(
            'محادثاتي',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              fontFamily: 'IBMPlexSans',
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 1.5,
            width: 100,
            color: const Color(0xFFA07B4F).withOpacity(0.6),
          ),
        ],
      ),
    );
  }

  // 🌟 دالة بناء الكارد بنفس التصميم المستطيل القديم اللي طلبتيه
  Widget _buildChatCard(
    BuildContext context,
    String chatId,
    String supervisorName,
    String currentUserId,
  ) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Chats')
          .doc(chatId)
          .snapshots(),
      builder: (context, chatSnapshot) {
        String lastMessage = 'اضغط لبدء المحادثة...';

        if (chatSnapshot.hasData && chatSnapshot.data!.exists) {
          var chatData = chatSnapshot.data!.data() as Map<String, dynamic>;
          lastMessage = chatData['last_message'] ?? lastMessage;
        }

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatScreen(
                  chatId: chatId,
                  otherUserName: supervisorName,
                  currentUserId: currentUserId,
                ),
              ),
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 22,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFA07B4F).withOpacity(0.25),
                      const Color(0xFFA07B4F).withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: const Color(0xFFA07B4F).withOpacity(0.3),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'المشرف: $supervisorName',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'IBMPlexSans',
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            lastMessage,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              fontFamily: 'IBMPlexSans',
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 18),
                    const Icon(
                      Icons.people_outline,
                      color: Colors.white,
                      size: 28,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
