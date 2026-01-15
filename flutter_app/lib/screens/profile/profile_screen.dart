import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../utils/theme.dart';
import '../../widgets/photo_gallery_widget.dart';
import '../../widgets/privacy_settings_widget.dart';
import 'edit_profile_screen.dart';
import '../settings/settings_screen.dart';
import '../settings/settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Consumer<AuthService>(
            builder: (context, authService, child) {
              final user = authService.currentUser;
              if (user == null) return const Center(child: CircularProgressIndicator());

              return SingleChildScrollView(
                child: Column(
                  children: [
                    _buildHeader(context),
                    const SizedBox(height: 20),
                    _buildProfileImage(user.firstImage),
                    const SizedBox(height: 16),
                    Text(
                      user.name,
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                    if (user.age != null)
                      Text(
                        '${user.age} years old',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.textSecondary),
                      ),
                    const SizedBox(height: 24),
                    _buildInfoCard(context, user),
                    const SizedBox(height: 16),
                    const PhotoGalleryWidget(),
                    const SizedBox(height: 16),
                    const PrivacySettingsWidget(),
                    const SizedBox(height: 16),
                    _buildInterestsCard(context, user),
                    const SizedBox(height: 16),
                    _buildSettingsCard(context, authService),
                    const SizedBox(height: 24),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              children: [
                Icon(Icons.person, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Profile', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const EditProfileScreen()),
              );
            },
            icon: const Icon(Icons.edit, color: AppTheme.primaryColor),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileImage(String? imageUrl) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppTheme.primaryGradient,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: const Icon(Icons.person, size: 60, color: Colors.white),
    );
  }

  Widget _buildInfoCard(BuildContext context, user) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('About Me', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          if (user.bio != null && user.bio!.isNotEmpty)
            Text(user.bio!, style: Theme.of(context).textTheme.bodyMedium)
          else
            Text('No bio yet', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary)),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.location_on, user.location ?? 'Not set'),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.email, user.email),
          if (user.relationshipIntent != null) ...[
            const SizedBox(height: 8),
            _buildInfoRow(Icons.favorite, user.relationshipIntent!),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.primaryColor),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
      ],
    );
  }

  Widget _buildInterestsCard(BuildContext context, user) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Interests', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          if (user.interests.isEmpty)
            Text('No interests added', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary))
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: user.interests.map<Widget>((interest) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(interest, style: const TextStyle(color: Colors.white, fontSize: 12)),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard(BuildContext context, AuthService authService) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSettingsTile(Icons.settings, 'Settings', () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
          }),
          _buildSettingsTile(Icons.help, 'Help & Support', () {}),
          _buildSettingsTile(Icons.privacy_tip, 'Privacy Policy', () {}),
          _buildSettingsTile(
            Icons.logout,
            'Logout',
            () async {
              await authService.logout();
              Navigator.of(context).pushReplacementNamed('/login');
            },
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(IconData icon, String title, VoidCallback onTap, {bool isDestructive = false}) {
    return ListTile(
      leading: Icon(icon, color: isDestructive ? AppTheme.errorColor : AppTheme.primaryColor),
      title: Text(title, style: TextStyle(color: isDestructive ? AppTheme.errorColor : AppTheme.textPrimary)),
      trailing: const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
      onTap: onTap,
    );
  }
}
