import 'dart:convert';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import '../utils/api_constants.dart';

class WebRTCService {
  // WebRTC Configuration with Google STUN (FREE)
  static final Map<String, dynamic> configuration = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
      {'urls': 'stun:stun2.l.google.com:19302'},
      {'urls': 'stun:stun3.l.google.com:19302'},
      {'urls': 'stun:stun4.l.google.com:19302'},
    ]
  };

  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;
  WebSocketChannel? _signalingChannel;
  
  int? _currentUserId;
  int? _otherUserId;
  String? _currentCallId;
  
  // Callbacks
  Function(MediaStream)? onLocalStream;
  Function(MediaStream)? onRemoteStream;
  Function()? onCallEnded;
  Function(String)? onError;

  // Initialize WebRTC
  Future<void> initialize(int userId) async {
    _currentUserId = userId;
    await _connectSignaling(userId);
  }

  // Connect to signaling server
  Future<void> _connectSignaling(int userId) async {
    try {
      final wsUrl = ApiConstants.baseUrl.replaceFirst('http', 'ws');
      _signalingChannel = WebSocketChannel.connect(
        Uri.parse('$wsUrl/api/calls/signal/$userId'),
      );

      _signalingChannel!.stream.listen((message) {
        _handleSignalingMessage(jsonDecode(message));
      });

      print('✅ Connected to signaling server');
    } catch (e) {
      print('❌ Signaling connection error: $e');
      onError?.call('Failed to connect to call server');
    }
  }

  // Handle signaling messages
  void _handleSignalingMessage(Map<String, dynamic> message) async {
    final type = message['type'];

    switch (type) {
      case 'incoming_call':
        // Handle incoming call (will be handled by UI)
        break;

      case 'call_accepted':
        // Other user accepted, start WebRTC connection
        await _createOffer();
        break;

      case 'call_rejected':
        onError?.call('Call was rejected');
        await endCall();
        break;

      case 'call_ended':
        onCallEnded?.call();
        await _cleanup();
        break;

      case 'webrtc_signal':
        await _handleWebRTCSignal(message['signal']);
        break;
    }
  }

  // Start a call (video or audio)
  Future<String?> startCall({
    required int receiverId,
    required String callType,
    required String token,
    required bool isVideo,
  }) async {
    try {
      _otherUserId = receiverId;

      // Get local media stream
      _localStream = await navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': isVideo
            ? {'facingMode': 'user', 'width': 640, 'height': 480}
            : false,
      });

      onLocalStream?.call(_localStream!);

      // Initiate call via API
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/api/calls/initiate'),
        headers: ApiConstants.getHeaders(token: token),
        body: jsonEncode({
          'receiver_id': receiverId,
          'call_type': callType,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _currentCallId = data['call_id'];
        return _currentCallId;
      } else {
        throw Exception('Failed to initiate call');
      }
    } catch (e) {
      print('Error starting call: $e');
      onError?.call('Failed to start call: $e');
      return null;
    }
  }

  // Accept incoming call
  Future<void> acceptCall({
    required String callId,
    required int callerId,
    required String token,
    required bool isVideo,
  }) async {
    try {
      _currentCallId = callId;
      _otherUserId = callerId;

      // Get local media stream
      _localStream = await navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': isVideo
            ? {'facingMode': 'user', 'width': 640, 'height': 480}
            : false,
      });

      onLocalStream?.call(_localStream!);

      // Accept call via API
      await http.post(
        Uri.parse('${ApiConstants.baseUrl}/api/calls/accept'),
        headers: ApiConstants.getHeaders(token: token),
        body: jsonEncode({'call_id': callId}),
      );

      // Create peer connection and wait for offer
      await _createPeerConnection();
    } catch (e) {
      print('Error accepting call: $e');
      onError?.call('Failed to accept call');
    }
  }

  // Reject incoming call
  Future<void> rejectCall(String callId, String token) async {
    try {
      await http.post(
        Uri.parse('${ApiConstants.baseUrl}/api/calls/reject'),
        headers: ApiConstants.getHeaders(token: token),
        body: jsonEncode({'call_id': callId}),
      );
    } catch (e) {
      print('Error rejecting call: $e');
    }
  }

  // Create peer connection
  Future<void> _createPeerConnection() async {
    _peerConnection = await createPeerConnection(configuration);

    // Add local stream to peer connection
    _localStream?.getTracks().forEach((track) {
      _peerConnection?.addTrack(track, _localStream!);
    });

    // Handle remote stream
    _peerConnection?.onTrack = (RTCTrackEvent event) {
      if (event.streams.isNotEmpty) {
        _remoteStream = event.streams[0];
        onRemoteStream?.call(_remoteStream!);
      }
    };

    // Handle ICE candidates
    _peerConnection?.onIceCandidate = (RTCIceCandidate candidate) {
      _sendSignal({
        'type': 'ice_candidate',
        'candidate': candidate.toMap(),
      });
    };

    // Handle connection state
    _peerConnection?.onConnectionState = (RTCPeerConnectionState state) {
      print('Connection state: $state');
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected) {
        onError?.call('Connection lost');
      }
    };
  }

  // Create offer (caller)
  Future<void> _createOffer() async {
    await _createPeerConnection();

    RTCSessionDescription offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);

    _sendSignal({
      'type': 'offer',
      'sdp': offer.sdp,
    });
  }

  // Handle WebRTC signals (SDP/ICE)
  Future<void> _handleWebRTCSignal(Map<String, dynamic> signal) async {
    final type = signal['type'];

    if (type == 'offer') {
      // Receiver gets offer
      await _createPeerConnection();
      await _peerConnection!.setRemoteDescription(
        RTCSessionDescription(signal['sdp'], 'offer'),
      );

      // Create answer
      RTCSessionDescription answer = await _peerConnection!.createAnswer();
      await _peerConnection!.setLocalDescription(answer);

      _sendSignal({
        'type': 'answer',
        'sdp': answer.sdp,
      });
    } else if (type == 'answer') {
      // Caller gets answer
      await _peerConnection!.setRemoteDescription(
        RTCSessionDescription(signal['sdp'], 'answer'),
      );
    } else if (type == 'ice_candidate') {
      // Add ICE candidate
      await _peerConnection!.addCandidate(
        RTCIceCandidate(
          signal['candidate']['candidate'],
          signal['candidate']['sdpMid'],
          signal['candidate']['sdpMLineIndex'],
        ),
      );
    }
  }

  // Send signaling message
  void _sendSignal(Map<String, dynamic> signal) {
    if (_signalingChannel != null && _otherUserId != null) {
      _signalingChannel!.sink.add(jsonEncode({
        'type': 'webrtc_signal',
        'to_user_id': _otherUserId,
        'signal': signal,
      }));
    }
  }

  // End call
  Future<void> endCall({String? token}) async {
    if (_currentCallId != null && token != null) {
      try {
        await http.post(
          Uri.parse('${ApiConstants.baseUrl}/api/calls/end'),
          headers: ApiConstants.getHeaders(token: token),
          body: jsonEncode({'call_id': _currentCallId}),
        );
      } catch (e) {
        print('Error ending call: $e');
      }
    }
    await _cleanup();
  }

  // Cleanup resources
  Future<void> _cleanup() async {
    _localStream?.getTracks().forEach((track) => track.stop());
    _localStream?.dispose();
    _localStream = null;

    _remoteStream?.dispose();
    _remoteStream = null;

    await _peerConnection?.close();
    _peerConnection = null;

    _currentCallId = null;
    _otherUserId = null;
  }

  // Toggle camera
  Future<void> switchCamera() async {
    if (_localStream != null) {
      final videoTrack = _localStream!.getVideoTracks().first;
      await Helper.switchCamera(videoTrack);
    }
  }

  // Toggle microphone
  void toggleMicrophone() {
    if (_localStream != null) {
      final audioTrack = _localStream!.getAudioTracks().first;
      audioTrack.enabled = !audioTrack.enabled;
    }
  }

  // Toggle video
  void toggleVideo() {
    if (_localStream != null) {
      final videoTrack = _localStream!.getVideoTracks().first;
      videoTrack.enabled = !videoTrack.enabled;
    }
  }

  // Dispose
  void dispose() {
    _cleanup();
    _signalingChannel?.sink.close();
  }
}
