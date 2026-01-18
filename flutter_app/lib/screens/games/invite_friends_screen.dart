import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../services/auth_service.dart';
import '../../utils/theme.dart';
import '../../utils/api_constants.dart';

class InviteFriendsScreen extends StatefulWidget {
  final int zoneId;
  final String zoneName;

  const InviteFriendsScreen({
    super.key,
    required this.zoneId,
    required this.zoneName,
  });

  @override
  State<InviteFriendsScreen> createState() => _InviteFriendsScreenState();
}

class _InviteFriendsScreenState extends State<InviteFriendsScreen> {
  List<Map<String, dynamic>> _matches = [];
  List<int> _invitedUsers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMatches();
  }

  Future<void> _loadMatches() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    if (authService.token == null) return;

    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/api/matches/'),
        headers: {'Authorization': 'Bearer ${authService.token}'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _matches = List<Map<String, dynamic>>.from(data);
          _loading = false;
        });
      }
    } catch (e) {
      print('Error loading matches: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _inviteUser(int userId, String userName) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/api/games/invite-user'),
        headers: ApiConstants.getHeaders(token: authService.token),
        body: jsonEncode({
          'zone_id': widget.zoneId,
          'user_id': userId,
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          _invitedUsers.add(userId);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎮 Invitation sent to $userName!'),
            backgroundColor: AppTheme.primaryColor,
          ),
        );
      } else {
        final error = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error['detail'] ?? 'Failed to send invitation')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Invite to ${widget.zoneName}'),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _buildMatchesList(),
    );
  }

  Widget _buildMatchesList() {
    if (_matches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No matches to invite',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Start matching with people to invite them to games!',
              style: TextStyle(color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFF6B6B), Color(0xFFFF8E8E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Invite your matches to join "${widget.zoneName}" and play games together!',
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _matches.length,
            itemBuilder: (context, index) {
              final match = _matches[index];
              final otherUser = match['other_user'];
              final isInvited = _invitedUsers.contains(otherUser['id']);
              
              return _buildMatchCard(otherUser, isInvited);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMatchCard(Map<String, dynamic> user, bool isInvited) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundImage: user['profile_images'] != null && 
                    user['profile_images'].isNotEmpty
                    ? NetworkImage(user['profile_images'][0])
                    : null,
                backgroundColor: AppTheme.primaryColor,
                child: user['profile_images'] == null || 
                    user['profile_images'].isEmpty
                    ? Text(
                        user['name'][0].toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user['name'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (user['age'] != null)
                      Text(
                        '${user['age']} years old',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: isInvited 
                    ? null 
                    : () => _inviteUser(user['id'], user['name']),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isInvited ? Colors.grey : AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  isInvited ? 'Invited' : 'Invite',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}