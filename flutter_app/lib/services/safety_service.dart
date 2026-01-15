import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../utils/api_constants.dart';

class SafetyService extends ChangeNotifier {
  List<SafetyTip> _safetyTips = [];
  SafetyResources? _safetyResources;
  bool _isLoading = false;
  String? _error;

  List<SafetyTip> get safetyTips => _safetyTips;
  SafetyResources? get safetyResources => _safetyResources;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchSafetyTips({String category = 'all'}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.safetyTips}?category=$category'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _safetyTips = (data['tips'] as List)
            .map((tip) => SafetyTip.fromJson(tip))
            .toList();
      } else {
        _error = 'Failed to fetch safety tips';
      }
    } catch (e) {
      _error = 'Network error: ${e.toString()}';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchSafetyResources() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.safetyResources}'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _safetyResources = SafetyResources.fromJson(data);
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to fetch safety resources: ${e.toString()}';
      notifyListeners();
    }
  }

  List<SafetyTip> getTipsByCategory(String category) {
    return _safetyTips.where((tip) => tip.category == category).toList();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

class SafetyTip {
  final int id;
  final String title;
  final String content;
  final String category;
  final bool isActive;
  final DateTime createdAt;

  SafetyTip({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    required this.isActive,
    required this.createdAt,
  });

  factory SafetyTip.fromJson(Map<String, dynamic> json) {
    return SafetyTip(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      category: json['category'],
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class SafetyResources {
  final Map<String, String> emergencyContacts;
  final List<SafetyApp> safetyApps;
  final List<String> datingSafetyChecklist;

  SafetyResources({
    required this.emergencyContacts,
    required this.safetyApps,
    required this.datingSafetyChecklist,
  });

  factory SafetyResources.fromJson(Map<String, dynamic> json) {
    return SafetyResources(
      emergencyContacts: Map<String, String>.from(json['emergency_contacts']),
      safetyApps: (json['safety_apps'] as List)
          .map((app) => SafetyApp.fromJson(app))
          .toList(),
      datingSafetyChecklist: List<String>.from(json['dating_safety_checklist']),
    );
  }
}

class SafetyApp {
  final String name;
  final String description;

  SafetyApp({
    required this.name,
    required this.description,
  });

  factory SafetyApp.fromJson(Map<String, dynamic> json) {
    return SafetyApp(
      name: json['name'],
      description: json['description'],
    );
  }
}