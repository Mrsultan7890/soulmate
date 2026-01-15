import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/theme.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _newMessages = true;
  bool _newMatches = true;
  bool _newLikes = true;
  bool _promotions = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _newMessages = prefs.getBool('notifications_messages') ?? true;
      _newMatches = prefs.getBool('notifications_matches') ?? true;
      _newLikes = prefs.getBool('notifications_likes') ?? true;
      _promotions = prefs.getBool('notifications_promotions') ?? false;
    });
  }

  Future<void> _saveSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
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
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _buildNotificationTile(
                      'New Messages',
                      'Get notified when someone sends you a message',
                      Icons.message,
                      _newMessages,
                      (value) {
                        setState(() => _newMessages = value);
                        _saveSetting('notifications_messages', value);
                      },
                    ),
                    const Divider(height: 1),
                    _buildNotificationTile(
                      'New Matches',
                      'Get notified when you get a new match',
                      Icons.favorite,
                      _newMatches,
                      (value) {
                        setState(() => _newMatches = value);
                        _saveSetting('notifications_matches', value);
                      },
                    ),
                    const Divider(height: 1),
                    _buildNotificationTile(
                      'New Likes',
                      'Get notified when someone likes your profile',
                      Icons.thumb_up,
                      _newLikes,
                      (value) {
                        setState(() => _newLikes = value);
                        _saveSetting('notifications_likes', value);
                      },
                    ),
                    const Divider(height: 1),
                    _buildNotificationTile(
                      'Promotions',
                      'Get notified about special offers and updates',
                      Icons.local_offer,
                      _promotions,
                      (value) {
                        setState(() => _promotions = value);
                        _saveSetting('notifications_promotions', value);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: AppTheme.primaryColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'You can also manage notifications in your device settings',
                        style: TextStyle(color: AppTheme.primaryColor, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationTile(String title, String subtitle, IconData icon, bool value, Function(bool) onChanged) {
    return ListTile(
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
      subtitle: Text(subtitle, style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppTheme.primaryColor,
      ),
    );
  }
}