import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'dart:ui' as ui;

class ChatScreen extends StatefulWidget {
  final String chatId; // معرف المحادثة (مثلاً: s901_p1001)
  final String otherUserName; // اسم الشخص اللي أكلمه (عشان يظهر فوق)
  final String currentUserId; // معرفي أنا

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.otherUserName,
    required this.currentUserId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // دالة إرسال الرسالة
  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();

    final firestore = FirebaseFirestore.instance;

    // 1. إضافة الرسالة في كولكشن messages الفرعي
    await firestore
        .collection('Chats')
        .doc(widget.chatId)
        .collection('messages')
        .add({
          'text': text,
          'sender_id': widget.currentUserId,
          'timestamp': FieldValue.serverTimestamp(),
          'type': 'text',
        });

    // 2. تحديث الوثيقة الأساسية عشان تظهر آخر رسالة في القوائم الخارجية
    await firestore.collection('Chats').doc(widget.chatId).set(
      {
        'last_message': text,
        'last_time': FieldValue.serverTimestamp(),
        // نقدر نضيف array للمشاركين هنا لو احتجناها مستقبلاً
      },
      SetOptions(merge: true),
    ); // merge عشان ما يمسح البيانات القديمة لو موجودة
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E), // لون خلفية داكن فخم
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D231E),
        elevation: 0,
        centerTitle: true,
        title: Text(
          widget.otherUserName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontFamily: 'IBMPlexSans',
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFFA07B4F)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/black.png'), // النقشة اللي تستخدمينها
            fit: BoxFit.cover,
            opacity: 0.3, // نخففها شوي عشان المحادثة تكون واضحة
          ),
        ),
        child: Column(
          children: [
            // 🌟 منطقة عرض الرسائل
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                // نستمع للرسائل ونرتبها من الأحدث للأقدم
                stream: FirebaseFirestore.instance
                    .collection('Chats')
                    .doc(widget.chatId)
                    .collection('messages')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(
                      child: Text(
                        'حدث خطأ في تحميل الرسائل',
                        style: TextStyle(color: Colors.red),
                      ),
                    );
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFA07B4F),
                      ),
                    );
                  }

                  final messages = snapshot.data?.docs ?? [];

                  if (messages.isEmpty) {
                    return const Center(
                      child: Text(
                        'لا توجد رسائل سابقة. ابدأ المحادثة الآن!',
                        style: TextStyle(color: Colors.white54),
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    reverse: true, // عشان الرسائل الجديدة تطلع تحت زي الواتساب
                    padding: const EdgeInsets.all(15),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msgData =
                          messages[index].data() as Map<String, dynamic>;
                      final bool isMe =
                          msgData['sender_id'] == widget.currentUserId;
                      final String type = msgData['type'] ?? 'text';

                      return _buildMessageBubble(
                        msgData['text'],
                        isMe,
                        msgData['timestamp'],
                        type,
                      );
                    },
                  );
                },
              ),
            ),

            // 🌟 شريط كتابة الرسالة تحت
            _buildMessageInput(),
          ],
        ),
      ),
    );
  }

  // تصميم فقاعة الرسالة (Bubble)
  Widget _buildMessageBubble(
    String text,
    bool isMe,
    Timestamp? timestamp,
    String type,
  ) {
    String timeStr = '';
    if (timestamp != null) {
      timeStr = DateFormat(
        'hh:mm a',
      ).format(timestamp.toDate()).replaceAll('AM', 'ص').replaceAll('PM', 'م');
    }

    // تصميم خاص لو كانت الرسالة أوتوماتيكية (إشعار نظام)
    if (type == 'system_alert') {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 10),
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFA07B4F).withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFA07B4F).withOpacity(0.5)),
          ),
          child: Text(
            text,
            style: const TextStyle(
              color: const Color(0xFFA07B4F),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      );
    }

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12, left: 20, right: 20),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            // لون ذهبي للمرسل، ولون رمادي داكن للمستقبل
            color: isMe ? const Color(0xFFA07B4F) : const Color(0xFF2A2A2A),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(15),
              topRight: const Radius.circular(15),
              bottomLeft: Radius.circular(isMe ? 15 : 0),
              bottomRight: Radius.circular(isMe ? 0 : 15),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                timeStr,
                style: TextStyle(
                  color: isMe ? Colors.white70 : Colors.white54,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // تصميم مربع الإدخال وزر الإرسال
  Widget _buildMessageInput() {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF2D231E),
          border: Border(
            top: BorderSide(color: Colors.white.withOpacity(0.05)),
          ),
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'اكتب رسالتك هنا...',
                    hintStyle: const TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: Colors.black26,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _sendMessage,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: Color(0xFFA07B4F),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.send, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
