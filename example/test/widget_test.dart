import 'package:flutter_test/flutter_test.dart';
import 'package:feedback_os_flutter/feedback_os_flutter.dart';
import 'package:example/main.dart';

void main() {
  testWidgets('FeedbackOsExampleApp smoke test', (WidgetTester tester) async {
    // Reset and initialize SDK with in-memory store for widget test
    await FeedbackOS.instance.reset();
    await FeedbackOS.instance.initializeTest(
      publishableKey: 'fos_pk_test_sample_12345',
      deviceIdStore: InMemoryDeviceIdStore(),
      submissionStore: InMemorySubmissionStore(),
      deviceInfoProvider: const StaticDeviceInfoProvider(),
    );

    await tester.pumpWidget(const FeedbackOsExampleApp());
    await tester.pumpAndSettle();

    expect(find.text('FeedbackOS Example'), findsOneWidget);
    expect(find.text('Report a Bug'), findsOneWidget);
    expect(find.text('Request a Feature'), findsOneWidget);
    expect(find.text('Community Feature Board'), findsOneWidget);
    expect(find.text('Product Roadmap'), findsOneWidget);
    expect(find.text('My Feedback Threads'), findsOneWidget);
  });
}
