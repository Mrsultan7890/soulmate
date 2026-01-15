import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/match.dart';
import '../utils/api_constants.dart';

class ChatService extends ChangeNotifier {
  final Map<int, List<Message>> _messagesByMatch = {};
  WebSocketChannel? _channel;
  bool _isLoading = false;
  String? _error;

  Map<int, List<Message>> get messagesByMatch => _messagesByMatch;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<Message> getMessagesForMatch(int matchId) {
    return _messagesByMatch[matchId] ?? [];
  }

  Future<void> fetchMessages(String token, int matchId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.messages}/$matchId/messages'),
        headers: ApiConstants.getHeaders(token: token),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _messagesByMatch[matchId] = data.map((msg) => Message.fromJson(msg)).toList();
      } else {
        _error = 'Failed to fetch messages';
      }
    } catch (e) {
      _error = 'Network error: ${e.toString()}';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> sendMessage({
    required String token,
    required int matchId,
    required String content,
    String messageType = 'text',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.sendMessage}/$matchId/messages'),
        headers: ApiConstants.getHeaders(token: token),
        body: jsonEncode({
          'match_id': matchId,
          'content': content,
          'message_type': messageType,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newMessage = Message.fromJson(data);
        
        if (_messagesByMatch[matchId] == null) {
          _messagesByMatch[matchId] = [];
        }
        _messagesByMatch[matchId]!.add(newMessage);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = 'Failed to send message: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  void connectWebSocket(int userId) {
    try {
      _channel = WebSocketChannel.connect(
        Uri.parse('${ApiConstants.websocket}/$userId'),
      );

      _channel!.stream.listen(
        (message) {
          final data = jsonDecode(message);
          if (data['type'] == 'new_message') {
            final newMessage = Message.fromJson(data['message']);
            final matchId = newMessage.matchId;
            
            if (_messagesByMatch[matchId] == null) {
              _messagesByMatch[matchId] = [];
            }
            _messagesByMatch[matchId]!.add(newMessage);
            notifyListeners();
          }
        },
        onError: (error) {
          print('WebSocket error: $error');
        },
        onDone: () {
          print('WebSocket connection closed');
        },
      );
    } catch (e) {
      print('Failed to connect WebSocket: $e');
    }
  }

  void disconnectWebSocket() {
    _channel?.sink.close();
    _channel = null;
  }

  void sendTypingIndicator(int matchId, bool isTyping) {
    if (_channel != null) {
      _channel!.sink.add(jsonEncode({
        'type': 'typing',
        'match_id': matchId,
        'is_typing': isTyping,
      }));
    }
  }

  @override
  void dispose() {
    disconnectWebSocket();
    super.dispose();
  }
}
