import 'package:flutter/material.dart';
import '../../utils/theme.dart';
import 'blocked_users_screen.dart';

class SafetyCenterScreen extends StatelessWidget {
  const SafetyCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Safety Center'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSafetyTip(
                'Stay Safe Online',
                'Never share personal information like your phone number, address, or financial details.',
                Icons.security,
              ),
              _buildSafetyTip(
                'Meet in Public',
                'Always meet new people in public places for your first few dates.',
                Icons.public,
              ),
              _buildSafetyTip(
                'Trust Your Instincts',
                'If something feels wrong, trust your gut and remove yourself from the situation.',
                Icons.psychology,
              ),
              _buildSafetyTip(
                'Report Suspicious Behavior',
                'Help keep our community safe by reporting users who violate our guidelines.',
                Icons.report,
              ),
              const SizedBox(height: 24),
              _buildSafetyAction(
                context,
                'Blocked Users',
                'Manage users you have blocked',
                Icons.block,
                () => Navigator.push(context, MaterialPageRoute(builder: (context) => const BlockedUsersScreen())),
              ),
              _buildSafetyAction(
                context,
                'Report a User',
                'Report inappropriate behavior',
                Icons.flag,
                () => _showReportDialog(context),
              ),
              _buildSafetyAction(
                context,
                'Safety Guidelines',
                'Learn about staying safe on HeartLink',
                Icons.menu_book,
                () => _showSafetyGuidelines(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSafetyTip(String title, String description, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
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
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppTheme.primaryColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                const SizedBox(height: 4),
                Text(description, style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyAction(BuildContext context, String title, String subtitle, IconData icon, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppTheme.primaryColor, size: 20),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
        onTap: onTap,
      ),
    );
  }

  void _showReportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report a User'),
        content: const Text('To report a user, go to their profile and tap the report button, or contact our support team.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSafetyGuidelines(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Safety Guidelines'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('• Never share personal information'),
              SizedBox(height: 8),
              Text('• Meet in public places'),
              SizedBox(height: 8),
              Text('• Tell someone where you\'re going'),
              SizedBox(height: 8),
              Text('• Trust your instincts'),
              SizedBox(height: 8),
              Text('• Report suspicious behavior'),
              SizedBox(height: 8),
              Text('• Block users who make you uncomfortable'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}