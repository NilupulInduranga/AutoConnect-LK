import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme.dart';
import '../../../core/responsive_utils.dart';
import '../data/chat_provider.dart';

class ConversationListScreen extends ConsumerWidget {
  const ConversationListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationsAsync = ref.watch(conversationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Messages', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: conversationsAsync.when(
        data: (conversations) {
          if (conversations.isEmpty) {
            return Center(child: Text('No messages yet', style: TextStyle(color: Colors.grey, fontSize: 14.sp)));
          }
          return RefreshIndicator(
            onRefresh: () async => ref.refresh(conversationsProvider),
            child: ListView.separated(
              itemCount: conversations.length,
              separatorBuilder: (_, __) => Divider(height: 1.h),
              itemBuilder: (context, index) {
                 final conversation = conversations[index];
                 final name = conversation.otherUserName ?? 'Unknown User';
                 final avatar = conversation.otherUserAvatar;
                 
                 return ListTile(
                   contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
                   leading: CircleAvatar(
                      radius: 24.r,
                      backgroundImage: avatar != null ? CachedNetworkImageProvider(avatar) : null,
                      child: avatar == null ? Text(name[0], style: TextStyle(fontSize: 14.sp)) : null,
                   ),
                   title: Text(name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15.sp)),
                   subtitle: Text('Tap to chat', style: TextStyle(color: Colors.grey, fontSize: 12.sp)),
                   trailing: Icon(Icons.arrow_forward_ios, size: 14.r, color: Colors.grey),
                   onTap: () {
                      context.push('/chat', extra: {
                        'id': conversation.id,
                        'name': name,
                        'other_uid': conversation.otherUserId,
                      });
                   },
                 );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err', style: TextStyle(fontSize: 14.sp))),
      ),
    );
  }
}
