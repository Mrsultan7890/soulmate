import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/match_service.dart';
import '../../utils/theme.dart';
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
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.search),
            label: const Text('Start Swiping'),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchCard(dynamic match) {
    final otherUser = match['other_user'];
    final matchId = match['id'];
    
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
        leading: CircleAvatar(
          radius: 30,
          backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
          backgroundImage: otherUser['profile_images'] != null && 
                          (otherUser['profile_images'] as List).isNotEmpty
              ? NetworkImage((otherUser['profile_images'] as List)[0])
              : null,
          child: otherUser['profile_images'] == null || 
                 (otherUser['profile_images'] as List).isEmpty
              ? const Icon(Icons.person, color: AppTheme.primaryColor)
              : null,
        ),
        title: Text(
          '${otherUser['name']}, ${otherUser['age'] ?? ''}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          otherUser['bio'] ?? 'No bio available',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
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

  void _openChat(int matchId, Map<String, dynamic> otherUser) {
    // Create a simplified match object for chat
    final matchForChat = {
      'id': matchId,
      'other_user': otherUser,
    };
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(match: matchForChat),
      ),
    );
  }
}