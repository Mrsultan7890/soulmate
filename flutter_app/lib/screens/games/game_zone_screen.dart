import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'dart:convert';
import 'dart:math';
import '../../services/auth_service.dart';
import '../../utils/theme.dart';
import '../../utils/api_constants.dart';
import 'game_rules_screen.dart';
import 'game_settings_screen.dart';

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
  String? _currentQuestion;
  Map<String, dynamic>? _answerer;
  bool _showQuestionInput = false;
  final _questionController = TextEditingController();
  final _chatTextController = TextEditingController();
  List<Map<String, dynamic>> _chatMessages = [];
  
  // Chat collapse
  bool _chatExpanded = false;
  late AnimationController _chatAnimationController;
  late Animation<double> _chatAnimation;
  
  // Voice chat
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  bool _isMuted = false;
  bool _voiceConnected = false;
  
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
    
    _chatAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _chatAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _chatAnimationController, curve: Curves.easeInOut),
    );
    
    _loadZoneData();
    _connectWebSocket();
    _initVoiceChat();
    
    // Set landscape after widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    });
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
      case 'question_asked':
        _handleQuestionAsked(data['result']);
        break;
      case 'answer_given':
        _handleAnswerGiven(data);
        break;
      case 'chat_message':
        _handleChatMessage(data);
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
        _showQuestionInput = true;
      });
    });
  }

  void _handleQuestionAsked(Map<String, dynamic> result) {
    setState(() {
      _currentQuestion = result['question'];
      _answerer = result['answerer'];
      _showQuestionInput = false;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${result['questioner']['name']} asked: ${result['question']}'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  void _handleAnswerGiven(Map<String, dynamic> data) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${data['answerer']['name']} answered!'),
        backgroundColor: Colors.green,
      ),
    );
    
    setState(() {
      _showQuestionInput = false;
      _currentPlayer = null;
      _currentQuestion = null;
      _answerer = null;
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

  Future<void> _askQuestion() async {
    if (_questionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a question')),
      );
      return;
    }

    final authService = Provider.of<AuthService>(context, listen: false);
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/api/games/zone/${widget.zoneId}/ask-question'),
        headers: ApiConstants.getHeaders(token: authService.token),
        body: jsonEncode({
          'question': _questionController.text.trim(),
          'type': 'text',
        }),
      );

      if (response.statusCode == 200) {
        _questionController.clear();
      }
    } catch (e) {
      print('Error asking question: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: OrientationBuilder(
          builder: (context, orientation) {
            return Stack(
              children: [
                // Main game area
                Row(
                  children: [
                    // Left side - Members
                    Container(
                      width: 120,
                      color: Colors.grey[100],
                      child: _buildMembersSection(),
                    ),
                    // Center - Game area
                    Expanded(
                      child: _buildGameArea(),
                    ),
                    // Right side - Voice controls
                    Container(
                      width: 80,
                      color: Colors.grey[50],
                      child: _buildVoiceControls(),
                    ),
                  ],
                ),
                // Collapsible chat
                _buildCollapsibleChat(),
                // Top bar
                _buildTopBar(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildMembersSection() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          child: Text(
            'Players\n${_members.length}/6',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _members.length,
            itemBuilder: (context, index) {
              final member = _members[index];
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 25,
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
                      style: const TextStyle(fontSize: 10),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    // Voice indicator
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(top: 2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _voiceConnected ? Colors.green : Colors.grey,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGameArea() {
    if (!_gameStarted) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sports_esports, size: 100, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _isAdmin ? 'Start the game when ready!' : 'Waiting for admin to start...',
              style: TextStyle(fontSize: 20, color: Colors.grey[600]),
            ),
            if (_isAdmin) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _startGame,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Start Game'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  textStyle: const TextStyle(fontSize: 18),
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
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey[300]!, width: 3),
                  gradient: LinearGradient(
                    colors: [Colors.white, Colors.grey[100]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.local_drink,
                    size: 80,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            );
          },
        ),
        
        const SizedBox(height: 30),
        
        if (_showQuestionInput && _currentPlayer != null) _buildQuestionInput(),
        
        if (!_showQuestionInput && _currentQuestion == null)
          ElevatedButton.icon(
            onPressed: _spinBottle,
            icon: const Icon(Icons.refresh),
            label: const Text('Spin Bottle'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              textStyle: const TextStyle(fontSize: 18),
            ),
          ),
        
        if (_currentQuestion != null) _buildCurrentQuestion(),
      ],
    );
  }

  Widget _buildQuestionInput() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
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
            '${_currentPlayer!['name']}, ask your question:',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          TextField(
            controller: _questionController,
            decoration: InputDecoration(
              hintText: 'Type your question here...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.help_outline),
            ),
            maxLines: 2,
            textCapitalization: TextCapitalization.sentences,
          ),
          
          const SizedBox(height: 16),
          
          ElevatedButton.icon(
            onPressed: _askQuestion,
            icon: const Icon(Icons.send),
            label: const Text('Ask Question'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentQuestion() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF6B6B), Color(0xFFFF8E8E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(Icons.question_mark, color: Colors.white, size: 32),
          const SizedBox(height: 12),
          Text(
            _currentQuestion!,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            '${_answerer!['name']}, it\'s your turn to answer!',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
            textAlign: TextAlign.center,
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
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const GameRulesScreen(),
                ),
              );
            },
            icon: const Icon(Icons.help_outline),
            tooltip: 'Game Rules',
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GameSettingsScreen(zoneId: widget.zoneId),
                ),
              );
            },
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
          ),
        ],
      ),
    );
  }

  // Voice Chat Methods
  Future<void> _initVoiceChat() async {
    try {
      // Check if WebRTC is available
      if (!mounted) return;
      
      _localStream = await navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': false,
      }).catchError((error) {
        print('Microphone permission denied: $error');
        return null;
      });
      
      if (_localStream == null) {
        setState(() => _voiceConnected = false);
        return;
      }
      
      _peerConnection = await createPeerConnection({
        'iceServers': [
          {'urls': 'stun:stun.l.google.com:19302'},
          {'urls': 'stun:stun1.l.google.com:19302'},
        ]
      }).catchError((error) {
        print('WebRTC connection failed: $error');
        return null;
      });
      
      if (_peerConnection != null && _localStream != null) {
        _peerConnection!.addStream(_localStream!);
        if (mounted) {
          setState(() => _voiceConnected = true);
        }
      }
    } catch (e) {
      print('Voice chat init error: $e');
      if (mounted) {
        setState(() => _voiceConnected = false);
      }
    }
  }
  
  void _toggleMute() {
    if (_localStream != null) {
      _localStream!.getAudioTracks().forEach((track) {
        track.enabled = _isMuted;
      });
      setState(() => _isMuted = !_isMuted);
    }
  }
  
  Widget _buildVoiceControls() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Voice status
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _voiceConnected ? Colors.green : Colors.grey,
          ),
          child: Icon(
            _voiceConnected ? Icons.mic : Icons.mic_off,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _voiceConnected ? 'Connected' : 'Connecting...',
          style: const TextStyle(fontSize: 10),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        
        // Mute button
        GestureDetector(
          onTap: _toggleMute,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isMuted ? Colors.red : AppTheme.primaryColor,
            ),
            child: Icon(
              _isMuted ? Icons.mic_off : Icons.mic,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _isMuted ? 'Muted' : 'Live',
          style: const TextStyle(fontSize: 10),
        ),
      ],
    );
  }
  
  Widget _buildTopBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
            ),
            Expanded(
              child: Text(
                _zoneData?['zone_name'] ?? 'Game Zone',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
            IconButton(
              onPressed: () {
                setState(() {
                  _chatExpanded = !_chatExpanded;
                  if (_chatExpanded) {
                    _chatAnimationController.forward();
                  } else {
                    _chatAnimationController.reverse();
                  }
                });
              },
              icon: Icon(_chatExpanded ? Icons.chat : Icons.chat_bubble_outline),
              tooltip: 'Toggle Chat',
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCollapsibleChat() {
    return AnimatedBuilder(
      animation: _chatAnimation,
      builder: (context, child) {
        return Positioned(
          bottom: 0,
          left: 120,
          right: 80,
          height: _chatAnimation.value * 200,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Chat header
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.chat, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Live Chat',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _chatExpanded = false;
                            _chatAnimationController.reverse();
                          });
                        },
                        child: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                // Chat messages
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: _chatMessages.length,
                    itemBuilder: (context, index) {
                      final msg = _chatMessages[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '${msg['sender']['name']}: ${msg['message']}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      );
                    },
                  ),
                ),
                // Chat input
                Container(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _chatTextController,
                          decoration: InputDecoration(
                            hintText: 'Type a message...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            isDense: true,
                          ),
                          style: const TextStyle(fontSize: 12),
                          onSubmitted: (_) => _sendChatMessage(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _sendChatMessage,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.primaryColor,
                          ),
                          child: const Icon(Icons.send, color: Colors.white, size: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleChatMessage(Map<String, dynamic> data) {
    setState(() {
      _chatMessages.add({
        'message': data['message'],
        'sender': data['sender'],
        'timestamp': data['timestamp'],
      });
    });
  }

  void _sendChatMessage() {
    if (_chatTextController.text.trim().isEmpty) return;
    
    final authService = Provider.of<AuthService>(context, listen: false);
    final message = {
      'type': 'chat_message',
      'message': _chatTextController.text.trim(),
      'sender': {'id': authService.currentUser?.id, 'name': authService.currentUser?.name},
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    _channel?.sink.add(json.encode(message));
    _chatTextController.clear();
  }


  @override
  void dispose() {
    // Restore orientation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    
    _bottleController.dispose();
    _chatAnimationController.dispose();
    _questionController.dispose();
    _chatTextController.dispose();
    _channel?.sink.close();
    _localStream?.dispose();
    _peerConnection?.dispose();
    super.dispose();
  }
}