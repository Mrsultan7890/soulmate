import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../services/auth_service.dart';
import '../../utils/api_constants.dart';
import '../../utils/theme.dart';
import 'notification_settings_screen.dart';
import 'privacy_policy_screen.dart';
import 'help_support_screen.dart';
import 'safety_center_screen.dart';
import 'blocked_users_screen.dart';
import 'change_password_screen.dart';
import 'about_screen.dart';
import 'advanced_filter_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _loading = true;
  bool _feedVisibility = true;
  bool _showInFeed = true;
  bool _notificationsEnabled = true;
  bool _locationSharing = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    if (authService.token == null) return;

    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/api/settings/'),
        headers: ApiConstants.getHeaders(token: authService.token),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _feedVisibility = data['feed_visibility'] ?? true;
          _showInFeed = data['show_in_feed'] ?? true;
          _notificationsEnabled = data['notifications_enabled'] ?? true;
          _locationSharing = data['location_sharing'] ?? true;
          _loading = false;
        });
      } else {
        print('Failed to load settings: ${response.statusCode}');
        setState(() => _loading = false);
      }
    } catch (e) {
      print('Error loading settings: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _updateSetting(String setting, bool value) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    if (authService.token == null) return;

    try {
      final response = await http.put(
        Uri.parse('${ApiConstants.baseUrl}/api/settings/'),
        headers: ApiConstants.getHeaders(token: authService.token),
        body: json.encode({setting: value}),
      );
      
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Setting updated successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
      } else {
        print('Failed to update setting: ${response.body}');
        _loadSettings(); // Revert on failure
      }
    } catch (e) {
      print('Error updating setting: $e');
      _loadSettings(); // Revert on error
    }
  }

  Future<void> _refreshFeedPosts() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    if (authService.token == null) return;

    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/api/feed/refresh-posts'),
        headers: {'Authorization': 'Bearer ${authService.token}'},
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Feed posts refreshed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error refreshing posts: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to refresh posts'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Feed Settings Section
                _buildSectionHeader('Feed Settings'),
                _buildSettingTile(
                  title: 'Show in Feed',
                  subtitle: 'Allow your photos to appear in other users\' feeds',
                  value: _showInFeed,
                  onChanged: (value) {
                    setState(() => _showInFeed = value);
                    _updateSetting('show_in_feed', value);
                  },
                ),
                _buildSettingTile(
                  title: 'Feed Visibility',
                  subtitle: 'See other users\' photos in your feed',
                  value: _feedVisibility,
                  onChanged: (value) {
                    setState(() => _feedVisibility = value);
                    _updateSetting('feed_visibility', value);
                  },
                ),
                
                // Refresh Feed Posts Button
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ElevatedButton.icon(
                    onPressed: _refreshFeedPosts,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh My Feed Posts'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Account Settings
                _buildSectionHeader('Account'),
                _buildNavigationTile(
                  icon: Icons.edit,
                  title: 'Edit Profile',
                  subtitle: 'Update your profile information',
                  onTap: () => Navigator.pop(context),
                ),
                _buildNavigationTile(
                  icon: Icons.notifications,
                  title: 'Notifications',
                  subtitle: 'Manage notification preferences',
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (context) => const NotificationSettingsScreen(),
                  )),
                ),
                _buildNavigationTile(
                  icon: Icons.lock,
                  title: 'Change Password',
                  subtitle: 'Update your account password',
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (context) => const ChangePasswordScreen(),
                  )),
                ),
                _buildNavigationTile(
                  icon: Icons.info_outline,
                  title: 'Account Info',
                  subtitle: 'View account details and stats',
                  onTap: () => _showAccountInfo(),
                ),
                
                const SizedBox(height: 24),
                
                // Discovery Settings
                _buildSectionHeader('Discovery'),
                _buildNavigationTile(
                  icon: Icons.filter_list,
                  title: 'Discovery Preferences',
                  subtitle: 'Age range, distance, and more',
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (context) => const AdvancedFilterScreen(),
                  )),
                ),
                _buildSettingTile(
                  title: 'Location Sharing',
                  subtitle: 'Allow location-based matching',
                  value: _locationSharing,
                  onChanged: (value) {
                    setState(() => _locationSharing = value);
                    _updateSetting('location_sharing', value);
                  },
                ),
                _buildNavigationTile(
                  icon: Icons.security,
                  title: 'Safety Center',
                  subtitle: 'Safety tips and reporting',
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (context) => const SafetyCenterScreen(),
                  )),
                ),
                _buildNavigationTile(
                  icon: Icons.block,
                  title: 'Blocked Users',
                  subtitle: 'Manage blocked accounts',
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (context) => const BlockedUsersScreen(),
                  )),
                ),
                
                const SizedBox(height: 24),
                
                // Support & Legal
                _buildSectionHeader('Support & Legal'),
                _buildNavigationTile(
                  icon: Icons.help,
                  title: 'Help & Support',
                  subtitle: 'FAQ and contact support',
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (context) => const HelpSupportScreen(),
                  )),
                ),
                _buildNavigationTile(
                  icon: Icons.privacy_tip,
                  title: 'Privacy Policy',
                  subtitle: 'How we handle your data',
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (context) => const PrivacyPolicyScreen(),
                  )),
                ),
                _buildNavigationTile(
                  icon: Icons.info,
                  title: 'About',
                  subtitle: 'App version and information',
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (context) => const AboutScreen(),
                  )),
                ),
                
                const SizedBox(height: 24),
                
                // Logout Button
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Logout'),
                          content: const Text('Are you sure you want to logout?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                Provider.of<AuthService>(context, listen: false).logout();
                                Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                              },
                              child: const Text('Logout', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('Logout'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Delete Account Button
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ElevatedButton.icon(
                    onPressed: () => _showDeleteAccountDialog(),
                    icon: const Icon(Icons.delete_forever),
                    label: const Text('Delete Account'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[700],
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Info Section
                _buildSectionHeader('About Feed'),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'How Feed Works',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '• Your profile photos automatically appear in the feed\n'
                        '• Other users can like and save your photos\n'
                        '• Double-tap to like, swipe up to view profile\n'
                        '• Turn off "Show in Feed" to keep your photos private',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildNavigationTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primaryColor),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.grey[800],
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: SwitchListTile(
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        value: value,
        onChanged: onChanged,
        activeColor: AppTheme.primaryColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }

  Future<void> _showAccountInfo() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/api/settings/account-info'),
        headers: {'Authorization': 'Bearer ${authService.token}'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Account Information'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Email: ${data['email']}'),
                Text('Name: ${data['name']}'),
                Text('Verified: ${data['is_verified'] ? 'Yes' : 'No'}'),
                Text('Total matches: ${data['total_matches']}'),
                Text('Profile views: ${data['profile_views']}'),
              ],
            ),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
          ),
        );
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> _showDeleteAccountDialog() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text('This will permanently delete your account and all data.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteAccount();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    try {
      final response = await http.delete(
        Uri.parse('${ApiConstants.baseUrl}/api/settings/delete-account'),
        headers: {'Authorization': 'Bearer ${authService.token}'},
      );
      if (response.statusCode == 200) {
        authService.logout();
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete account'), backgroundColor: Colors.red),
      );
    }
  }
}