import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:ui' as ui;
import 'package:hamaltekk/screens/chat_screen.dart'; // مسار شاشة المحادثة

class StaffChatListScreen extends StatefulWidget {
  const StaffChatListScreen({super.key});

  @override
  State<StaffChatListScreen> createState() => _StaffChatListScreenState();
}

class _StaffChatListScreenState extends State<StaffChatListScreen> {
  String searchQuery = '';
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  Widget build(BuildContext context) {
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
              _buildSearchBar(),
              const SizedBox(height: 10),

              // 🌟 جلب مجموعة المشرف أولاً ثم جلب الحجاج
              Expanded(
                child: FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('Users')
                      .doc(currentUserId)
                      .get(),
                  builder: (context, staffSnapshot) {
                    if (staffSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFA07B4F),
                        ),
                      );
                    }

                    var staffData =
                        staffSnapshot.data?.data() as Map<String, dynamic>?;
                    String? groupId = staffData?['group_id'];

                    if (groupId == null) {
                      return const Center(
                        child: Text(
                          'لم يتم تعيينك في مجموعة بعد',
                          style: TextStyle(color: Colors.white54),
                        ),
                      );
                    }

                    // 🌟 الاستماع لقائمة الحجاج في نفس المجموعة
                    return StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('Users')
                          .where('type', isEqualTo: 'p')
                          .where('group_id', isEqualTo: groupId)
                          .snapshots(),
                      builder: (context, pilgrimsSnapshot) {
                        if (pilgrimsSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFFA07B4F),
                            ),
                          );
                        }

                        if (!pilgrimsSnapshot.hasData ||
                            pilgrimsSnapshot.data!.docs.isEmpty) {
                          return const Center(
                            child: Text(
                              'لا يوجد حجاج في مجموعتك حتى الآن',
                              style: TextStyle(color: Colors.white54),
                            ),
                          );
                        }

                        var allPilgrims = pilgrimsSnapshot.data!.docs;

                        // 🌟 فلترة الحجاج بناءً على شريط البحث
                        var filteredPilgrims = allPilgrims.where((doc) {
                          var data = doc.data() as Map<String, dynamic>;
                          String name = data['info']?['name'] ?? 'حاج';
                          return name.toLowerCase().contains(
                            searchQuery.toLowerCase(),
                          );
                        }).toList();

                        if (filteredPilgrims.isEmpty) {
                          return const Center(
                            child: Text(
                              'لم يتم العثور على حاج بهذا الاسم',
                              style: TextStyle(color: Colors.white54),
                            ),
                          );
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 25,
                            vertical: 10,
                          ),
                          itemCount: filteredPilgrims.length,
                          itemBuilder: (context, index) {
                            var pilgrimDoc = filteredPilgrims[index];
                            var pilgrimData =
                                pilgrimDoc.data() as Map<String, dynamic>;
                            String pilgrimId = pilgrimDoc.id;
                            String pilgrimName =
                                pilgrimData['info']?['name'] ?? 'حاج بدون اسم';

                            // معرف المحادثة (نفس الطريقة: رقم المشرف_رقم الحاج)
                            String chatId = '${currentUserId}_$pilgrimId';

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 15),
                              child: _buildChatCard(
                                context,
                                chatId,
                                pilgrimName,
                                pilgrimId,
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
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.only(top: 30, bottom: 15),
      child: Column(
        children: [
          const Text(
            'المحادثات',
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

  // 🌟 شريط البحث الأنيق
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
      child: Directionality(
        textDirection: ui.TextDirection.rtl,
        child: TextField(
          style: const TextStyle(color: Colors.white),
          onChanged: (value) {
            setState(() {
              searchQuery = value;
            });
          },
          decoration: InputDecoration(
            hintText: 'ابحث عن اسم الحاج...',
            hintStyle: const TextStyle(color: Colors.white54, fontSize: 14),
            prefixIcon: const Icon(Icons.search, color: Color(0xFFA07B4F)),
            filled: true,
            fillColor: Colors.black.withOpacity(0.4),
            contentPadding: const EdgeInsets.symmetric(vertical: 15),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(
                color: Color(0xFFA07B4F),
                width: 1.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 🌟 كرت المحادثة الزجاجي (نفس تصميم الحاج بالضبط للتوحيد)
  Widget _buildChatCard(
    BuildContext context,
    String chatId,
    String pilgrimName,
    String pilgrimId,
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
                  otherUserName: pilgrimName,
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
                            pilgrimName,
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
                      Icons
                          .person_outline, // أيقونة شخص واحد لأنها تعبر عن حاج واحد
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
