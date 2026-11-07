import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:feedback_os_flutter/feedback_os_flutter.dart';

void main() {
  group('FeedbackOSOptions', () {
    test('defaults to production base URL and sensible timeouts', () {
      final options = FeedbackOSOptions();

      expect(options.baseUrl.toString(), equals('https://api.feedbackos.dev'));
      expect(options.connectTimeout, equals(const Duration(seconds: 15)));
      expect(options.receiveTimeout, equals(const Duration(seconds: 15)));
      expect(options.debugLogging, isFalse);
      expect(options.maxOfflineQueueSize, equals(500));
      expect(options.queueItemTtl, equals(const Duration(days: 7)));
      expect(options.theme, equals(const FeedbackOSTheme()));
    });

    test('staging factory points to verified staging Worker URL', () {
      final options = FeedbackOSOptions.staging();

      expect(
        options.baseUrl.toString(),
        equals('https://api-staging.feedbackos.dev'),
      );
      expect(options.theme, equals(const FeedbackOSTheme()));
    });

    test('local factory points to localhost:8787 and enables debug logging',
        () {
      final options = FeedbackOSOptions.local();

      expect(options.baseUrl.toString(), equals('http://localhost:8787'));
      expect(options.debugLogging, isTrue);
      expect(options.theme, equals(const FeedbackOSTheme()));
    });

    test('allows fully custom configuration including user-defined theme', () {
      final customUrl = Uri.parse('https://custom.feedbackos.example.com');
      const customTheme = FeedbackOSTheme(
        primaryColor: Colors.deepPurple,
        backgroundColor: Colors.black,
      );
      final options = FeedbackOSOptions(
        baseUrl: customUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 45),
        debugLogging: true,
        maxOfflineQueueSize: 200,
        queueItemTtl: const Duration(days: 3),
        theme: customTheme,
      );

      expect(options.baseUrl, equals(customUrl));
      expect(options.connectTimeout, equals(const Duration(seconds: 30)));
      expect(options.receiveTimeout, equals(const Duration(seconds: 45)));
      expect(options.debugLogging, isTrue);
      expect(options.maxOfflineQueueSize, equals(200));
      expect(options.queueItemTtl, equals(const Duration(days: 3)));
      expect(options.theme.primaryColor, equals(Colors.deepPurple));
      expect(options.theme.backgroundColor, equals(Colors.black));
    });

    test('equality checks work as expected via Equatable', () {
      final opt1 = FeedbackOSOptions();
      final opt2 = FeedbackOSOptions();
      expect(opt1, equals(opt2));

      final opt3 = FeedbackOSOptions(
        theme: const FeedbackOSTheme(primaryColor: Colors.teal),
      );
      expect(opt1 == opt3, isFalse);
    });
  });
}
