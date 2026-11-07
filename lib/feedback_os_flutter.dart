/// FeedbackOS Flutter SDK
///
/// A production-minded Flutter SDK for FeedbackOS bug reports, feature requests,
/// offline delivery, and roadmap integration.
library feedback_os_flutter;

// Core public facade & options
export 'src/feedback_os.dart' show FeedbackOS;
export 'src/config/feedback_os_options.dart' show FeedbackOSOptions;
export 'core/theme/theme.dart' show FeedbackOSTheme, FeedbackOSThemeProvider;

// Configuration & Ping Entities
export 'src/features/feedback/domain/entities/sdk_config_entity.dart'
    show SdkConfig, SdkBoardConfig, SdkRoadmapConfig, SdkLimitsConfig;
export 'src/features/feedback/domain/entities/sdk_ping_entity.dart'
    show SdkPingResult;

// Feedback Submission & Item Entities
export 'src/features/feedback/domain/entities/feedback_type.dart'
    show FeedbackType;
export 'src/features/feedback/domain/entities/feedback_device_info.dart'
    show FeedbackDeviceInfo;
export 'src/features/feedback/domain/entities/feedback_submission.dart'
    show FeedbackSubmission;
export 'src/features/feedback/domain/entities/feedback_item.dart'
    show FeedbackItem;
export 'src/features/feedback/domain/entities/feedback_submit_result.dart'
    show FeedbackSubmitResult, FeedbackSubmitStatus;

// Presentation & State (BLoC)
export 'src/features/feedback/presentation/feedback_form.dart'
    show FeedbackFormDialog;
export 'src/features/feedback/state/feedback_bloc.dart'
    show FeedbackBloc, FeedbackSubmitHandler;
export 'src/features/feedback/state/feedback_event.dart'
    show
        FeedbackEvent,
        FeedbackFormStarted,
        FeedbackTypeChanged,
        FeedbackTitleChanged,
        FeedbackDescriptionChanged,
        FeedbackCategoryChanged,
        FeedbackAttachmentAdded,
        FeedbackAttachmentRemoved,
        FeedbackSubmitted,
        FeedbackReset;
export 'src/features/feedback/state/feedback_state.dart'
    show FeedbackState, FeedbackFormStatus;

// Board Presentation & State (BLoC)
export 'src/features/board/presentation/board_view.dart' show BoardView;
export 'src/features/board/presentation/roadmap_view.dart' show RoadmapView;
export 'src/features/board/state/board_bloc.dart' show BoardBloc;
export 'src/features/board/state/board_event.dart'
    show
        BoardEvent,
        BoardStarted,
        BoardSortChanged,
        BoardNextPageRequested,
        BoardItemVoteToggled,
        RoadmapStarted;
export 'src/features/board/state/board_state.dart' show BoardState, BoardStatus;

// Threads Presentation & State (BLoC)
export 'src/features/threads/presentation/my_feedback_list_view.dart'
    show MyFeedbackListView;
export 'src/features/threads/presentation/thread_detail_view.dart'
    show ThreadDetailView;
export 'src/features/threads/state/threads_bloc.dart' show ThreadsBloc;
export 'src/features/threads/state/threads_event.dart'
    show
        ThreadsEvent,
        MyItemsStarted,
        ThreadDetailStarted,
        ThreadReplySubmitted,
        ThreadReadMarked;
export 'src/features/threads/state/threads_state.dart'
    show ThreadsState, ThreadsStatus;

// Offline Queue Entities & Contracts
export 'src/features/feedback/domain/entities/queued_feedback.dart'
    show QueuedFeedback, QueueStatus;
export 'src/features/feedback/data/datasources/submission_store.dart'
    show SubmissionStore;
export 'src/features/feedback/data/datasources/in_memory_submission_store.dart'
    show InMemorySubmissionStore;
export 'src/features/feedback/data/datasources/sqlite_submission_store.dart'
    show SqliteSubmissionStore;

// Upload & Attachment Entities
export 'src/features/uploads/domain/entities/upload_reservation.dart'
    show UploadReservation;
export 'src/features/uploads/domain/entities/screenshot_attachment.dart'
    show ScreenshotAttachment;

// Community Board & Roadmap Entities
export 'src/features/board/domain/entities/board_item.dart' show BoardItem;
export 'src/features/board/domain/entities/board_page.dart' show BoardPage;
export 'src/features/board/domain/entities/roadmap.dart' show Roadmap;
export 'src/features/board/domain/entities/vote_result.dart' show VoteResult;
export 'src/features/board/domain/repositories/board_repository.dart'
    show BoardRepository;

// User Threads & My Items Entities
export 'src/features/threads/domain/entities/unread_count.dart'
    show UnreadCount;
export 'src/features/threads/domain/entities/my_feedback_item.dart'
    show MyFeedbackItem;
export 'src/features/threads/domain/entities/thread_detail.dart'
    show ThreadDetail;
export 'src/features/threads/domain/entities/thread_reply.dart'
    show ThreadReply;
export 'src/features/threads/domain/entities/thread_event.dart'
    show ThreadEvent;
export 'src/features/threads/domain/repositories/threads_repository.dart'
    show ThreadsRepository;

// Public Exceptions
export 'src/core/errors/exceptions.dart'
    show
        FeedbackOsException,
        FeedbackOsNetworkException,
        FeedbackOsAuthenticationException,
        FeedbackOsSubscriptionException,
        FeedbackOsValidationException,
        FeedbackOsRateLimitException,
        FeedbackOsPayloadTooLargeException,
        FeedbackOsUploadNotFoundException,
        FeedbackOsUploadInvalidException,
        FeedbackOsStorageException,
        FeedbackOsServerException;

// Domain Failures (Functional fpdart Result types)
export 'src/core/errors/failures.dart'
    show
        Failure,
        NetworkFailure,
        AuthenticationFailure,
        SubscriptionFailure,
        ValidationFailure,
        FeatureDisabledFailure,
        RateLimitFailure,
        PayloadTooLargeFailure,
        UploadNotFoundFailure,
        UploadInvalidFailure,
        StorageFailure,
        ServerFailure;

// Device ID & Info provider contracts (for testing or custom providers)
export 'src/identity/device_id_store.dart'
    show DeviceIdStore, InMemoryDeviceIdStore;
export 'src/identity/device_info_provider.dart'
    show DeviceInfoProvider, StaticDeviceInfoProvider;

// Typography & Styles (per rule 16)
export 'core/theme/styles.dart' show AppStyles;
