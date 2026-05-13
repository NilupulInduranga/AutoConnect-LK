import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme.dart';
import '../../../core/responsive_utils.dart';
import '../../../models/chat.dart';
import '../data/chat_provider.dart';
import '../data/chat_repository.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String conversationId;
  final String otherUserName;
  final String otherUserId;

  const ChatScreen({
    super.key, 
    required this.conversationId, 
    required this.otherUserName,
    required this.otherUserId,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Mark as read when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatRepositoryProvider).markMessagesAsRead(widget.conversationId);
    });
  }

  void _sendMessage() {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;
    
    ref.read(chatRepositoryProvider).sendMessage(
      widget.conversationId, 
      content,
      widget.otherUserId,
    );
    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(messagesProvider(widget.conversationId));
    final myId = Supabase.instance.client.auth.currentUser?.id;

    // Auto-mark as read when new messages arrive while looking at screen
    ref.listen(messagesProvider(widget.conversationId), (previous, next) {
      next.whenData((messages) {
         // Check if there are unread messages from others
         final hasUnread = messages.any((m) => !m.isRead && m.senderId != myId);
         if (hasUnread) {
           ref.read(chatRepositoryProvider).markMessagesAsRead(widget.conversationId);
         }
      });
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.otherUserName, style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                if (messages.isEmpty) {
                   return Center(child: Text('Say hello! 👋', style: TextStyle(color: Colors.grey, fontSize: 14.sp)));
                }
                
                // Sort messages: Newest first
                final sortedMessages = List<Message>.from(messages);
                sortedMessages.sort((a, b) => b.createdAt.compareTo(a.createdAt));
                
                return ListView.builder(
                  reverse: true, // Start from bottom
                  padding: EdgeInsets.all(16.r),
                  itemCount: sortedMessages.length,
                  itemBuilder: (context, index) {
                    final message = sortedMessages[index];
                    final isMe = message.senderId == myId;
                    
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        constraints: BoxConstraints(maxWidth: 0.7.sw), // Max 70% screen width
                        margin: EdgeInsets.symmetric(vertical: 4.h),
                        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                        decoration: BoxDecoration(
                          color: isMe ? AppTheme.primaryColor : Colors.grey[200],
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(16.r),
                            topRight: Radius.circular(16.r),
                            bottomLeft: isMe ? Radius.circular(16.r) : Radius.zero,
                            bottomRight: isMe ? Radius.zero : Radius.circular(16.r),
                          ),
                        ),
                        child: Text(
                          message.content,
                          style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontSize: 13.sp),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err', style: TextStyle(fontSize: 14.sp))),
            ),
          ),
          
          // Input Area
          Container(
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5.r, offset: Offset(0, -2.h))],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: TextStyle(fontSize: 14.sp),
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: TextStyle(fontSize: 14.sp),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(25.r), borderSide: BorderSide.none),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                SizedBox(width: 8.w),
                CircleAvatar(
                  radius: 22.r,
                  backgroundColor: AppTheme.primaryColor,
                  child: IconButton(
                    icon: Icon(Icons.send, color: Colors.white, size: 20.r),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
