import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:feedback_os_flutter/feedback_os_flutter.dart';

void main() {
  group('FeedbackOSOptions', () {
    test('defaults to sensible timeouts and default properties', () {
      const options = FeedbackOSOptions();

      expect(options.connectTimeout, equals(const Duration(seconds: 15)));
      expect(options.receiveTimeout, equals(const Duration(seconds: 15)));
      expect(options.debugLogging, isFalse);
      expect(options.maxOfflineQueueSize, equals(500));
      expect(options.queueItemTtl, equals(const Duration(days: 7)));
      expect(options.theme, equals(const FeedbackOSTheme()));
      expect(
        options.threadPollingInterval,
        equals(const Duration(seconds: 4)),
      );
    });

    test('allows fully custom configuration including user-defined theme', () {
      const customTheme = FeedbackOSTheme(
        primaryColor: Colors.deepPurple,
        backgroundColor: Colors.black,
      );
      const options = FeedbackOSOptions(
        connectTimeout: Duration(seconds: 30),
        receiveTimeout: Duration(seconds: 45),
        debugLogging: true,
        maxOfflineQueueSize: 200,
        queueItemTtl: Duration(days: 3),
        theme: customTheme,
        threadPollingInterval: Duration(seconds: 5),
      );

      expect(options.connectTimeout, equals(const Duration(seconds: 30)));
      expect(options.receiveTimeout, equals(const Duration(seconds: 45)));
      expect(options.debugLogging, isTrue);
      expect(options.maxOfflineQueueSize, equals(200));
      expect(options.queueItemTtl, equals(const Duration(days: 3)));
      expect(options.theme.primaryColor, equals(Colors.deepPurple));
      expect(options.theme.backgroundColor, equals(Colors.black));
      expect(
        options.threadPollingInterval,
        equals(const Duration(seconds: 5)),
      );
    });

    test('copyWith creates modified copy', () {
      const options = FeedbackOSOptions();
      final updated = options.copyWith(
        debugLogging: true,
        maxOfflineQueueSize: 100,
      );

      expect(updated.debugLogging, isTrue);
      expect(updated.maxOfflineQueueSize, equals(100));
      expect(updated.connectTimeout, equals(options.connectTimeout));
    });

    test('equality checks work as expected via Equatable', () {
      const opt1 = FeedbackOSOptions();
      const opt2 = FeedbackOSOptions();
      expect(opt1, equals(opt2));

      const opt3 = FeedbackOSOptions(
        theme: FeedbackOSTheme(primaryColor: Colors.teal),
      );
      expect(opt1 == opt3, isFalse);
    });
  });
}
