import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../utils/theme.dart';

class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  List<Map<String, dynamic>> _blockedUsers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBlockedUsers();
  }

  Future<void> _loadBlockedUsers() async {
    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));
    
    setState(() {
      _blockedUsers = [
        {
          'id': 1,
          'name': 'John Doe',
          'blocked_at': '2024-01-15',
        },
        {
          'id': 2,
          'name': 'Jane Smith',
          'blocked_at': '2024-01-10',
        },
      ];
      _isLoading = false;
    });
  }

  Future<void> _unblockUser(int userId, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Unblock $name?'),
        content: const Text('This user will be able to see your profile and message you again.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Unblock'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _blockedUsers.removeWhere((user) => user['id'] == userId);
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$name has been unblocked')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Blocked Users'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _blockedUsers.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _blockedUsers.length,
                      itemBuilder: (context, index) {
                        final user = _blockedUsers[index];
                        return _buildBlockedUserCard(user);
                      },
                    ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.block, size: 40, color: AppTheme.primaryColor),
          ),
          const SizedBox(height: 16),
          Text('No blocked users', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text('Users you block will appear here', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildBlockedUserCard(Map<String, dynamic> user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.errorColor.withOpacity(0.1),
          child: const Icon(Icons.person, color: AppTheme.errorColor),
        ),
        title: Text(user['name']),
        subtitle: Text('Blocked on ${user['blocked_at']}'),
        trailing: TextButton(
          onPressed: () => _unblockUser(user['id'], user['name']),
          child: const Text('Unblock', style: TextStyle(color: AppTheme.primaryColor)),
        ),
      ),
    );
  }
}