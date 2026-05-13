class Conversation {
  final String id;
  final String participant1Id;
  final String participant2Id;
  final DateTime createdAt;
  final String? otherUserName; // For UI convenience
  final String? otherUserAvatar; // For UI convenience
  final String otherUserId; // Helper to know who we are talking to

  Conversation({
    required this.id,
    required this.participant1Id,
    required this.participant2Id,
    required this.createdAt,
    this.otherUserName,
    this.otherUserAvatar,
    required this.otherUserId,
  });

  factory Conversation.fromJson(Map<String, dynamic> json, String myUserId) {
    // Determine which participant is the "other" user
    String otherId = json['participant1_id'] == myUserId 
        ? json['participant2_id'] 
        : json['participant1_id'];
    
    // Attempt to extract joined profile info if available
    String? name;
    String? avatar;
    
    // Note: Supabase joins return data in nested maps. 
    // We expect the query to look like: *, p1:participant1_id(...), p2:participant2_id(...)
    // This logic depends on how the repository constructs the query.
    // simpler approach: The repository will attach the other user's profile to a standard key like 'other_user'
    
    if (json['other_user'] != null) {
      name = json['other_user']['full_name'];
      avatar = json['other_user']['avatar_url'];
    }

    return Conversation(
      id: json['id'],
      participant1Id: json['participant1_id'],
      participant2Id: json['participant2_id'],
      createdAt: DateTime.parse(json['created_at']),
      otherUserName: name,
      otherUserAvatar: avatar,
      otherUserId: otherId,
    );
  }
}

class Message {
  final String id;
  final String conversationId;
  final String senderId;
  final String content;
  final bool isRead;
  final DateTime createdAt;

  Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    required this.isRead,
    required this.createdAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      conversationId: json['conversation_id'],
      senderId: json['sender_id'],
      content: json['content'],
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
