import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../services/auth_service.dart';
import '../../utils/theme.dart';
import '../../utils/api_constants.dart';
import '../../utils/storage_helper.dart';
import '../profile/edit_profile_screen.dart';
import 'change_password_screen.dart';
import 'blocked_users_screen.dart';
import 'safety_center_screen.dart';
import 'notification_settings_screen.dart';
import 'about_screen.dart';
import 'privacy_policy_screen.dart';
import 'help_support_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSection(context, 'Account', [
              _buildTile(Icons.person, 'Edit Profile', () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const EditProfileScreen()));
              }),
              _buildTile(Icons.lock, 'Change Password', () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const ChangePasswordScreen()));
              }),
              _buildTile(Icons.notifications, 'Notifications', () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationSettingsScreen()));
              }),
            ]),
            const SizedBox(height: 16),
            _buildSection(context, 'Privacy & Safety', [
              _buildTile(Icons.block, 'Blocked Users', () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const BlockedUsersScreen()));
              }),
              _buildTile(Icons.security, 'Safety Center', () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const SafetyCenterScreen()));
              }),
            ]),
            const SizedBox(height: 16),
            _buildSection(context, 'About', [
              _buildTile(Icons.info, 'About HeartLink', () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const AboutScreen()));
              }),
              _buildTile(Icons.privacy_tip, 'Privacy Policy', () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen()));
              }),
              _buildTile(Icons.description, 'Terms of Service', () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen()));
              }),
              _buildTile(Icons.help, 'Help & Support', () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const HelpSupportScreen()));
              }),
            ]),
            const SizedBox(height: 16),
            _buildSection(context, 'Account Actions', [
              _buildTile(Icons.logout, 'Logout', () async {
                final authService = Provider.of<AuthService>(context, listen: false);
                await authService.logout();
                if (context.mounted) Navigator.of(context).pushReplacementNamed('/login');
              }, isDestructive: true),
              _buildTile(Icons.delete_forever, 'Delete Account', () {
                _showDeleteAccountDialog(context);
              }, isDestructive: true),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(title, style: Theme.of(context).textTheme.titleLarge),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTile(IconData icon, String title, VoidCallback onTap, {bool isDestructive = false}) {
    return ListTile(
      leading: Icon(icon, color: isDestructive ? AppTheme.errorColor : AppTheme.primaryColor),
      title: Text(title, style: TextStyle(color: isDestructive ? AppTheme.errorColor : AppTheme.textPrimary)),
      trailing: const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile(String title, bool value, Function(bool) onChanged) {
    return SwitchListTile(
      title: Text(title),
      value: value,
      activeColor: AppTheme.primaryColor,
      onChanged: onChanged,
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone and will permanently remove all your data, matches, and messages.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteAccount(context);
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount(BuildContext context) async {
    try {
      final token = await StorageHelper.getToken();
      if (token == null) return;

      final response = await http.delete(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.deleteAccount}'),
        headers: ApiConstants.getHeaders(token: token),
      );

      if (response.statusCode == 200) {
        final authService = Provider.of<AuthService>(context, listen: false);
        await authService.logout();
        if (context.mounted) {
          Navigator.of(context).pushReplacementNamed('/login');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Account deleted successfully')),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete account')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}
