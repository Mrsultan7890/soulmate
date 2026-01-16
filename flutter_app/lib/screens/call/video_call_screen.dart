import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:provider/provider.dart';
import '../../services/webrtc_service.dart';
import '../../services/auth_service.dart';
import '../../utils/theme.dart';

class VideoCallScreen extends StatefulWidget {
  final int otherUserId;
  final String otherUserName;
  final String? callId;
  final bool isIncoming;
  final bool isVideoCall;

  const VideoCallScreen({
    super.key,
    required this.otherUserId,
    required this.otherUserName,
    this.callId,
    this.isIncoming = false,
    this.isVideoCall = true,
  });

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  final WebRTCService _webrtcService = WebRTCService();
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();

  bool _isMuted = false;
  bool _isVideoEnabled = true;
  bool _isSpeakerOn = true;
  bool _isConnected = false;
  bool _isConnecting = true;

  @override
  void initState() {
    super.initState();
    _initializeCall();
  }

  Future<void> _initializeCall() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();

    final authService = Provider.of<AuthService>(context, listen: false);
    final token = authService.token;

    if (token == null) {
      _showError('Not authenticated');
      return;
    }

    _webrtcService.onLocalStream = (stream) {
      setState(() {
        _localRenderer.srcObject = stream;
      });
    };

    _webrtcService.onRemoteStream = (stream) {
      setState(() {
        _remoteRenderer.srcObject = stream;
        _isConnected = true;
        _isConnecting = false;
      });
    };

    _webrtcService.onCallEnded = () {
      Navigator.pop(context);
    };

    _webrtcService.onError = (error) {
      _showError(error);
    };

    await _webrtcService.initialize(authService.currentUser!.id);

    if (widget.isIncoming && widget.callId != null) {
      await _webrtcService.acceptCall(
        callId: widget.callId!,
        callerId: widget.otherUserId,
        token: token,
        isVideo: widget.isVideoCall,
      );
    } else {
      final callId = await _webrtcService.startCall(
        receiverId: widget.otherUserId,
        callType: widget.isVideoCall ? 'video' : 'audio',
        token: token,
        isVideo: widget.isVideoCall,
      );

      if (callId == null) {
        Navigator.pop(context);
      }
    }

    setState(() => _isConnecting = false);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _endCall() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    await _webrtcService.endCall(token: authService.token);
    Navigator.pop(context);
  }

  void _toggleMute() {
    setState(() => _isMuted = !_isMuted);
    _webrtcService.toggleMicrophone();
  }

  void _toggleVideo() {
    setState(() => _isVideoEnabled = !_isVideoEnabled);
    _webrtcService.toggleVideo();
  }

  void _switchCamera() {
    _webrtcService.switchCamera();
  }

  @override
  void dispose() {
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    _webrtcService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (_isConnected && widget.isVideoCall)
            Positioned.fill(
              child: RTCVideoView(_remoteRenderer, mirror: false),
            )
          else
            _buildWaitingView(),

          if (widget.isVideoCall && _isVideoEnabled)
            Positioned(
              top: 50,
              right: 20,
              child: Container(
                width: 120,
                height: 160,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: RTCVideoView(_localRenderer, mirror: true),
                ),
              ),
            ),

          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black54, Colors.transparent],
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      widget.otherUserName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isConnecting
                          ? 'Connecting...'
                          : _isConnected
                              ? 'Connected'
                              : 'Ringing...',
                      style: const TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black54, Colors.transparent],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildControlButton(
                      icon: _isMuted ? Icons.mic_off : Icons.mic,
                      onPressed: _toggleMute,
                      color: _isMuted ? Colors.red : Colors.white,
                    ),
                    if (widget.isVideoCall)
                      _buildControlButton(
                        icon: _isVideoEnabled ? Icons.videocam : Icons.videocam_off,
                        onPressed: _toggleVideo,
                        color: _isVideoEnabled ? Colors.white : Colors.red,
                      ),
                    _buildControlButton(
                      icon: Icons.call_end,
                      onPressed: _endCall,
                      color: Colors.red,
                      size: 70,
                    ),
                    if (widget.isVideoCall)
                      _buildControlButton(
                        icon: Icons.flip_camera_ios,
                        onPressed: _switchCamera,
                        color: Colors.white,
                      ),
                    _buildControlButton(
                      icon: _isSpeakerOn ? Icons.volume_up : Icons.volume_off,
                      onPressed: () => setState(() => _isSpeakerOn = !_isSpeakerOn),
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaitingView() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppTheme.primaryGradient,
              ),
              child: const Icon(Icons.person, size: 60, color: Colors.white),
            ),
            const SizedBox(height: 24),
            Text(
              widget.otherUserName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (_isConnecting)
              const CircularProgressIndicator(color: Colors.white)
            else
              const Text(
                'Ringing...',
                style: TextStyle(color: Colors.white70, fontSize: 18),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required Color color,
    double size = 60,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withOpacity(0.3),
          border: Border.all(color: color, width: 2),
        ),
        child: Icon(icon, color: color, size: size * 0.5),
      ),
    );
  }
}
