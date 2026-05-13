import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mobile_app/models/chat.dart';
import 'chat_repository.dart';

// Provider for the list of conversations (Inbox)
final conversationsProvider = FutureProvider<List<Conversation>>((ref) async {
  final repo = ref.watch(chatRepositoryProvider);
  return repo.fetchConversations();
});



// Provider for Auth State
final authStateProvider = StreamProvider<AuthState>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});

// Provider for messages in a specific conversation
final messagesProvider = StreamProvider.family<List<Message>, String>((ref, conversationId) {
  // Ensure we rebuild if auth changes (though less critical for specific chat if ID is passed)
  ref.watch(authStateProvider);
  final repo = ref.watch(chatRepositoryProvider);
  return repo.getMessages(conversationId);
});

// Provider for global unread count
final unreadCountProvider = StreamProvider<int>((ref) {
  // CRITICAL: Watch auth state so this provider rebuilds when user logs in!
  ref.watch(authStateProvider);
  
  final repo = ref.watch(chatRepositoryProvider);
  return repo.getUnreadCountStream();
});
