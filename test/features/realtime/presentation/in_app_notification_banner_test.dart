import 'package:feedback_os_flutter/feedback_os_flutter.dart';
import 'package:feedback_os_flutter/src/features/realtime/presentation/in_app_notification_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('bannerContentFor', () {
    test('reply with and without author', () {
      final withAuthor = bannerContentFor(ReplyReceived(
        itemId: 'i',
        replyId: 'r',
        authorName: 'Jane',
        preview: 'Fixed!',
        createdAt: DateTime.utc(2026),
      ));
      expect(withAuthor.title, 'New reply from Jane');
      expect(withAuthor.message, 'Fixed!');

      final anonymous = bannerContentFor(ReplyReceived(
        itemId: 'i',
        replyId: 'r',
        authorName: null,
        preview: 'Fixed!',
        createdAt: DateTime.utc(2026),
      ));
      expect(anonymous.title, 'New reply');
    });

    test('status change', () {
      final content = bannerContentFor(StatusChanged(
        itemId: 'i',
        fromStatus: 'open',
        toStatus: 'in_progress',
        createdAt: DateTime.utc(2026),
      ));
      expect(content.title, 'Status updated: in progress');
    });
  });

  testWidgets('shows, handles tap and auto-dismisses after 4s', (tester) async {
    final navigatorKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(MaterialApp(
      navigatorKey: navigatorKey,
      home: const Scaffold(body: SizedBox()),
    ));

    final banner = InAppNotificationBanner();
    var taps = 0;
    banner.show(
      overlay: navigatorKey.currentState!.overlay!,
      title: 'New reply',
      message: 'We shipped it',
      theme: const FeedbackOSTheme(),
      onTap: () => taps++,
    );
    await tester.pumpAndSettle();
    expect(find.text('New reply'), findsOneWidget);
    expect(find.text('We shipped it'), findsOneWidget);

    await tester.tap(find.text('New reply'));
    await tester.pumpAndSettle();
    expect(taps, 1);
    expect(find.text('New reply'), findsNothing);

    banner.show(
      overlay: navigatorKey.currentState!.overlay!,
      title: 'Status updated: shipped',
      message: '',
      theme: const FeedbackOSTheme(),
    );
    await tester.pumpAndSettle();
    expect(find.text('Status updated: shipped'), findsOneWidget);

    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    expect(find.text('Status updated: shipped'), findsNothing);
    expect(banner.isShowing, isFalse);
  });
}
