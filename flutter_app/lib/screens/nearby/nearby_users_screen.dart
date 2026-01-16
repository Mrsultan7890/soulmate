import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../utils/theme.dart';
import '../../utils/location_helper.dart';
import '../user/user_profile_view_screen.dart';

class NearbyUsersScreen extends StatefulWidget {
  const NearbyUsersScreen({super.key});

  @override
  State<NearbyUsersScreen> createState() => _NearbyUsersScreenState();
}

class _NearbyUsersScreenState extends State<NearbyUsersScreen> {
  double _radius = 5.0;
  bool _isLoadingLocation = false;

  @override
  void initState() {
    super.initState();
    _loadNearbyUsers();
  }

  Future<void> _loadNearbyUsers() async {
    setState(() => _isLoadingLocation = true);
    
    final position = await LocationHelper.getCurrentLocation();
    if (position != null) {
      final authService = Provider.of<AuthService>(context, listen: false);
      final userService = Provider.of<UserService>(context, listen: false);
      
      if (authService.token != null) {
        await userService.updateLocation(authService.token!, position.latitude, position.longitude, null);
        await userService.fetchDiscoverUsers(authService.token!);
      }
    }
    
    setState(() => _isLoadingLocation = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Users'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadNearbyUsers),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: Column(
          children: [
            _buildRadiusSlider(),
            Expanded(
              child: Consumer<UserService>(
                builder: (context, userService, child) {
                  if (_isLoadingLocation || userService.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (userService.discoverUsers.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.location_off, size: 80, color: AppTheme.textSecondary),
                          const SizedBox(height: 16),
                          Text('No users nearby', style: Theme.of(context).textTheme.headlineMedium),
                          const SizedBox(height: 8),
                          Text('Try increasing the radius', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary)),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: userService.discoverUsers.length,
                    itemBuilder: (context, index) {
                      final user = userService.discoverUsers[index];
                      return _buildUserCard(user);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRadiusSlider() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Search Radius: ${_radius.toInt()} km', style: const TextStyle(fontWeight: FontWeight.w600)),
          Slider(
            value: _radius,
            min: 1,
            max: 50,
            divisions: 49,
            activeColor: AppTheme.primaryColor,
            onChanged: (value) => setState(() => _radius = value),
            onChangeEnd: (value) => _loadNearbyUsers(),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(user) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UserProfileViewScreen(userId: user.id),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))]),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: user.profileImages.isNotEmpty
                  ? Image.network(
                      user.firstImage,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 60,
                        height: 60,
                        color: AppTheme.primaryColor.withOpacity(0.2),
                        child: const Icon(Icons.person, color: AppTheme.primaryColor),
                      ),
                    )
                  : Container(
                      width: 60,
                      height: 60,
                      color: AppTheme.primaryColor.withOpacity(0.2),
                      child: const Icon(Icons.person, color: AppTheme.primaryColor),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(user.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      if (user.isVerified) ...[const SizedBox(width: 4), const Icon(Icons.verified, color: AppTheme.successColor, size: 16)],
                    ],
                  ),
                  if (user.age != null) Text('${user.age} years old', style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
                  if (user.location != null) Row(children: [const Icon(Icons.location_on, size: 14, color: AppTheme.textSecondary), Text(user.location!, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary))]),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
          ],
        ),
      ),
    );
  }
}
