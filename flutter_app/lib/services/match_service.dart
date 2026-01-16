import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/match.dart';
import '../utils/api_constants.dart';
import 'notification_service.dart';

class MatchService extends ChangeNotifier {
  List<Match> _matches = [];
  bool _isLoading = false;
  String? _error;
  Match? _newMatch;

  List<Match> get matches => _matches;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Match? get newMatch => _newMatch;

  Future<Map<String, dynamic>?> swipe({
    required String token,
    required int swipedUserId,
    required bool isLike,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.swipe}'),
        headers: ApiConstants.getHeaders(token: token),
        body: jsonEncode({
          'swiped_user_id': swipedUserId,
          'is_like': isLike,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['is_match'] == true) {
          // Fetch the new match details
          await fetchMatches(token);
          
          // Show notification
          if (_matches.isNotEmpty) {
            final match = _matches.first;
            await NotificationService.showMatchNotification(match.otherUser.name);
          }
          
          return data;
        }
        return data;
      }
      return null;
    } catch (e) {
      _error = 'Failed to swipe: ${e.toString()}';
      notifyListeners();
      return null;
    }
  }

  Future<void> fetchMatches(String token) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.matches}'),
        headers: ApiConstants.getHeaders(token: token),
      );

      print('Matches API response: ${response.statusCode}');
      print('Matches API body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print('Total matches received: ${data.length}');
        _matches = data.map((match) => Match.fromJson(match)).toList();
        print('Matches parsed: ${_matches.length}');
      } else {
        _error = 'Failed to fetch matches';
        print('Error: $_error');
      }
    } catch (e) {
      _error = 'Network error: ${e.toString()}';
      print('Exception in fetchMatches: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> unmatch(String token, int matchId) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.unmatch}/$matchId'),
        headers: ApiConstants.getHeaders(token: token),
      );

      if (response.statusCode == 200) {
        _matches.removeWhere((match) => match.id == matchId);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = 'Failed to unmatch';
      notifyListeners();
      return false;
    }
  }

  void setNewMatch(Match match) {
    _newMatch = match;
    notifyListeners();
  }

  void clearNewMatch() {
    _newMatch = null;
    notifyListeners();
  }
}
