import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../../services/safety_service.dart';
import '../../utils/theme.dart';

class UserDetailScreen extends StatelessWidget {
  final User user;

  const UserDetailScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 400,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  user.profileImages.isNotEmpty
                      ? Image.network('https://via.placeholder.com/400x600/FF6B9D/FFFFFF?text=${user.name}', fit: BoxFit.cover)
                      : Container(color: AppTheme.primaryColor.withOpacity(0.2), child: const Icon(Icons.person, size: 100, color: AppTheme.primaryColor)),
                  Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withOpacity(0.7)]))),
                ],
              ),
            ),
            actions: [IconButton(icon: const Icon(Icons.more_vert), onPressed: () => _showOptionsMenu(context))],
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(user.name, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                                if (user.isVerified) ...[const SizedBox(width: 8), const Icon(Icons.verified, color: AppTheme.successColor, size: 24)],
                              ],
                            ),
                            if (user.age != null) Text('${user.age} years old', style: TextStyle(fontSize: 16, color: AppTheme.textSecondary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('About', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 12),
                      Text(user.bio ?? 'No bio available', style: Theme.of(context).textTheme.bodyMedium),
                      if (user.relationshipIntent != null) ...[
                        const SizedBox(height: 16),
                        Row(children: [const Icon(Icons.favorite, color: AppTheme.primaryColor, size: 20), const SizedBox(width: 8), Text('Looking for: ${user.relationshipIntent}')]),
                      ],
                    ],
                  ),
                ),
                if (user.interests.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Interests', style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: user.interests.map((i) => Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(gradient: AppTheme.primaryGradient, borderRadius: BorderRadius.circular(20)), child: Text(i, style: const TextStyle(color: Colors.white, fontSize: 12)))).toList(),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildActionButton(Icons.close, AppTheme.errorColor, () => Navigator.pop(context)),
            _buildActionButton(Icons.favorite, AppTheme.primaryColor, () => Navigator.pop(context)),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildActionButton(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5))]),
        child: Icon(icon, color: color, size: 28),
      ),
    );
  }

  void _showOptionsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(leading: const Icon(Icons.report, color: AppTheme.errorColor), title: const Text('Report User'), onTap: () {
              Navigator.pop(context);
              _showReportDialog(context);
            }),
            ListTile(leading: const Icon(Icons.block, color: AppTheme.errorColor), title: const Text('Block User'), onTap: () => Navigator.pop(context)),
          ],
        ),
      ),
    );
  }

  void _showReportDialog(BuildContext context) {
    final reasons = ['Inappropriate content', 'Spam', 'Fake profile', 'Harassment', 'Scam', 'Other'];
    String? selectedReason;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report User'),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: reasons.map((reason) => RadioListTile<String>(title: Text(reason), value: reason, groupValue: selectedReason, onChanged: (value) => setState(() => selectedReason = value))).toList(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              if (selectedReason != null) {
                final authService = Provider.of<AuthService>(context, listen: false);
                final safetyService = Provider.of<SafetyService>(context, listen: false);
                if (authService.token != null) {
                  await safetyService.reportUser(token: authService.token!, reportedUserId: user.id, reason: selectedReason!);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User reported')));
                  }
                }
              }
            },
            child: const Text('Report'),
          ),
        ],
      ),
    );
  }
}
