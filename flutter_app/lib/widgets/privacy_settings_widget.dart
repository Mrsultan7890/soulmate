import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../utils/theme.dart';

class PrivacySettingsWidget extends StatefulWidget {
  const PrivacySettingsWidget({super.key});

  @override
  State<PrivacySettingsWidget> createState() => _PrivacySettingsWidgetState();
}

class _PrivacySettingsWidgetState extends State<PrivacySettingsWidget> {
  bool _blurPhotos = true;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthService>(context, listen: false).currentUser;
    _blurPhotos = user?.preferences['blur_photos_until_match'] ?? true;
  }

  Future<void> _updatePrivacy(bool value) async {
    setState(() => _blurPhotos = value);
    
    final authService = Provider.of<AuthService>(context, listen: false);
    if (authService.token != null) {
      // Call API to update privacy
      // await userService.updatePhotoPrivacy(authService.token!, value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Privacy Settings', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Blur photos until match'),
            subtitle: const Text('Your photos will be blurred for users until you match'),
            value: _blurPhotos,
            activeColor: AppTheme.primaryColor,
            onChanged: _updatePrivacy,
          ),
        ],
      ),
    );
  }
}
