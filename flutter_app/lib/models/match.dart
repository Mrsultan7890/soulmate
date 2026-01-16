import 'user.dart';

class Match {
  final int id;
  final int user1Id;
  final int user2Id;
  final User user1Profile;
  final User user2Profile;
  final DateTime createdAt;
  final String? lastMessage;
  final DateTime? lastMessageTime;

  Match({
    required this.id,
    required this.user1Id,
    required this.user2Id,
    required this.user1Profile,
    required this.user2Profile,
    required this.createdAt,
    this.lastMessage,
    this.lastMessageTime,
  });

  factory Match.fromJson(Map<String, dynamic> json) {
    // Handle backend response format with 'other_user'
    if (json.containsKey('other_user')) {
      final otherUser = json['other_user'];
      return Match(
        id: json['id'],
        user1Id: json['user1_id'] ?? 0,
        user2Id: json['user2_id'] ?? 0,
        user1Profile: User.fromJson(otherUser),
        user2Profile: User.fromJson(otherUser),
        createdAt: DateTime.parse(json['created_at']),
        lastMessage: json['last_message'],
        lastMessageTime: json['last_message_time'] != null
            ? DateTime.parse(json['last_message_time'])
            : null,
      );
    }
    
    // Handle old format with user1_profile and user2_profile
    return Match(
      id: json['id'],
      user1Id: json['user1_id'],
      user2Id: json['user2_id'],
      user1Profile: User.fromJson(json['user1_profile']),
      user2Profile: User.fromJson(json['user2_profile']),
      createdAt: DateTime.parse(json['created_at']),
      lastMessage: json['last_message'],
      lastMessageTime: json['last_message_time'] != null
          ? DateTime.parse(json['last_message_time'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user1_id': user1Id,
      'user2_id': user2Id,
      'user1_profile': user1Profile.toJson(),
      'user2_profile': user2Profile.toJson(),
      'created_at': createdAt.toIso8601String(),
      'last_message': lastMessage,
      'last_message_time': lastMessageTime?.toIso8601String(),
    };
  }

  User getOtherUser(int currentUserId) {
    return currentUserId == user1Id ? user2Profile : user1Profile;
  }
}

class Message {
  final int id;
  final int matchId;
  final int senderId;
  final String content;
  final String messageType;
  final bool isRead;
  final DateTime createdAt;
  final String senderName;

  Message({
    required this.id,
    required this.matchId,
    required this.senderId,
    required this.content,
    this.messageType = 'text',
    this.isRead = false,
    required this.createdAt,
    required this.senderName,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      matchId: json['match_id'],
      senderId: json['sender_id'],
      content: json['content'],
      messageType: json['message_type'] ?? 'text',
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      senderName: json['sender_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'match_id': matchId,
      'sender_id': senderId,
      'content': content,
      'message_type': messageType,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
      'sender_name': senderName,
    };
  }
}
