import 'package:flutter/material.dart';
import '../../utils/theme.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Icon(Icons.help_outline, size: 60, color: AppTheme.primaryColor),
                    const SizedBox(height: 16),
                    Text(
                      'How can we help you?',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Find answers to common questions or contact our support team',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Frequently Asked Questions',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              _buildFAQItem(
                'How do I verify my profile?',
                'Upload clear photos and complete your profile information. Our team reviews profiles to ensure authenticity.',
              ),
              _buildFAQItem(
                'How does the Feed work?',
                'Your profile photos appear in other users\' feeds. They can like and save your photos. You can control feed visibility in Settings.',
              ),
              _buildFAQItem(
                'How does matching work?',
                'Our algorithm matches you based on preferences, location, and interests. Swipe right to like, left to pass.',
              ),
              _buildFAQItem(
                'Can I change my location?',
                'Location is automatically detected via GPS for accuracy. You can update it by moving to a new location and refreshing the app.',
              ),
              _buildFAQItem(
                'What is Friend Zone game?',
                'A multiplayer game where you can create zones, invite friends, play bottle spin, ask questions, and chat live with voice support.',
              ),
              _buildFAQItem(
                'How do video calls work?',
                'Once matched, you can start video/audio calls directly from the chat screen. Calls use P2P technology for privacy.',
              ),
              _buildFAQItem(
                'How do I report someone?',
                'Tap the three dots on their profile or in chat, select "Report", choose a reason, and submit. We review all reports promptly.',
              ),
              _buildFAQItem(
                'How do I delete my account?',
                'Go to Settings > Account > Delete Account. This action is permanent and cannot be undone.',
              ),
              _buildFAQItem(
                'Why can\'t I see some users?',
                'Users may have restricted their visibility, or they might be outside your preference filters or location range.',
              ),
              _buildFAQItem(
                'How do I turn off notifications?',
                'Go to Settings > Notifications to customize which notifications you receive.',
              ),
              const SizedBox(height: 24),
              Text(
                'Contact Support',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              _buildContactOption(
                'Email Support',
                'Get help via email',
                Icons.email,
                () => _showContactDialog(context, 'Email Support', 'Send your questions to:\nsupport@heartlink.app\n\nWe typically respond within 24 hours.'),
              ),
              _buildContactOption(
                'Report Bug',
                'Report technical issues',
                Icons.bug_report,
                () => _showContactDialog(context, 'Bug Report', 'Found a bug? Help us improve!\n\nEmail: bugs@heartlink.app\nInclude: Device model, app version, and steps to reproduce.'),
              ),
              _buildContactOption(
                'Feature Request',
                'Suggest new features',
                Icons.lightbulb_outline,
                () => _showContactDialog(context, 'Feature Request', 'Have an idea? We\'d love to hear it!\n\nEmail: features@heartlink.app\nTell us what you\'d like to see in HeartLink.'),
              ),
              _buildContactOption(
                'Safety Center',
                'Learn about safety features',
                Icons.security,
                () => _showSafetyDialog(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ExpansionTile(
        title: Text(question, style: const TextStyle(fontWeight: FontWeight.w500)),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              answer,
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactOption(String title, String subtitle, IconData icon, VoidCallback onTap) {
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

  void _showContactDialog(BuildContext context, String method, String info) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(method),
        content: Text(info),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showFAQDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('More Help'),
        content: const Text('Visit our website at www.heartlink.app/help for more detailed guides and tutorials.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
  
  void _showSafetyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Safety Tips'),
        content: const Text(
          '• Never share personal information\n'
          '• Meet in public places\n'
          '• Trust your instincts\n'
          '• Report suspicious behavior\n'
          '• Use in-app video calls first\n'
          '• Tell someone about your plans'
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