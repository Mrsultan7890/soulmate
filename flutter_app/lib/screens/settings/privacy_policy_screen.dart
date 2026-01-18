import 'package:flutter/material.dart';
import '../../utils/theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Privacy Policy',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Last updated: December 2024',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildSection(
                    'Information We Collect',
                    '• Profile information (name, age, photos, bio)\n'
                    '• Location data (GPS coordinates for matching)\n'
                    '• Usage data (swipes, matches, messages)\n'
                    '• Device information (for security and optimization)',
                  ),
                  _buildSection(
                    'How We Use Your Information',
                    '• Match you with compatible users nearby\n'
                    '• Show your profile in the Feed (if enabled)\n'
                    '• Enable messaging and video calls\n'
                    '• Improve our matching algorithm\n'
                    '• Ensure platform safety and security',
                  ),
                  _buildSection(
                    'Location Data',
                    'We use GPS location to show you nearby users and help others find you. Location is updated automatically for accuracy. You can control location sharing in Settings.',
                  ),
                  _buildSection(
                    'Feed & Photo Sharing',
                    'Your profile photos may appear in other users\' feeds unless you disable this in Settings. Users can like and save your photos, but cannot download them.',
                  ),
                  _buildSection(
                    'Video Calls & Voice Chat',
                    'Video/audio calls use peer-to-peer technology. We do not record or store call content. Voice chat in games is real-time and not saved.',
                  ),
                  _buildSection(
                    'Data Storage',
                    'Photos are stored securely via Telegram\'s infrastructure. Messages and user data are encrypted. We do not sell your data to third parties.',
                  ),
                  _buildSection(
                    'Your Privacy Controls',
                    '• Control feed visibility\n'
                    '• Manage location sharing\n'
                    '• Block or report users\n'
                    '• Delete your account anytime\n'
                    '• Download your data',
                  ),
                  _buildSection(
                    'Contact Us',
                    'Questions about privacy? Contact us at:\nprivacy@heartlink.app\n\nFor data deletion requests:\ndelete@heartlink.app',
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.security, color: AppTheme.primaryColor),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Your privacy matters. We use minimal data, store it securely, and give you full control over your information.',
                            style: TextStyle(color: AppTheme.primaryColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}