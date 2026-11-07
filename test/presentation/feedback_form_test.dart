import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:feedback_os_flutter/feedback_os_flutter.dart';
import 'package:image/image.dart' as img;

void main() {
  Widget buildTestableWidget(FeedbackBloc bloc,
      {Future<ScreenshotAttachment?> Function()? onPick}) {
    return MaterialApp(
      home: Scaffold(
        body: BlocProvider<FeedbackBloc>.value(
          value: bloc,
          child: FeedbackFormDialog(onPickAttachment: onPick),
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
          attachments = const [],
        }) async =>
            const FeedbackSubmitResult(
          status: FeedbackSubmitStatus.sent,
          clientSubmissionId: 'sub_1',
        ),
      );

      await tester.pumpWidget(buildTestableWidget(bloc));
      await tester.pumpAndSettle();

      expect(find.text('Send Feedback'), findsOneWidget); // Header title
      expect(find.text('Send'), findsOneWidget); // Submit button text
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
          attachments = const [],
        }) async =>
            const FeedbackSubmitResult(
          status: FeedbackSubmitStatus.sent,
          clientSubmissionId: 'sub_1',
        ),
      );

      await tester.pumpWidget(buildTestableWidget(bloc));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('feedback_title_field')),
        'App crashed on login',
      );
      await tester.pumpAndSettle();

      final submitBtn = tester.widget<ElevatedButton>(
        find.byKey(const Key('feedback_submit_button')),
      );
      expect(submitBtn.onPressed, isNotNull); // enabled now

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
          attachments = const [],
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
          attachments = const [],
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

    testWidgets('picking and removing screenshot attachments works',
        (tester) async {
      final bloc = FeedbackBloc(
        submitHandler: ({
          required type,
          required title,
          required description,
          category,
          attachments = const [],
        }) async =>
            const FeedbackSubmitResult(
          status: FeedbackSubmitStatus.sent,
          clientSubmissionId: 'sub_1',
        ),
      );

      final dummyAttachment = ScreenshotAttachment(
        fileName: 'screen.png',
        contentType: 'image/png',
        bytes: Uint8List.fromList([1, 2, 3]),
      );

      await tester.pumpWidget(
        buildTestableWidget(bloc, onPick: () async => dummyAttachment),
      );
      await tester.pumpAndSettle();

      // Tap Add attachment button
      expect(find.byKey(const Key('feedback_add_attachment_button')),
          findsOneWidget);
      await tester.tap(find.byKey(const Key('feedback_add_attachment_button')));
      await tester.pumpAndSettle();

      expect(bloc.state.attachments.length, 1);
      expect(find.text('1/3'), findsOneWidget);
      expect(find.byKey(const Key('feedback_remove_attachment_0')),
          findsOneWidget);

      // Tap remove attachment
      await tester.tap(find.byKey(const Key('feedback_remove_attachment_0')));
      await tester.pumpAndSettle();

      expect(bloc.state.attachments.length, 0);
      expect(find.text('0/3'), findsOneWidget);
    });

    testWidgets(
        'full screenshot flow: attach screenshot -> compress under 256 KB -> upload to get id -> submit with upload id',
        (tester) async {
      bool uploadApiRan = false;
      bool submitApiRan = false;
      List<String> submittedUploadIds = [];

      // Create a valid encoded image > 256 KB
      final random = math.Random(123);
      final testImg = img.Image(width: 1000, height: 800);
      for (int y = 0; y < 800; y++) {
        for (int x = 0; x < 1000; x++) {
          testImg.setPixelRgba(
            x,
            y,
            random.nextInt(256),
            random.nextInt(256),
            random.nextInt(256),
            255,
          );
        }
      }
      final rawLargeBytes = Uint8List.fromList(img.encodePng(testImg));
      expect(rawLargeBytes.lengthInBytes, greaterThan(256 * 1024));

      final bloc = FeedbackBloc(
        submitHandler: ({
          required type,
          required title,
          required description,
          category,
          attachments = const [],
        }) async {
          // 1. First run upload screenshot API for each attachment
          final uploadIds = <String>[];
          for (final att in attachments) {
            uploadApiRan = true;
            expectSync(att.byteSize, lessThanOrEqualTo(256 * 1024));
            // Simulate upload returning reference id
            uploadIds.add('upload_ref_789');
          }

          // 2. Then submit with upload reference ids
          submitApiRan = true;
          submittedUploadIds = uploadIds;

          return const FeedbackSubmitResult(
            status: FeedbackSubmitStatus.sent,
            itemId: 'item_ss_123',
            clientSubmissionId: 'sub_ss_1',
          );
        },
      );

      // Render form dialog with attachment picker returning uncompressed large bytes
      await tester.pumpWidget(
        buildTestableWidget(
          bloc,
          onPick: () async => ScreenshotAttachment(
            fileName: 'large_screen.jpg',
            contentType: 'image/jpeg',
            bytes: rawLargeBytes,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Form is open -> verify attach screenshot button is present
      final addBtnFinder = find.byKey(const Key('feedback_add_attachment_button'));
      expect(addBtnFinder, findsOneWidget);

      // User clicks attach screenshot button -> image is selected and referenced
      await tester.tap(addBtnFinder);
      await tester.pumpAndSettle();

      // Verify app references file, compressed to under 256 KB
      expect(bloc.state.attachments.length, 1);
      expect(bloc.state.attachments.first.byteSize,
          lessThanOrEqualTo(256 * 1024));
      expect(find.text('1/3'), findsOneWidget);

      // User enters title
      await tester.enterText(
        find.byKey(const Key('feedback_title_field')),
        'Screenshot bug report',
      );
      await tester.pumpAndSettle();

      final buttonWidget =
          tester.widget<ElevatedButton>(find.byKey(const Key('feedback_submit_button')));
      // print('canSubmit: ${bloc.state.canSubmit}, title: ${bloc.state.title}, status: ${bloc.state.status}, onPressed: ${buttonWidget.onPressed}');
      expect(buttonWidget.onPressed, isNotNull);

      // User clicks Submit
      final submitBtn = find.byKey(const Key('feedback_submit_button'));
      await tester.ensureVisible(submitBtn);
      await tester.pumpAndSettle();
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      // Verify: First upload API ran, then submit API referenced the upload ID
      expect(uploadApiRan, isTrue);
      expect(submitApiRan, isTrue);
      expect(submittedUploadIds, equals(['upload_ref_789']));

      // Thank You success view is displayed
      expect(find.text('Thank You!'), findsOneWidget);
    });
  });
}
