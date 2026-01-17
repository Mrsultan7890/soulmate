import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../services/auth_service.dart';
import '../../services/chat_service.dart';
import '../../utils/theme.dart';
import '../../utils/api_constants.dart';
import '../call/video_call_screen.dart';
import '../user/user_profile_view_screen.dart';
import '../location/location_sharing_screen.dart';

class ChatScreen extends StatefulWidget {
  final Map<String, dynamic> match;

  const ChatScreen({super.key, required this.match});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final chatService = Provider.of<ChatService>(context, listen: false);
    
    if (authService.token != null) {
      await chatService.fetchMessages(authService.token!, widget.match['id']);
      _scrollToBottom();
      _updateActivity();
    }
  }

  Future<void> _updateActivity() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    if (authService.token == null) return;
    
    try {
      await http.post(
        Uri.parse('${ApiConstants.baseUrl}/api/profile/update-activity'),
        headers: {'Authorization': 'Bearer ${authService.token}'},
      );
    } catch (e) {
      print('Activity update error: $e');
    }
  }

  Future<Map<String, dynamic>> _getActivityStatus(int userId) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    if (authService.token == null) return {'status': 'Offline', 'is_online': false};
    
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/api/profile/activity-status/$userId'),
        headers: {'Authorization': 'Bearer ${authService.token}'},
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      print('Activity status error: $e');
    }
    return {'status': 'Offline', 'is_online': false};
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final authService = Provider.of<AuthService>(context, listen: false);
    final chatService = Provider.of<ChatService>(context, listen: false);
    
    final content = _messageController.text.trim();
    _messageController.clear();

    if (authService.token != null) {
      await chatService.sendMessage(
        token: authService.token!,
        matchId: widget.match['id'],
        content: content,
      );
      _scrollToBottom();
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final otherUser = widget.match['other_user'];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => UserProfileViewScreen(userId: otherUser['id']),
              ),
            );
          },
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
                backgroundImage: otherUser['profile_images'] != null && 
                                (otherUser['profile_images'] as List).isNotEmpty
                    ? NetworkImage((otherUser['profile_images'] as List)[0])
                    : null,
                child: otherUser['profile_images'] == null || 
                       (otherUser['profile_images'] as List).isEmpty
                    ? const Icon(Icons.person, color: AppTheme.primaryColor)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      otherUser['name'] ?? 'Unknown',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    FutureBuilder<Map<String, dynamic>>(
                      future: _getActivityStatus(otherUser['id']),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          final isOnline = snapshot.data!['is_online'] ?? false;
                          final status = snapshot.data!['status'] ?? '';
                          return Row(
                            children: [
                              if (isOnline)
                                Container(
                                  width: 8,
                                  height: 8,
                                  margin: const EdgeInsets.only(right: 4),
                                  decoration: const BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              Text(
                                status,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isOnline ? Colors.green : AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          );
                        }
                        return Text(
                          'Loading...',
                          style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.location_on, color: AppTheme.primaryColor),
            onPressed: () => _showLocationShareDialog(),
          ),
          IconButton(
            icon: const Icon(Icons.videocam, color: AppTheme.primaryColor),
            onPressed: () => _startVideoCall(),
          ),
          IconButton(
            icon: const Icon(Icons.call, color: AppTheme.primaryColor),
            onPressed: () => _startAudioCall(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Consumer<ChatService>(
              builder: (context, chatService, child) {
                final messages = chatService.getMessagesForMatch(widget.match['id']);

                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.favorite, color: Colors.white, size: 40),
                        ),
                        const SizedBox(height: 16),
                        Text('Say Hi to ${otherUser['name']}!', style: Theme.of(context).textTheme.headlineMedium),
                        const SizedBox(height: 8),
                        Text('Start your conversation', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message['sender_id'] == authService.currentUser!.id;
                    
                    return _buildMessageBubble(message, isMe);
                  },
                );
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(dynamic message, bool isMe) {
    final isLocationMessage = message['message_type'] == 'location';
    
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: () => _showMessageOptions(message, isMe),
        onTap: isLocationMessage ? () => _viewSharedLocation(message) : null,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
          decoration: BoxDecoration(
            gradient: isMe ? AppTheme.primaryGradient : null,
            color: isMe ? null : (isLocationMessage ? Colors.orange[100] : Colors.grey[200]),
            borderRadius: BorderRadius.circular(20),
            border: isLocationMessage ? Border.all(color: Colors.orange, width: 1) : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isLocationMessage)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.location_on,
                      color: isMe ? Colors.white : Colors.orange,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Live Location',
                      style: TextStyle(
                        color: isMe ? Colors.white : Colors.orange,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              if (isLocationMessage) const SizedBox(height: 4),
              Text(
                message['content'] ?? '',
                style: TextStyle(
                  color: isMe ? Colors.white : AppTheme.textPrimary,
                  fontSize: 14,
                ),
              ),
              if (isLocationMessage)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Tap to view location',
                    style: TextStyle(
                      color: isMe ? Colors.white70 : Colors.orange[700],
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    () {
                      try {
                        if (message['created_at'] != null) {
                          final timestamp = DateTime.parse(message['created_at']);
                          print('Message timestamp: ${message['created_at']}, Parsed: $timestamp');
                          return timeago.format(timestamp);
                        } else {
                          print('Message created_at is null');
                          return 'Just now';
                        }
                      } catch (e) {
                        print('Error parsing timestamp: $e, Raw: ${message['created_at']}');
                        return 'Just now';
                      }
                    }(),
                    style: TextStyle(
                      color: isMe ? Colors.white.withOpacity(0.7) : AppTheme.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                  if (isMe) ...[
                    const SizedBox(width: 4),
                    Icon(
                      message['is_read'] == true ? Icons.done_all : Icons.done,
                      size: 12,
                      color: message['is_read'] == true ? Colors.blue : Colors.white.withOpacity(0.7),
                    ),
                  ],
                  if (message['reactions'] != null && (message['reactions'] as Map).isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Text(
                      (message['reactions'] as Map).values.join(' '),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMessageOptions(dynamic message, bool isMe) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.emoji_emotions, color: AppTheme.primaryColor),
              title: const Text('React'),
              onTap: () {
                Navigator.pop(context);
                _showReactionPicker(message);
              },
            ),
            if (isMe) ...[
              ListTile(
                leading: const Icon(Icons.delete, color: AppTheme.errorColor),
                title: const Text('Delete for me'),
                onTap: () {
                  Navigator.pop(context);
                  _deleteMessage(message['id'], false);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_forever, color: AppTheme.errorColor),
                title: const Text('Delete for everyone'),
                onTap: () {
                  Navigator.pop(context);
                  _deleteMessage(message['id'], true);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showReactionPicker(dynamic message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('React to message'),
        content: Wrap(
          spacing: 16,
          children: ['❤️', '😂', '😮', '😢', '😡', '👍'].map((emoji) {
            return GestureDetector(
              onTap: () {
                Navigator.pop(context);
                _addReaction(message['id'], emoji);
              },
              child: Text(emoji, style: const TextStyle(fontSize: 32)),
            );
          }).toList(),
        ),
      ),
    );
  }

  Future<void> _addReaction(int messageId, String emoji) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    if (authService.token != null) {
      // Call backend API to add reaction
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reacted with $emoji')),
      );
    }
  }

  Future<void> _deleteMessage(int messageId, bool forEveryone) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    if (authService.token != null) {
      // Call backend API to delete message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(forEveryone ? 'Message deleted for everyone' : 'Message deleted')),
      );
    }
  }

  void _startVideoCall() {
    final otherUser = widget.match['other_user'];
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoCallScreen(
          otherUserId: otherUser['id'],
          otherUserName: otherUser['name'],
          isVideoCall: true,
        ),
      ),
    );
  }

  void _startAudioCall() {
    final otherUser = widget.match['other_user'];
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoCallScreen(
          otherUserId: otherUser['id'],
          otherUserName: otherUser['name'],
          isVideoCall: false,
        ),
      ),
    );
  }

  void _showLocationShareDialog() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController phoneController = TextEditingController();
    int selectedHours = 2;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Share Live Location'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Share your live location for safety during your date.'),
                const SizedBox(height: 16),
                const Text('Duration:', style: TextStyle(fontWeight: FontWeight.bold)),
                DropdownButton<int>(
                  value: selectedHours,
                  isExpanded: true,
                  items: [1, 2, 3, 4, 6, 8].map((hours) {
                    return DropdownMenuItem(
                      value: hours,
                      child: Text('$hours hour${hours > 1 ? "s" : ""}'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedHours = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                const Text('Emergency Contact (Optional):', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _shareLocation(
                  selectedHours,
                  nameController.text.trim(),
                  phoneController.text.trim(),
                );
              },
              child: const Text('Share Location'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareLocation(int hours, String emergencyName, String emergencyPhone) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final chatService = Provider.of<ChatService>(context, listen: false);
    if (authService.token == null) return;

    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/api/profile/share-location'),
        headers: {
          'Authorization': 'Bearer ${authService.token}',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'shared_with_user_id': widget.match['other_user']['id'],
          'duration_hours': hours,
          'emergency_contact_name': emergencyName.isNotEmpty ? emergencyName : null,
          'emergency_contact_phone': emergencyPhone.isNotEmpty ? emergencyPhone : null,
        }),
      );

      if (response.statusCode == 200) {
        // Send location share message to chat
        String locationMessage = '📍 I shared my live location for $hours hours';
        if (emergencyName.isNotEmpty) {
          locationMessage += '\nEmergency contact: $emergencyName';
        }
        
        await chatService.sendMessage(
          token: authService.token!,
          matchId: widget.match['id'],
          content: locationMessage,
          messageType: 'location',
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location shared successfully')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _viewSharedLocation(dynamic message) {
    final otherUser = widget.match['other_user'];
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LocationSharingScreen(
          otherUserId: otherUser['id'],
          otherUserName: otherUser['name'],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    hintText: 'Type a message...',
                    border: InputBorder.none,
                  ),
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: const BoxDecoration(
                gradient: AppTheme.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: _sendMessage,
                icon: const Icon(Icons.send, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
