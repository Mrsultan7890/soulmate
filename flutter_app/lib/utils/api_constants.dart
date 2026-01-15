class ApiConstants {
  // Base URL - Change this to your backend URL
  static const String baseUrl = 'http://localhost:8000';
  
  // Auth Endpoints
  static const String register = '/api/auth/register';
  static const String login = '/api/auth/login';
  static const String me = '/api/auth/me';
  
  // User Endpoints
  static const String profile = '/api/users/profile';
  static const String updateProfile = '/api/users/profile';
  static const String uploadImage = '/api/users/upload-image';
  static const String deleteImage = '/api/users/image';
  static const String discover = '/api/users/discover';
  static const String discoverAdvanced = '/api/users/discover-advanced';
  static const String filterOptions = '/api/users/filter-options';
  static const String richProfile = '/api/users/rich-profile';
  static const String nearby = '/api/users/nearby';
  static const String updateLocation = '/api/users/location';
  static const String updateInterests = '/api/users/interests';
  static const String getInterests = '/api/users/interests';
  static const String updateRelationshipIntent = '/api/users/relationship-intent';
  
  // Match Endpoints
  static const String swipe = '/api/matches/swipe';
  static const String matches = '/api/matches/';
  static const String unmatch = '/api/matches';
  
  // Chat Endpoints
  static const String messages = '/api/chat';
  static const String sendMessage = '/api/chat';
  static const String unreadCount = '/api/chat';
  static const String websocket = 'ws://localhost:8000/api/chat/ws';
  
  // Enhanced Chat Endpoints
  static const String enhancedSendMessage = '/api/enhanced-chat/send-message';
  static const String markMessageRead = '/api/enhanced-chat/message';
  static const String addReaction = '/api/enhanced-chat/message';
  static const String getMessages = '/api/enhanced-chat/match';
  
  // Safety Endpoints
  static const String safetyTips = '/api/safety-tips/safety-tips';
  static const String safetyResources = '/api/safety-tips/safety-resources';
  
  // Headers
  static Map<String, String> getHeaders({String? token}) {
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }
}
