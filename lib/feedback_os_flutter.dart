/// FeedbackOS Flutter SDK
///
/// A production-minded Flutter SDK for FeedbackOS bug reports, feature requests,
/// offline delivery, and roadmap integration.
library feedback_os_flutter;

// Core public facade & options
export 'src/feedback_os.dart' show FeedbackOS;
export 'src/config/feedback_os_options.dart' show FeedbackOSOptions;

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
        RateLimitFailure,
        PayloadTooLargeFailure,
        StorageFailure,
        ServerFailure;

// Device ID & Info provider contracts (for testing or custom providers)
export 'src/identity/device_id_store.dart'
    show DeviceIdStore, InMemoryDeviceIdStore;
export 'src/identity/device_info_provider.dart'
    show DeviceInfoProvider, StaticDeviceInfoProvider;

// Typography & Styles (per rule 16)
export 'core/theme/styles.dart' show AppStyles;
