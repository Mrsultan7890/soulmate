import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../services/auth_service.dart';
import '../../utils/theme.dart';
import '../../utils/api_constants.dart';

class LocationSharingScreen extends StatefulWidget {
  final int otherUserId;
  final String otherUserName;

  const LocationSharingScreen({
    super.key,
    required this.otherUserId,
    required this.otherUserName,
  });

  @override
  State<LocationSharingScreen> createState() => _LocationSharingScreenState();
}

class _LocationSharingScreenState extends State<LocationSharingScreen> {
  Map<String, dynamic>? _sharedLocation;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSharedLocation();
  }

  Future<void> _loadSharedLocation() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    if (authService.token == null) return;

    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/api/profile/shared-location/${widget.otherUserId}'),
        headers: {'Authorization': 'Bearer ${authService.token}'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _sharedLocation = data['shared'] ? data : null;
          _loading = false;
        });
      }
    } catch (e) {
      print('Error loading location: $e');
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.otherUserName}\'s Location'),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _sharedLocation == null
              ? _buildNoLocation()
              : _buildLocationView(),
    );
  }

  Widget _buildNoLocation() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_off, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            '${widget.otherUserName} hasn\'t shared location',
            style: const TextStyle(fontSize: 16, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationView() {
    final lat = _sharedLocation!['latitude'];
    final lng = _sharedLocation!['longitude'];
    final expiresAt = DateTime.parse(_sharedLocation!['expires_at']);
    final emergency = _sharedLocation!['emergency_contact'];

    return Column(
      children: [
        Expanded(
          child: Container(
            color: Colors.grey[200],
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.map, size: 80, color: AppTheme.primaryColor),
                  const SizedBox(height: 16),
                  Text(
                    'Location: $lat, $lng',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Expires: ${_formatExpiry(expiresAt)}',
                    style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (emergency != null)
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.orange[50],
            child: Row(
              children: [
                const Icon(Icons.emergency, color: Colors.orange),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Emergency Contact',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text('${emergency['name']} - ${emergency['phone']}'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Opening in maps...')),
              );
            },
            icon: const Icon(Icons.map),
            label: const Text('Open in Maps'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
            ),
          ),
        ),
      ],
    );
  }

  String _formatExpiry(DateTime expiresAt) {
    final now = DateTime.now();
    final diff = expiresAt.difference(now);

    if (diff.inHours > 0) {
      return 'in ${diff.inHours}h ${diff.inMinutes % 60}m';
    } else if (diff.inMinutes > 0) {
      return 'in ${diff.inMinutes}m';
    } else {
      return 'Expired';
    }
  }
}
