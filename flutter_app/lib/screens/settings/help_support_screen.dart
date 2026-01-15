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
                'Go to Settings > Face Verification and follow the instructions to verify your identity using your camera.',
              ),
              _buildFAQItem(
                'How does matching work?',
                'Our algorithm matches you with users based on your preferences, location, and interests. Swipe right to like, left to pass.',
              ),
              _buildFAQItem(
                'Can I change my location?',
                'Yes, you can update your location in the Edit Profile section. This will affect who you see and who can see you.',
              ),
              _buildFAQItem(
                'How do I report someone?',
                'Go to their profile and tap the report button, or contact our support team directly.',
              ),
              _buildFAQItem(
                'How do I delete my account?',
                'Contact our support team at support@heartlink.app to request account deletion.',
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
                () => _showContactDialog(context, 'Email', 'support@heartlink.app'),
              ),
              _buildContactOption(
                'Live Chat',
                'Chat with our support team',
                Icons.chat,
                () => _showContactDialog(context, 'Live Chat', 'Coming soon!'),
              ),
              _buildContactOption(
                'FAQ',
                'Browse frequently asked questions',
                Icons.quiz,
                () => _showFAQDialog(context),
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
}