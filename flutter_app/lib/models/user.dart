class User {
  final int id;
  final String email;
  final String name;
  final int? age;
  final String? bio;
  final String? location;
  final double? latitude;
  final double? longitude;
  final List<String> interests;
  final String? relationshipIntent;
  final List<String> profileImages;
  final Map<String, dynamic> preferences;
  final bool isVerified;
  final bool isPremium;
  final DateTime createdAt;

  User({
    required this.id,
    required this.email,
    required this.name,
    this.age,
    this.bio,
    this.location,
    this.latitude,
    this.longitude,
    this.interests = const [],
    this.relationshipIntent,
    this.profileImages = const [],
    this.preferences = const {},
    this.isVerified = false,
    this.isPremium = false,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'] ?? '',
      name: json['name'],
      age: json['age'],
      bio: json['bio'],
      location: json['location'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      interests: json['interests'] != null 
          ? List<String>.from(json['interests']) 
          : [],
      relationshipIntent: json['relationship_intent'],
      profileImages: json['profile_images'] != null
          ? List<String>.from(json['profile_images'])
          : [],
      preferences: json['preferences'] ?? {},
      isVerified: json['is_verified'] ?? false,
      isPremium: json['is_premium'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'age': age,
      'bio': bio,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'interests': interests,
      'relationship_intent': relationshipIntent,
      'profile_images': profileImages,
      'preferences': preferences,
      'is_verified': isVerified,
      'is_premium': isPremium,
      'created_at': createdAt.toIso8601String(),
    };
  }

  String get firstImage => profileImages.isNotEmpty ? profileImages[0] : '';
  
  String get displayAge => age != null ? '$age' : '';
  
  String get displayLocation => location ?? 'Unknown';
}
