import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/chat.dart';

final chatRepositoryProvider = Provider((ref) => ChatRepository(Supabase.instance.client));

class ChatRepository {
  final SupabaseClient _supabase;

  ChatRepository(this._supabase);

  // Get current user ID
  String? get currentUserId => _supabase.auth.currentUser?.id;

  // Get or Create Conversation with a user
  Future<String> getOrCreateConversation(String otherUserId) async {
    final myId = currentUserId;
    if (myId == null) throw Exception('Not logged in');

    // 1. Check if conversation exists
    // We check both combinations (p1=me, p2=other OR p1=other, p2=me)
    final response = await _supabase.from('conversations')
        .select()
        .or('and(participant1_id.eq.$myId,participant2_id.eq.$otherUserId),and(participant1_id.eq.$otherUserId,participant2_id.eq.$myId)')
        .maybeSingle();

    if (response != null) {
      return response['id'] as String;
    }

    // 2. Create new conversation
    // Order IDs to ensure consistency (optional but good practice)
    // Actually, uniqueness constraint unique(participant1_id, participant2_id) might fail if we flip order.
    // Our uniqueness constraint doesn't enforce order (unless we added check constraint).
    // Let's just try to insert.
    
    final newConv = await _supabase.from('conversations').insert({
      'participant1_id': myId,
      'participant2_id': otherUserId,
    }).select().single();

    return newConv['id'] as String;
  }


  
  // Helper to fetch conversations with Profiles
  Future<List<Conversation>> fetchConversations() async {
    final myId = currentUserId;
    if (myId == null) return [];

    // Fetch conversations where I am p1 or p2
    final data = await _supabase.from('conversations')
        .select('*, p1:profiles!participant1_id(full_name, avatar_url), p2:profiles!participant2_id(full_name, avatar_url)')
        .or('participant1_id.eq.$myId,participant2_id.eq.$myId');

    return (data as List).map((json) {
      // Manually attach the "other" user profile to 'other_user' key for the model
      final isP1 = json['participant1_id'] == myId;
      final otherProfile = isP1 ? json['p2'] : json['p1'];
      json['other_user'] = otherProfile;
      
      return Conversation.fromJson(json, myId);
    }).toList();
  }

  // Fetch Messages for a conversation (Realtime)
  Stream<List<Message>> getMessages(String conversationId) {
    return _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at')
        .map((maps) => maps.map((map) => Message.fromJson(map)).toList());
  }

  // Stream of unread message count
  // Optimized: Uses receiver_id for direct filtering (efficient for Realtime)
  Stream<int> getUnreadCountStream() {
    final myId = currentUserId;
    if (myId == null) return Stream.value(0);

    return _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .map((data) => data.where((m) => m['receiver_id'] == myId && m['is_read'] == false).length);
  }

  // Mark messages as read for a conversation
  Future<void> markMessagesAsRead(String conversationId) async {
    final myId = currentUserId;
    if (myId == null) return;
    
    // We can now try standard update since RLS is simpler, 
    // but RPC is still safer for "mark as read" logic.
    // Let's stick to RPC or use the new simplified update policy.
    // The new policy "Users can update received messages" allows updating if receiver_id = auth.uid.
    
    await _supabase.from('messages')
        .update({'is_read': true})
        .eq('conversation_id', conversationId)
        .eq('receiver_id', myId)
        .eq('is_read', false);
  }

  // Send Message
  Future<void> sendMessage(String conversationId, String content, String receiverId) async {
    final myId = currentUserId;
    if (myId == null) return;

    await _supabase.from('messages').insert({
      'conversation_id': conversationId,
      'sender_id': myId,
      'receiver_id': receiverId,
      'content': content,
    });
  }
}
