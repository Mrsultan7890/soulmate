import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../services/auth_service.dart';
import '../../services/match_service.dart';
import '../../models/match.dart';
import '../../models/user.dart';
import '../../utils/theme.dart';
import '../../utils/api_constants.dart';
import '../chat/chat_screen.dart';

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  @override
  void initState() {
    super.initState();
    _loadMatches();
  }

  Future<void> _loadMatches() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final matchService = Provider.of<MatchService>(context, listen: false);
    
    if (authService.token != null) {
      await matchService.fetchMatches(authService.token!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: Consumer<MatchService>(
                  builder: (context, matchService, child) {
                    if (matchService.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (matchService.error != null) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, size: 60, color: AppTheme.errorColor),
                            SizedBox(height: 16),
                            Text('Error: ${matchService.error}'),
                            SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadMatches,
                              child: Text('Retry'),
                            ),
                          ],
                        ),
                      );
                    }

                    if (matchService.matches.isEmpty) {
                      return _buildEmptyState();
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: matchService.matches.length,
                      itemBuilder: (context, index) {
                        final match = matchService.matches[index];
                        return _buildMatchCard(match);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              children: [
                Icon(Icons.favorite, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Matches', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: _loadMatches,
            icon: const Icon(Icons.refresh, color: AppTheme.primaryColor),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.favorite_border, size: 60, color: AppTheme.primaryColor),
          ),
          const SizedBox(height: 24),
          Text('No matches yet', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text('Keep swiping to find your perfect match!', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // Switch to discover tab (index 0)
              DefaultTabController.of(context).animateTo(0);
            },
            icon: const Icon(Icons.search),
            label: const Text('Start Swiping'),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchCard(Match match) {
    final otherUser = match.user1Profile;
    final matchId = match.id;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
              backgroundImage: otherUser.profileImages.isNotEmpty
                  ? NetworkImage(otherUser.profileImages[0])
                  : null,
              child: otherUser.profileImages.isEmpty
                  ? const Icon(Icons.person, color: AppTheme.primaryColor)
                  : null,
            ),
            FutureBuilder<Map<String, dynamic>>(
              future: _getActivityStatus(otherUser.id),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!['is_online'] == true) {
                  return Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
        title: Text(
          '${otherUser.name}, ${otherUser.age ?? ""}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FutureBuilder<Map<String, dynamic>>(
              future: _getActivityStatus(otherUser.id),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return Text(
                    snapshot.data!['status'],
                    style: TextStyle(
                      fontSize: 12,
                      color: snapshot.data!['is_online'] ? Colors.green : AppTheme.textSecondary,
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            Text(
              otherUser.bio ?? 'No bio available',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        trailing: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.primaryGradient,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            onPressed: () => _openChat(matchId, otherUser),
            icon: const Icon(Icons.chat, color: Colors.white),
          ),
        ),
        onTap: () => _openChat(matchId, otherUser),
      ),
    );
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
    } catch (e) {}
    return {'status': 'Offline', 'is_online': false};
  }

  void _openChat(int matchId, User otherUser) {
    // Create a simplified match object for chat
    final matchForChat = {
      'id': matchId,
      'other_user': {
        'id': otherUser.id,
        'name': otherUser.name,
        'age': otherUser.age,
        'bio': otherUser.bio,
        'profile_images': otherUser.profileImages,
      },
    };
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(match: matchForChat),
      ),
    );
  }
}