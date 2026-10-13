import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:feedback_os_flutter/feedback_os_flutter.dart';

void main() {
  Widget buildTestableWidget(FeedbackBloc bloc) {
    return MaterialApp(
      home: Scaffold(
        body: BlocProvider<FeedbackBloc>.value(
          value: bloc,
          child: const FeedbackFormDialog(),
        ),
      ),
    );
  }

  group('FeedbackFormDialog Widget Tests', () {
    testWidgets('renders all initial fields and disabled submit button',
        (tester) async {
      final bloc = FeedbackBloc(
        submitHandler: ({
          required type,
          required title,
          required description,
          category,
        }) async =>
            const FeedbackSubmitResult(
          status: FeedbackSubmitStatus.sent,
          clientSubmissionId: 'sub_1',
        ),
      );

      await tester.pumpWidget(buildTestableWidget(bloc));
      await tester.pumpAndSettle();

      expect(find.text('Send Feedback'),
          findsNWidgets(2)); // Header title + button text
      expect(find.byKey(const Key('feedback_type_bug')), findsOneWidget);
      expect(find.byKey(const Key('feedback_type_feature')), findsOneWidget);
      expect(find.byKey(const Key('feedback_title_field')), findsOneWidget);
      expect(
          find.byKey(const Key('feedback_description_field')), findsOneWidget);

      final submitBtn = tester.widget<ElevatedButton>(
        find.byKey(const Key('feedback_submit_button')),
      );
      expect(submitBtn.onPressed, isNull); // disabled because title is empty
    });

    testWidgets('typing title enables submit button and toggling type works',
        (tester) async {
      final bloc = FeedbackBloc(
        submitHandler: ({
          required type,
          required title,
          required description,
          category,
        }) async =>
            const FeedbackSubmitResult(
          status: FeedbackSubmitStatus.sent,
          clientSubmissionId: 'sub_1',
        ),
      );

      await tester.pumpWidget(buildTestableWidget(bloc));
      await tester.pumpAndSettle();

      // Enter title
      await tester.enterText(
        find.byKey(const Key('feedback_title_field')),
        'Login button broken',
      );
      await tester.pumpAndSettle();

      final submitBtn = tester.widget<ElevatedButton>(
        find.byKey(const Key('feedback_submit_button')),
      );
      expect(submitBtn.onPressed, isNotNull);

      // Toggle to Feature
      await tester.tap(find.byKey(const Key('feedback_type_feature')));
      await tester.pumpAndSettle();
      expect(bloc.state.type, equals(FeedbackType.feature));
    });

    testWidgets('submitting successfully displays Thank You view',
        (tester) async {
      final bloc = FeedbackBloc(
        submitHandler: ({
          required type,
          required title,
          required description,
          category,
        }) async =>
            const FeedbackSubmitResult(
          status: FeedbackSubmitStatus.sent,
          itemId: 'item_123',
          clientSubmissionId: 'sub_1',
        ),
      );

      await tester.pumpWidget(buildTestableWidget(bloc));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('feedback_title_field')),
        'Valid title',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('feedback_submit_button')));
      await tester.pumpAndSettle();

      expect(find.text('Thank You!'), findsOneWidget);
      expect(find.byKey(const Key('feedback_success_done_button')),
          findsOneWidget);
    });

    testWidgets('submitting offline displays Saved for Later view',
        (tester) async {
      final bloc = FeedbackBloc(
        submitHandler: ({
          required type,
          required title,
          required description,
          category,
        }) async =>
            const FeedbackSubmitResult(
          status: FeedbackSubmitStatus.queued,
          clientSubmissionId: 'sub_1',
        ),
      );

      await tester.pumpWidget(buildTestableWidget(bloc));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('feedback_title_field')),
        'Offline feedback',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('feedback_submit_button')));
      await tester.pumpAndSettle();

      expect(find.text('Saved for Later'), findsOneWidget);
      expect(find.textContaining('saved offline'), findsOneWidget);
    });
  });
}
