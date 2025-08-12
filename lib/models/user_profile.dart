class UserProfile {
  final String id;
  final String email;
  final String? fullName;
  final String? phoneNumber;
  final String? bio;
  final String? avatarUrl;
  final String subscriptionPlan;
  final DateTime? subscriptionExpiresAt;
  final int totalTranslations;
  final int dailyTranslations;
  final DateTime lastDailyReset;
  final String preferredLanguage;
  final List<String> learningLanguages;
  final int streakDays;
  final DateTime lastActivityAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime lastLoginAt;
  final bool isActive;
  final Map<String, dynamic> settings;

  UserProfile({
    required this.id,
    required this.email,
    this.fullName,
    this.phoneNumber,
    this.bio,
    this.avatarUrl,
    this.subscriptionPlan = 'free',
    this.subscriptionExpiresAt,
    this.totalTranslations = 0,
    this.dailyTranslations = 0,
    required this.lastDailyReset,
    this.preferredLanguage = 'en',
    this.learningLanguages = const [],
    this.streakDays = 0,
    required this.lastActivityAt,
    required this.createdAt,
    required this.updatedAt,
    required this.lastLoginAt,
    this.isActive = true,
    this.settings = const {},
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String?,
      phoneNumber: json['phone_number'] as String?,
      bio: json['bio'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      subscriptionPlan: json['subscription_plan'] as String? ?? 'free',
      subscriptionExpiresAt: json['subscription_expires_at'] != null
          ? DateTime.parse(json['subscription_expires_at'])
          : null,
      totalTranslations: json['total_translations'] as int? ?? 0,
      dailyTranslations: json['daily_translations'] as int? ?? 0,
      lastDailyReset: DateTime.parse(json['last_daily_reset'] ?? DateTime.now().toIso8601String()),
      preferredLanguage: json['preferred_language'] as String? ?? 'en',
      learningLanguages: List<String>.from(json['learning_languages'] ?? []),
      streakDays: json['streak_days'] as int? ?? 0,
      lastActivityAt: DateTime.parse(json['last_activity_at'] ?? DateTime.now().toIso8601String()),
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
      lastLoginAt: DateTime.parse(json['last_login_at'] ?? DateTime.now().toIso8601String()),
      isActive: json['is_active'] as bool? ?? true,
      settings: Map<String, dynamic>.from(json['settings'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'phone_number': phoneNumber,
      'bio': bio,
      'avatar_url': avatarUrl,
      'subscription_plan': subscriptionPlan,
      'subscription_expires_at': subscriptionExpiresAt?.toIso8601String(),
      'total_translations': totalTranslations,
      'daily_translations': dailyTranslations,
      'last_daily_reset': lastDailyReset.toIso8601String(),
      'preferred_language': preferredLanguage,
      'learning_languages': learningLanguages,
      'streak_days': streakDays,
      'last_activity_at': lastActivityAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'last_login_at': lastLoginAt.toIso8601String(),
      'is_active': isActive,
      'settings': settings,
    };
  }

  UserProfile copyWith({
    String? id,
    String? email,
    String? fullName,
    String? phoneNumber,
    String? bio,
    String? avatarUrl,
    String? subscriptionPlan,
    DateTime? subscriptionExpiresAt,
    int? totalTranslations,
    int? dailyTranslations,
    DateTime? lastDailyReset,
    String? preferredLanguage,
    List<String>? learningLanguages,
    int? streakDays,
    DateTime? lastActivityAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastLoginAt,
    bool? isActive,
    Map<String, dynamic>? settings,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      subscriptionPlan: subscriptionPlan ?? this.subscriptionPlan,
      subscriptionExpiresAt: subscriptionExpiresAt ?? this.subscriptionExpiresAt,
      totalTranslations: totalTranslations ?? this.totalTranslations,
      dailyTranslations: dailyTranslations ?? this.dailyTranslations,
      lastDailyReset: lastDailyReset ?? this.lastDailyReset,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      learningLanguages: learningLanguages ?? this.learningLanguages,
      streakDays: streakDays ?? this.streakDays,
      lastActivityAt: lastActivityAt ?? this.lastActivityAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      isActive: isActive ?? this.isActive,
      settings: settings ?? this.settings,
    );
  }

  @override
  String toString() {
    return 'UserProfile(id: $id, email: $email, fullName: $fullName, subscriptionPlan: $subscriptionPlan)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is UserProfile &&
        other.id == id &&
        other.email == email &&
        other.fullName == fullName &&
        other.subscriptionPlan == subscriptionPlan;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        email.hashCode ^
        fullName.hashCode ^
        subscriptionPlan.hashCode;
  }

  // Convenience getters
  String get displayName => fullName ?? email.split('@').first;
  
  bool get isPro => subscriptionPlan == 'pro' || subscriptionPlan == 'premium';
  
  bool get hasActiveSubscription => 
      isPro && (subscriptionExpiresAt?.isAfter(DateTime.now()) ?? false);
  
  int get translationsRemaining {
    if (isPro) return -1; // Unlimited for pro users
    const dailyLimit = 50; // Free users get 50 translations per day
    return (dailyLimit - dailyTranslations).clamp(0, dailyLimit);
  }
  
  bool get canTranslate => isPro || translationsRemaining > 0;
}