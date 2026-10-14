import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:feedback_os_flutter/feedback_os_flutter.dart';
import 'package:feedback_os_flutter/src/features/feedback/domain/repositories/feedback_repository.dart';
import 'package:feedback_os_flutter/src/features/feedback/domain/usecases/get_sdk_config_usecase.dart';

class MockFeedbackRepository extends Mock implements FeedbackRepository {}

void main() {
  group('FeedbackBloc', () {
    late MockFeedbackRepository mockRepository;
    late GetSdkConfigUseCase getConfigUseCase;

    const testConfig = SdkConfig(
      appId: '1c0e8260-63ee-4213-a70d-f06f88da777c',
      configVersion: 1,
      enabled: true,
      board: SdkBoardConfig(enabled: true),
      roadmap: SdkRoadmapConfig(enabled: true),
      categories: ['Billing', 'UI', 'Performance'],
      statuses: ['open'],
      limits: SdkLimitsConfig(
        maxScreenshots: 3,
        maxScreenshotBytes: 5000000,
        screenshotTypes: ['image/png'],
      ),
    );

    setUp(() {
      mockRepository = MockFeedbackRepository();
      getConfigUseCase = GetSdkConfigUseCase(mockRepository);
    });

    test('initial state has default values and canSubmit is false', () {
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

      expect(bloc.state.status, equals(FeedbackFormStatus.initial));
      expect(bloc.state.type, equals(FeedbackType.bug));
      expect(bloc.state.title, isEmpty);
      expect(bloc.state.attachments, isEmpty);
      expect(bloc.state.canSubmit, isFalse);
      expect(bloc.state.canAddAttachment, isTrue);
    });

    test('FeedbackFormStarted loads categories from config', () async {
      when(() => mockRepository.getConfig(any()))
          .thenAnswer((_) async => const Right(testConfig));

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
        getConfigUseCase: getConfigUseCase,
        publishableKey: 'fos_pk_test',
      );

      bloc.add(const FeedbackFormStarted(initialType: FeedbackType.feature));
      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<FeedbackState>()
              .having(
                  (s) => s.status, 'status', FeedbackFormStatus.loadingConfig)
              .having((s) => s.type, 'type', FeedbackType.feature),
          isA<FeedbackState>()
              .having((s) => s.status, 'status', FeedbackFormStatus.ready)
              .having((s) => s.availableCategories, 'categories',
                  ['Billing', 'UI', 'Performance']),
        ]),
      );
    });

    test('updates form fields and enables canSubmit when title is non-empty',
        () async {
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

      bloc.add(const FeedbackTypeChanged(FeedbackType.feature));
      bloc.add(const FeedbackTitleChanged('Add Dark Mode'));
      bloc.add(const FeedbackDescriptionChanged('Please add theme options'));
      bloc.add(const FeedbackCategoryChanged('UI'));

      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<FeedbackState>()
              .having((s) => s.type, 'type', FeedbackType.feature),
          isA<FeedbackState>()
              .having((s) => s.title, 'title', 'Add Dark Mode')
              .having((s) => s.canSubmit, 'canSubmit', isTrue),
          isA<FeedbackState>().having(
              (s) => s.description, 'description', 'Please add theme options'),
          isA<FeedbackState>().having((s) => s.category, 'category', 'UI'),
        ]),
      );
    });

    test('FeedbackAttachmentAdded and FeedbackAttachmentRemoved update state',
        () async {
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

      final attachment = ScreenshotAttachment(
        fileName: 'screen.png',
        contentType: 'image/png',
        bytes: Uint8List.fromList([1, 2, 3]),
      );

      bloc.add(FeedbackAttachmentAdded(attachment));
      await expectLater(
        bloc.stream,
        emits(isA<FeedbackState>()
            .having((s) => s.attachments.length, 'attachments length', 1)),
      );

      bloc.add(const FeedbackAttachmentRemoved(0));
      await expectLater(
        bloc.stream,
        emits(isA<FeedbackState>()
            .having((s) => s.attachments.length, 'attachments length', 0)),
      );
    });

    test('cannot add more than 3 attachments', () async {
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

      final a1 = ScreenshotAttachment(
        fileName: '1.png',
        contentType: 'image/png',
        bytes: Uint8List.fromList([1]),
      );
      final a2 = ScreenshotAttachment(
        fileName: '2.png',
        contentType: 'image/png',
        bytes: Uint8List.fromList([2]),
      );
      final a3 = ScreenshotAttachment(
        fileName: '3.png',
        contentType: 'image/png',
        bytes: Uint8List.fromList([3]),
      );
      final a4 = ScreenshotAttachment(
        fileName: '4.png',
        contentType: 'image/png',
        bytes: Uint8List.fromList([4]),
      );

      bloc.add(FeedbackAttachmentAdded(a1));
      bloc.add(FeedbackAttachmentAdded(a2));
      bloc.add(FeedbackAttachmentAdded(a3));
      bloc.add(FeedbackAttachmentAdded(a4));

      await expectLater(
        bloc.stream,
        emitsThrough(isA<FeedbackState>()
            .having((s) => s.errorMessage, 'errorMessage',
                contains('Cannot attach more than 3 screenshots'))),
      );
      expect(bloc.state.attachments.length, 3);
    });

    test(
        'FeedbackSubmitted emits submitting then success on successful delivery',
        () async {
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
          itemId: 'item_99',
          clientSubmissionId: 'sub_1',
        ),
      );

      bloc.add(const FeedbackTitleChanged('Bug title'));
      await bloc.stream.first; // Wait for title change to process

      bloc.add(const FeedbackSubmitted());
      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<FeedbackState>()
              .having((s) => s.status, 'status', FeedbackFormStatus.submitting),
          isA<FeedbackState>()
              .having((s) => s.status, 'status', FeedbackFormStatus.success)
              .having((s) => s.submissionResult?.itemId, 'itemId', 'item_99'),
        ]),
      );
    });

    test('FeedbackSubmitted emits failure when submitHandler throws', () async {
      final bloc = FeedbackBloc(
        submitHandler: ({
          required type,
          required title,
          required description,
          category,
          attachments = const [],
        }) async =>
            throw const FeedbackOsValidationException('Invalid request'),
      );

      bloc.add(const FeedbackTitleChanged('Invalid title'));
      await bloc.stream.first;

      bloc.add(const FeedbackSubmitted());
      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<FeedbackState>()
              .having((s) => s.status, 'status', FeedbackFormStatus.submitting),
          isA<FeedbackState>()
              .having((s) => s.status, 'status', FeedbackFormStatus.failure)
              .having(
                  (s) => s.errorMessage, 'error', contains('Invalid request')),
        ]),
      );
    });
  });
}
