abstract final class ApiEndpoints {
  static const String sdkBase = '/v1/sdk';

  static String config(String key) => '$sdkBase/config/$key';
  static const String ping = '$sdkBase/ping';
  static const String identify = '$sdkBase/identify';
  static const String feedback = '$sdkBase/feedback';
  static const String uploads = '$sdkBase/uploads';

  // Header names
  static const String headerApiKey = 'X-FeedbackOS-Key';
  static const String headerDevice = 'X-FeedbackOS-Device';
}
