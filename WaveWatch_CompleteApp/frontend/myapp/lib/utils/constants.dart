class AppConstants {
  // Shared Preferences Keys
  static const String storedMetricsKey = 'stored_metrics';
  static const String lastFeedbackPromptKey = 'last_feedback_prompt';
  static const String lastNetworkTypeKey = 'last_network_type';
  static const String lastSignalStrengthKey = 'last_signal_strength';
  static const String lastLatencyKey = 'last_latency';
  static const String deviceIdKey = 'device_id';
  static const String userPointsKey = 'user_points';
  static const String userLevelKey = 'user_level';
  static const String isDarkModeKey = 'is_dark_mode';
  static const String isBackgroundServiceEnabledKey = 'is_background_service_enabled';
  
  // Network Metrics Thresholds
  static const double goodLatencyThreshold = 50.0; // ms
  static const double poorLatencyThreshold = 200.0; // ms
  static const double goodJitterThreshold = 10.0; // ms
  static const double poorJitterThreshold = 50.0; // ms
  static const double goodBandwidthThreshold = 10.0; // Mbps
  static const double poorBandwidthThreshold = 1.0; // Mbps
  static const double acceptablePacketLossThreshold = 1.0; // %
  static const double poorPacketLossThreshold = 5.0; // %
  
  // Reward System
  static const int pointsPerFeedback = 10;
  static const int pointsPerSpeedTest = 5;
  static const int pointsPerDayActive = 2;
  static const Map<int, String> levelTitles = {
    0: 'Novice',
    100: 'Explorer',
    250: 'Contributor',
    500: 'Expert',
    1000: 'Master',
  };
  
  // API Endpoints
  static const String baseApiUrl = 'https://api.example.com';
  static const String metricsEndpoint = '/metrics';
  static const String feedbackEndpoint = '/feedback';
  static const String userEndpoint = '/users';
  
  // App Info
  static const String appName = 'Network QoE';
  static const String appVersion = '1.0.0';
  static const String appPrivacyPolicy = 'https://example.com/privacy';
  static const String appTermsOfService = 'https://example.com/terms';
}
