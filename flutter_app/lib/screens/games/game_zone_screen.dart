import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';
import 'dart:math';
import '../../services/auth_service.dart';
import '../../utils/theme.dart';
import '../../utils/api_constants.dart';

class GameZoneScreen extends StatefulWidget {
  final int zoneId;

  const GameZoneScreen({super.key, required this.zoneId});

  @override
  State<GameZoneScreen> createState() => _GameZoneScreenState();
}

class _GameZoneScreenState extends State<GameZoneScreen>
    with TickerProviderStateMixin {
  Map<String, dynamic>? _zoneData;
  List<Map<String, dynamic>> _members = [];
  bool _loading = true;
  bool _isAdmin = false;
  bool _gameStarted = false;
  
  // Bottle animation
  late AnimationController _bottleController;
  late Animation<double> _bottleAnimation;
  double _currentAngle = 0;
  
  // Game state
  Map<String, dynamic>? _currentPlayer;
  String? _truthQuestion;
  String? _dareChallenge;
  bool _showChoice = false;
  
  WebSocketChannel? _channel;

  @override
  void initState() {
    super.initState();
    _bottleController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _bottleAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _bottleController, curve: Curves.easeOut),
    );
    
    _loadZoneData();
    _connectWebSocket();
  }

  Future<void> _loadZoneData() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    if (authService.token == null) return;

    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/api/games/zone/${widget.zoneId}'),
        headers: {'Authorization': 'Bearer ${authService.token}'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _zoneData = data['zone'];
          _members = List<Map<String, dynamic>>.from(data['members']);
          _isAdmin = data['is_admin'];
          _loading = false;
        });
      }
    } catch (e) {
      print('Error loading zone: $e');
      setState(() => _loading = false);
    }
  }

  void _connectWebSocket() {
    final authService = Provider.of<AuthService>(context, listen: false);
    if (authService.token == null) return;

    try {
      final wsUrl = ApiConstants.baseUrl.replaceFirst('http', 'ws');
      _channel = WebSocketChannel.connect(
        Uri.parse('$wsUrl/api/games/zone/${widget.zoneId}/ws'),
      );

      _channel!.stream.listen((message) {
        final data = json.decode(message);
        _handleWebSocketMessage(data);
      });
    } catch (e) {
      print('WebSocket error: $e');
    }
  }

  void _handleWebSocketMessage(Map<String, dynamic> data) {
    switch (data['type']) {
      case 'member_joined':
        _loadZoneData();
        break;
      case 'game_started':
        setState(() => _gameStarted = true);
        break;
      case 'bottle_spun':
        _handleBottleSpin(data['result']);
        break;
      case 'choice_made':
        _handleChoiceMade(data);
        break;
    }
  }

  void _handleBottleSpin(Map<String, dynamic> result) {
    final targetAngle = result['angle'].toDouble();
    
    _bottleAnimation = Tween<double>(
      begin: _currentAngle,
      end: _currentAngle + 720 + targetAngle, // 2 full spins + target
    ).animate(CurvedAnimation(
      parent: _bottleController,
      curve: Curves.easeOut,
    ));

    _bottleController.reset();
    _bottleController.forward().then((_) {
      setState(() {
        _currentAngle = targetAngle;
        _currentPlayer = result['selected_player'];
        _truthQuestion = result['truth_question'];
        _dareChallenge = result['dare_challenge'];
        _showChoice = true;
      });
    });
  }

  void _handleChoiceMade(Map<String, dynamic> data) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${data['player']['name']} chose ${data['choice']}!'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
    
    setState(() {
      _showChoice = false;
      _currentPlayer = null;
    });
  }

  Future<void> _startGame() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/api/games/zone/${widget.zoneId}/start-game'),
        headers: {'Authorization': 'Bearer ${authService.token}'},
      );

      if (response.statusCode == 200) {
        setState(() => _gameStarted = true);
      }
    } catch (e) {
      print('Error starting game: $e');
    }
  }

  Future<void> _spinBottle() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    try {
      await http.post(
        Uri.parse('${ApiConstants.baseUrl}/api/games/zone/${widget.zoneId}/spin-bottle'),
        headers: {'Authorization': 'Bearer ${authService.token}'},
      );
    } catch (e) {
      print('Error spinning bottle: $e');
    }
  }

  void _makeChoice(String choice) {
    _channel?.sink.add(json.encode({
      'type': 'choice_made',
      'choice': choice,
      'player': _currentPlayer,
    }));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_zoneData?['zone_name'] ?? 'Game Zone'),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: Column(
        children: [
          _buildMembersSection(),
          Expanded(child: _buildGameArea()),
          if (_gameStarted) _buildGameControls(),
        ],
      ),
    );
  }

  Widget _buildMembersSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Players (${_members.length}/6)',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _members.length,
              itemBuilder: (context, index) {
                final member = _members[index];
                return Container(
                  margin: const EdgeInsets.only(right: 12),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: member['role'] == 'admin' 
                            ? AppTheme.primaryColor 
                            : Colors.blue,
                        child: Text(
                          member['name'][0].toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        member['name'],
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameArea() {
    if (!_gameStarted) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sports_esports, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _isAdmin ? 'Start the game when ready!' : 'Waiting for admin to start...',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            if (_isAdmin) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _startGame,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Start Game'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Bottle animation
        AnimatedBuilder(
          animation: _bottleAnimation,
          builder: (context, child) {
            return Transform.rotate(
              angle: _bottleAnimation.value * pi / 180,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey[300]!, width: 2),
                ),
                child: const Center(
                  child: Icon(
                    Icons.local_drink,
                    size: 60,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            );
          },
        ),
        
        const SizedBox(height: 20),
        
        if (_showChoice && _currentPlayer != null) _buildChoiceDialog(),
        
        if (!_showChoice)
          ElevatedButton.icon(
            onPressed: _spinBottle,
            icon: const Icon(Icons.refresh),
            label: const Text('Spin Bottle'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildChoiceDialog() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            '${_currentPlayer!['name']}, choose:',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _makeChoice('Truth'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Truth'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _makeChoice('Dare'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Dare'),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          if (_truthQuestion != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Truth:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(_truthQuestion!),
                ],
              ),
            ),
          
          const SizedBox(height: 8),
          
          if (_dareChallenge != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Dare:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(_dareChallenge!),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGameControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.help_outline),
            tooltip: 'Game Rules',
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _bottleController.dispose();
    _channel?.sink.close();
    super.dispose();
  }
}