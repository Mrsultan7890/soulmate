import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../utils/api_constants.dart';

class EnhancedChatService extends ChangeNotifier {
  Map<int, List<EnhancedMessage>> _matchMessages = {};
  bool _isLoading = false;
  String? _error;

  Map<int, List<EnhancedMessage>> get matchMessages => _matchMessages;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<EnhancedMessage> getMessagesForMatch(int matchId) {
    return _matchMessages[matchId] ?? [];
  }

  Future<bool> sendEnhancedMessage({
    required String token,
    required int matchId,
    required String content,
    String messageType = 'text',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.enhancedSendMessage}'),
        headers: ApiConstants.getHeaders(token: token),
        body: jsonEncode({
          'match_id': matchId,
          'content': content,
          'message_type': messageType,
        }),
      );

      if (response.statusCode == 200) {
        // Refresh messages for this match
        await fetchEnhancedMessages(token, matchId);
        return true;
      }
      return false;
    } catch (e) {
      _error = 'Failed to send message: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  Future<void> fetchEnhancedMessages(String token, int matchId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.getMessages}/$matchId/messages'),
        headers: ApiConstants.getHeaders(token: token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final messages = (data['messages'] as List)
            .map((msg) => EnhancedMessage.fromJson(msg))
            .toList();
        
        _matchMessages[matchId] = messages;
      }
    } catch (e) {
      _error = 'Failed to fetch messages: ${e.toString()}';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> markMessageAsRead(String token, int messageId) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.markMessageRead}/$messageId/read'),
        headers: ApiConstants.getHeaders(token: token),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> addMessageReaction({
    required String token,
    required int messageId,
    required String reactionType,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.addReaction}/$messageId/react'),
        headers: ApiConstants.getHeaders(token: token),
        body: jsonEncode({
          'reaction_type': reactionType,
        }),
      );

      if (response.statusCode == 200) {
        // Update local message with new reaction
        _updateMessageReaction(messageId, reactionType);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  void _updateMessageReaction(int messageId, String reactionType) {
    for (var messages in _matchMessages.values) {
      for (var message in messages) {
        if (message.id == messageId) {
          // Update reaction locally (simplified)
          notifyListeners();
          break;
        }
      }
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

class EnhancedMessage {
  final int id;
  final int matchId;
  final int senderId;
  final String content;
  final String messageType;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;
  final Map<String, String> reactions;
  final Map<String, int> reactionSummary;
  final bool isOwnMessage;
  final String senderName;

  EnhancedMessage({
    required this.id,
    required this.matchId,
    required this.senderId,
    required this.content,
    required this.messageType,
    required this.isRead,
    required this.createdAt,
    this.readAt,
    required this.reactions,
    required this.reactionSummary,
    required this.isOwnMessage,
    required this.senderName,
  });

  factory EnhancedMessage.fromJson(Map<String, dynamic> json) {
    return EnhancedMessage(
      id: json['id'],
      matchId: json['match_id'],
      senderId: json['sender_id'],
      content: json['content'],
      messageType: json['message_type'] ?? 'text',
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      readAt: json['read_at'] != null ? DateTime.parse(json['read_at']) : null,
      reactions: Map<String, String>.from(json['reactions'] ?? {}),
      reactionSummary: Map<String, int>.from(json['reaction_summary'] ?? {}),
      isOwnMessage: json['is_own_message'] ?? false,
      senderName: json['sender_name'] ?? 'Unknown',
    );
  }
}