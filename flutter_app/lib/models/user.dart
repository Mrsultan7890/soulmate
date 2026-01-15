class User {
  final int id;
  final String email;
  final String name;
  final int? age;
  final String? bio;
  final String? location;
  final double? latitude;
  final double? longitude;
  
  // Rich Profile Data
  final String? jobTitle;
  final String? company;
  final String? educationLevel;
  final String? educationDetails;
  final int? height;
  final String? bodyType;
  final String? smoking;
  final String? drinking;
  final String? dietPreference;
  final String? religion;
  final String? caste;
  final String? motherTongue;
  final String? gymFrequency;
  final String? travelFrequency;
  final Map<String, String>? profilePrompts;
  
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
    this.jobTitle,
    this.company,
    this.educationLevel,
    this.educationDetails,
    this.height,
    this.bodyType,
    this.smoking,
    this.drinking,
    this.dietPreference,
    this.religion,
    this.caste,
    this.motherTongue,
    this.gymFrequency,
    this.travelFrequency,
    this.profilePrompts,
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
      jobTitle: json['job_title'],
      company: json['company'],
      educationLevel: json['education_level'],
      educationDetails: json['education_details'],
      height: json['height'],
      bodyType: json['body_type'],
      smoking: json['smoking'],
      drinking: json['drinking'],
      dietPreference: json['diet_preference'],
      religion: json['religion'],
      caste: json['caste'],
      motherTongue: json['mother_tongue'],
      gymFrequency: json['gym_frequency'],
      travelFrequency: json['travel_frequency'],
      profilePrompts: json['profile_prompts'] != null 
          ? Map<String, String>.from(json['profile_prompts'])
          : null,
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
      'job_title': jobTitle,
      'company': company,
      'education_level': educationLevel,
      'education_details': educationDetails,
      'height': height,
      'body_type': bodyType,
      'smoking': smoking,
      'drinking': drinking,
      'diet_preference': dietPreference,
      'religion': religion,
      'caste': caste,
      'mother_tongue': motherTongue,
      'gym_frequency': gymFrequency,
      'travel_frequency': travelFrequency,
      'profile_prompts': profilePrompts,
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
