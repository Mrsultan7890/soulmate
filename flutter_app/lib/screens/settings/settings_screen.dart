import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../utils/theme.dart';

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
              _buildTile(Icons.person, 'Edit Profile', () {}),
              _buildTile(Icons.lock, 'Change Password', () {}),
              _buildTile(Icons.email, 'Email Preferences', () {}),
            ]),
            const SizedBox(height: 16),
            _buildSection(context, 'Privacy', [
              _buildTile(Icons.visibility_off, 'Photo Privacy', () {}),
              _buildTile(Icons.block, 'Blocked Users', () {}),
              _buildTile(Icons.security, 'Safety Center', () {}),
            ]),
            const SizedBox(height: 16),
            _buildSection(context, 'Notifications', [
              _buildSwitchTile('New Matches', true, (val) {}),
              _buildSwitchTile('Messages', true, (val) {}),
              _buildSwitchTile('Likes', false, (val) {}),
            ]),
            const SizedBox(height: 16),
            _buildSection(context, 'About', [
              _buildTile(Icons.info, 'About HeartLink', () {}),
              _buildTile(Icons.privacy_tip, 'Privacy Policy', () {}),
              _buildTile(Icons.description, 'Terms of Service', () {}),
              _buildTile(Icons.help, 'Help & Support', () {}),
            ]),
            const SizedBox(height: 16),
            _buildSection(context, 'Account Actions', [
              _buildTile(Icons.logout, 'Logout', () async {
                final authService = Provider.of<AuthService>(context, listen: false);
                await authService.logout();
                if (context.mounted) Navigator.of(context).pushReplacementNamed('/login');
              }, isDestructive: true),
              _buildTile(Icons.delete_forever, 'Delete Account', () {}, isDestructive: true),
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
}
