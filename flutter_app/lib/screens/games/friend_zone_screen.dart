import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../services/auth_service.dart';
import '../../utils/theme.dart';
import '../../utils/api_constants.dart';
import 'game_zone_screen.dart';
import 'invite_friends_screen.dart';

class FriendZoneScreen extends StatefulWidget {
  const FriendZoneScreen({super.key});

  @override
  State<FriendZoneScreen> createState() => _FriendZoneScreenState();
}

class _FriendZoneScreenState extends State<FriendZoneScreen> {
  final _zoneNameController = TextEditingController();
  List<Map<String, dynamic>> _myZones = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadMyZones();
  }

  Future<void> _loadMyZones() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    if (authService.token == null) return;

    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/api/games/my-zones'),
        headers: {'Authorization': 'Bearer ${authService.token}'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _myZones = List<Map<String, dynamic>>.from(data['zones']);
        });
      }
    } catch (e) {
      print('Error loading zones: $e');
    }
  }

  Future<void> _createZone() async {
    if (_zoneNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter zone name')),
      );
      return;
    }

    setState(() => _loading = true);

    final authService = Provider.of<AuthService>(context, listen: false);
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/api/games/create-zone'),
        headers: ApiConstants.getHeaders(token: authService.token),
        body: jsonEncode({'zone_name': _zoneNameController.text.trim()}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _zoneNameController.clear();
        _loadMyZones();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🎮 Friend Zone created!')),
        );
        
        // Navigate to zone
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GameZoneScreen(zoneId: data['zone_id']),
          ),
        );
      } else {
        final error = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error['detail'] ?? 'Failed to create zone')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🎮 Friend Zone'),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: Column(
        children: [
          _buildCreateZoneCard(),
          const SizedBox(height: 16),
          Expanded(child: _buildMyZonesList()),
        ],
      ),
    );
  }

  Widget _buildCreateZoneCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF6B6B), Color(0xFFFF8E8E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.pink.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.group_add, color: Colors.white, size: 28),
              SizedBox(width: 12),
              Text(
                'Create Friend Zone',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Create a zone for up to 6 friends to play games together!',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _zoneNameController,
            decoration: InputDecoration(
              hintText: 'Enter zone name...',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
              filled: true,
              fillColor: Colors.white.withOpacity(0.2),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _createZone,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFFFF6B6B),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      '🚀 Create Zone',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyZonesList() {
    if (_myZones.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.games, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No zones yet',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first Friend Zone to start playing!',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _myZones.length,
      itemBuilder: (context, index) {
        final zone = _myZones[index];
        return _buildZoneCard(zone);
      },
    );
  }

  Widget _buildZoneCard(Map<String, dynamic> zone) {
    final isAdmin = zone['role'] == 'admin';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => GameZoneScreen(zoneId: zone['id']),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: isAdmin ? AppTheme.primaryColor : Colors.blue,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Icon(
                    isAdmin ? Icons.admin_panel_settings : Icons.group,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        zone['zone_name'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${zone['current_players']}/6 players • ${isAdmin ? 'Admin' : 'Member'}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      if (isAdmin && zone['current_players'] < 6)
                        TextButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => InviteFriendsScreen(
                                  zoneId: zone['id'],
                                  zoneName: zone['zone_name'],
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.person_add, size: 16),
                          label: const Text('Invite Friends', style: TextStyle(fontSize: 12)),
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.primaryColor,
                            padding: EdgeInsets.zero,
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey[400],
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _zoneNameController.dispose();
    super.dispose();
  }
}