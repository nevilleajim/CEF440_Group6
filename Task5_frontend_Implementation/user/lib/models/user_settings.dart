// models/user_settings.dart
class UserSettings {
  final int notificationFrequency; // in minutes
  final bool backgroundCollection;
  final int rewardPoints;

  UserSettings({
    this.notificationFrequency = 60,
    this.backgroundCollection = true,
    this.rewardPoints = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'notificationFrequency': notificationFrequency,
      'backgroundCollection': backgroundCollection,
      'rewardPoints': rewardPoints,
    };
  }

  factory UserSettings.fromMap(Map<String, dynamic> map) {
    return UserSettings(
      notificationFrequency: map['notificationFrequency'] ?? 60,
      backgroundCollection: map['backgroundCollection'] ?? true,
      rewardPoints: map['rewardPoints'] ?? 0,
    );
  }
}