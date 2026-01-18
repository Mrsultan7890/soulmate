import 'package:flutter/material.dart';
import '../../utils/theme.dart';

class GameSettingsScreen extends StatefulWidget {
  final int zoneId;

  const GameSettingsScreen({super.key, required this.zoneId});

  @override
  State<GameSettingsScreen> createState() => _GameSettingsScreenState();
}

class _GameSettingsScreenState extends State<GameSettingsScreen> {
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _autoSpin = false;
  int _spinDuration = 3;
  String _gameMode = 'Classic';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('⚙️ Game Settings'),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSettingsCard(
            '🔊 Audio & Vibration',
            [
              _buildSwitchTile(
                'Sound Effects',
                'Play bottle spin and notification sounds',
                _soundEnabled,
                (value) => setState(() => _soundEnabled = value),
                Icons.volume_up,
              ),
              _buildSwitchTile(
                'Vibration',
                'Vibrate on bottle spin and selections',
                _vibrationEnabled,
                (value) => setState(() => _vibrationEnabled = value),
                Icons.vibration,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSettingsCard(
            '🎮 Game Mechanics',
            [
              _buildSwitchTile(
                'Auto Spin',
                'Automatically spin bottle after each turn',
                _autoSpin,
                (value) => setState(() => _autoSpin = value),
                Icons.autorenew,
              ),
              ListTile(
                leading: const Icon(Icons.timer, color: AppTheme.primaryColor),
                title: const Text('Spin Duration'),
                subtitle: Text('${_spinDuration} seconds'),
                trailing: SizedBox(
                  width: 150,
                  child: Slider(
                    value: _spinDuration.toDouble(),
                    min: 1,
                    max: 5,
                    divisions: 4,
                    label: '${_spinDuration}s',
                    onChanged: (value) {
                      setState(() => _spinDuration = value.round());
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSettingsCard(
            '🎯 Game Mode',
            [
              _buildRadioTile(
                'Classic Mode',
                'Traditional Truth or Dare',
                'Classic',
                _gameMode,
                (value) => setState(() => _gameMode = value!),
              ),
              _buildRadioTile(
                'Speed Mode',
                'Quick rounds, faster gameplay',
                'Speed',
                _gameMode,
                (value) => setState(() => _gameMode = value!),
              ),
              _buildRadioTile(
                'Deep Mode',
                'More personal questions',
                'Deep',
                _gameMode,
                (value) => setState(() => _gameMode = value!),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSettingsCard(
            '🛡️ Safety & Privacy',
            [
              ListTile(
                leading: const Icon(Icons.report, color: Colors.orange),
                title: const Text('Report Issue'),
                subtitle: const Text('Report inappropriate behavior'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  _showReportDialog();
                },
              ),
              ListTile(
                leading: const Icon(Icons.exit_to_app, color: Colors.red),
                title: const Text('Leave Zone'),
                subtitle: const Text('Exit this Friend Zone'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  _showLeaveZoneDialog();
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _saveSettings,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Save Settings',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard(String title, List<Widget> children) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
    IconData icon,
  ) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryColor),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppTheme.primaryColor,
      ),
    );
  }

  Widget _buildRadioTile(
    String title,
    String subtitle,
    String value,
    String groupValue,
    ValueChanged<String?> onChanged,
  ) {
    return RadioListTile<String>(
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      groupValue: groupValue,
      onChanged: onChanged,
      activeColor: AppTheme.primaryColor,
    );
  }

  void _showReportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Issue'),
        content: const Text(
          'If someone is behaving inappropriately, please report them. '
          'We take safety seriously and will investigate all reports.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Report submitted. Thank you!')),
              );
            },
            child: const Text('Report'),
          ),
        ],
      ),
    );
  }

  void _showLeaveZoneDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Zone'),
        content: const Text(
          'Are you sure you want to leave this Friend Zone? '
          'You won\'t be able to rejoin unless invited again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Left the zone successfully')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }

  void _saveSettings() {
    // Save settings to backend or local storage
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('⚙️ Settings saved successfully!'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }
}