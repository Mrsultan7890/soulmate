import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../services/auth_service.dart';
import '../../utils/api_constants.dart';
import '../../utils/theme.dart';

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
        headers: {'Authorization': 'Bearer ${authService.token}'},
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
      await http.put(
        Uri.parse('${ApiConstants.baseUrl}/api/settings/'),
        headers: {
          'Authorization': 'Bearer ${authService.token}',
          'Content-Type': 'application/json',
        },
        body: json.encode({setting: value}),
      );
    } catch (e) {
      print('Error updating setting: $e');
      // Revert the change
      _loadSettings();
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
                
                const SizedBox(height: 16),
                
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
                
                // Privacy Settings Section
                _buildSectionHeader('Privacy Settings'),
                _buildSettingTile(
                  title: 'Notifications',
                  subtitle: 'Receive push notifications',
                  value: _notificationsEnabled,
                  onChanged: (value) {
                    setState(() => _notificationsEnabled = value);
                    _updateSetting('notifications_enabled', value);
                  },
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
}