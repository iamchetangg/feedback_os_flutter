abstract final class ApiEndpoints {
  // Base URLs
  static final Uri productionBaseUrl = Uri.parse('https://api.feedbackos.dev');

  static const String sdkBase = '/v1/sdk';

  static String config(String key) => '$sdkBase/config/$key';
  static const String ping = '$sdkBase/ping';
  static const String identify = '$sdkBase/identify';
  static const String feedback = '$sdkBase/feedback';
  static const String uploads = '$sdkBase/uploads';

  // Board & Roadmap endpoints
  static const String board = '$sdkBase/board';
  static const String roadmap = '$sdkBase/roadmap';
  static String itemVote(String itemId) => '$sdkBase/items/$itemId/vote';

  // Threads & My Items endpoints
  static const String meItems = '$sdkBase/me/items';
  static const String meUnread = '$sdkBase/me/unread';
  static String meItemDetail(String itemId) => '$sdkBase/me/items/$itemId';
  static String meItemRead(String itemId) => '$sdkBase/me/items/$itemId/read';
  static String meItemReplies(String itemId) =>
      '$sdkBase/me/items/$itemId/replies';

  // Header names
  static const String headerApiKey = 'X-FeedbackOS-Key';
  static const String headerDevice = 'X-FeedbackOS-Device';
}
