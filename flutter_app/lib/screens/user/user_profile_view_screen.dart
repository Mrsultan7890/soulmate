import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/auth_service.dart';
import '../../utils/api_constants.dart';
import '../../utils/theme.dart';

class UserProfileViewScreen extends StatefulWidget {
  final int userId;

  const UserProfileViewScreen({super.key, required this.userId});

  @override
  State<UserProfileViewScreen> createState() => _UserProfileViewScreenState();
}

class _UserProfileViewScreenState extends State<UserProfileViewScreen> {
  Map<String, dynamic>? _userProfile;
  Map<String, dynamic>? _activityStatus;
  bool _isLoading = true;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _trackView();
    _loadActivityStatus();
  }

  Future<void> _loadUserProfile() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    if (authService.token == null) return;

    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/api/users/${widget.userId}/profile'),
        headers: ApiConstants.getHeaders(token: authService.token!),
      );

      if (response.statusCode == 200) {
        setState(() {
          _userProfile = jsonDecode(response.body);
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _trackView() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    if (authService.token == null) return;

    try {
      await http.post(
        Uri.parse('${ApiConstants.baseUrl}/api/users/track-view/${widget.userId}'),
        headers: ApiConstants.getHeaders(token: authService.token!),
      );
    } catch (e) {}
  }

  Future<void> _loadActivityStatus() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    if (authService.token == null) return;

    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/api/profile/activity-status/${widget.userId}'),
        headers: ApiConstants.getHeaders(token: authService.token!),
      );

      if (response.statusCode == 200) {
        setState(() {
          _activityStatus = jsonDecode(response.body);
        });
      }
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
          child: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_userProfile == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(child: Text('User not found')),
      );
    }

    final images = _userProfile!['profile_images'] as List;

    return Scaffold(
      body: Stack(
        children: [
          if (images.isNotEmpty)
            Positioned.fill(
              child: PageView.builder(
                itemCount: images.length,
                onPageChanged: (index) {
                  setState(() => _currentImageIndex = index);
                },
                itemBuilder: (context, index) {
                  return CachedNetworkImage(
                    imageUrl: images[index],
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: AppTheme.primaryColor.withOpacity(0.2),
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: AppTheme.primaryColor.withOpacity(0.2),
                      child: const Icon(Icons.person, size: 100),
                    ),
                  );
                },
              ),
            ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.transparent,
                    Colors.black.withOpacity(0.8),
                  ],
                  stops: const [0.0, 0.3, 1.0],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                      if (images.length > 1)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${_currentImageIndex + 1}/${images.length}',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '${_userProfile!['name']}, ${_userProfile!['age']}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (_userProfile!['is_verified'] == true) ...[ 
                            const SizedBox(width: 8),
                            const Icon(Icons.verified, color: Colors.blue, size: 28),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_userProfile!['job_title'] != null)
                        Row(
                          children: [
                            const Icon(Icons.work, color: Colors.white70, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              _userProfile!['job_title'],
                              style: const TextStyle(color: Colors.white70, fontSize: 16),
                            ),
                          ],
                        ),
                      if (_userProfile!['location'] != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on, color: Colors.white70, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              _userProfile!['location'],
                              style: const TextStyle(color: Colors.white70, fontSize: 16),
                            ),
                          ],
                        ),
                      ],
                      if (_activityStatus != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: _activityStatus!['is_online'] ? Colors.green : Colors.grey,
                                shape: BoxShape.circle,
                              ),
                            ),
                            Text(
                              _activityStatus!['status'],
                              style: TextStyle(
                                color: _activityStatus!['is_online'] ? Colors.green : Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (_userProfile!['bio'] != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          _userProfile!['bio'],
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ],
                      if (_userProfile!['interests'] != null &&
                          (_userProfile!['interests'] as List).isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: (_userProfile!['interests'] as List).map((interest) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white, width: 1),
                              ),
                              child: Text(
                                interest,
                                style: const TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
