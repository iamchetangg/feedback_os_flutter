import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import 'config/feedback_os_options.dart';
import 'core/errors/exceptions.dart';
import 'core/errors/failures.dart';
import 'core/network/feedback_os_dio_client.dart';
import 'features/feedback/data/datasources/feedback_remote_data_source.dart';
import 'features/feedback/data/repositories/feedback_repository_impl.dart';
import 'features/feedback/domain/entities/feedback_device_info.dart';
import 'features/feedback/domain/entities/feedback_submit_result.dart';
import 'features/feedback/domain/entities/feedback_submission.dart';
import 'features/feedback/domain/entities/feedback_type.dart';
import 'features/feedback/domain/entities/sdk_config_entity.dart';
import 'features/feedback/domain/entities/sdk_ping_entity.dart';
import 'features/feedback/domain/repositories/feedback_repository.dart';
import 'features/feedback/domain/usecases/get_sdk_config_usecase.dart';
import 'features/feedback/domain/usecases/identify_user_usecase.dart';
import 'features/feedback/domain/usecases/ping_sdk_usecase.dart';
import 'features/feedback/domain/usecases/submit_feedback_usecase.dart';
import 'identity/device_id_store.dart';
import 'identity/device_info_provider.dart';

/// The primary entrypoint and public facade for the FeedbackOS Flutter SDK.
class FeedbackOS {
  FeedbackOS._();

  static final FeedbackOS _instance = FeedbackOS._();

  /// Access the shared instance of [FeedbackOS].
  static FeedbackOS get instance => _instance;

  bool _isInitialized = false;
  String? _publishableKey;
  FeedbackOSOptions? _options;
  DeviceIdStore? _deviceIdStore;
  DeviceInfoProvider? _deviceInfoProvider;
  FeedbackOsHttpClient? _httpClient;
  FeedbackRepository? _repository;

  GetSdkConfigUseCase? _getConfigUseCase;
  PingSdkUseCase? _pingUseCase;
  IdentifyUserUseCase? _identifyUseCase;
  SubmitFeedbackUseCase? _submitFeedbackUseCase;

  String? _activeExternalUserId;

  /// Whether the SDK has been initialized.
  bool get isInitialized => _isInitialized;

  /// The active publishable key.
  String? get publishableKey => _publishableKey;

  /// The currently identified external user ID, if any.
  String? get activeExternalUserId => _activeExternalUserId;

  /// Internal access to the repository (for feature widgets & controllers).
  FeedbackRepository get repository {
    _ensureInitialized();
    return _repository!;
  }

  /// Internal access to device ID store.
  DeviceIdStore get deviceIdStore {
    _ensureInitialized();
    return _deviceIdStore!;
  }

  /// Internal access to device info provider.
  DeviceInfoProvider get deviceInfoProvider {
    _ensureInitialized();
    return _deviceInfoProvider!;
  }

  /// Initializes the FeedbackOS SDK.
  ///
  /// Safe to call repeatedly with the same [publishableKey].
  /// Does not require immediate network connectivity to initialize.
  Future<void> initialize({
    required String publishableKey,
    FeedbackOSOptions? options,
    DeviceIdStore? deviceIdStore,
    DeviceInfoProvider? deviceInfoProvider,
    FeedbackOsHttpClient? httpClient,
  }) async {
    final sanitizedKey = publishableKey.trim();

    // Local validation
    if (sanitizedKey.isEmpty) {
      throw const FeedbackOsValidationException(
        'FeedbackOS publishable key cannot be empty.',
      );
    }
    if (!sanitizedKey.startsWith('fos_pk_')) {
      throw const FeedbackOsValidationException(
        "Invalid key prefix. FeedbackOS publishable keys must start with 'fos_pk_'.",
      );
    }

    // Idempotent initialization check
    if (_isInitialized) {
      if (_publishableKey == sanitizedKey) {
        return;
      } else {
        throw const FeedbackOsValidationException(
          'FeedbackOS is already initialized with a different key. '
          'Call reset() before reinitializing with a new project.',
        );
      }
    }

    _publishableKey = sanitizedKey;
    _options = options ?? FeedbackOSOptions();
    _deviceIdStore = deviceIdStore ?? SecureDeviceIdStore();
    _deviceInfoProvider = deviceInfoProvider ?? DefaultDeviceInfoProvider();

    _httpClient = httpClient ??
        FeedbackOsDioClient(
          publishableKey: sanitizedKey,
          getDeviceId: () => _deviceIdStore!.getOrCreateDeviceId(),
          options: _options!,
        );

    final remoteDataSource = FeedbackRemoteDataSourceImpl(client: _httpClient!);
    _repository = FeedbackRepositoryImpl(remoteDataSource: remoteDataSource);

    _getConfigUseCase = GetSdkConfigUseCase(_repository!);
    _pingUseCase = PingSdkUseCase(_repository!);
    _identifyUseCase = IdentifyUserUseCase(_repository!);
    _submitFeedbackUseCase = SubmitFeedbackUseCase(_repository!);

    _isInitialized = true;
  }

  void _ensureInitialized() {
    if (!_isInitialized) {
      throw const FeedbackOsValidationException(
        'FeedbackOS is not initialized. Call FeedbackOS.instance.initialize(...) first.',
      );
    }
  }

  /// Retrieves the persistent lowercase device UUIDv4.
  Future<String> getDeviceId() async {
    _ensureInitialized();
    return _deviceIdStore!.getOrCreateDeviceId();
  }

  /// Pings the FeedbackOS server to validate the publishable key and device.
  Future<SdkPingResult> ping({CancelToken? cancelToken}) async {
    _ensureInitialized();
    final result = await _pingUseCase!.call(cancelToken: cancelToken);
    return result.fold(
      (failure) => throw _mapFailureToException(failure),
      (data) => data,
    );
  }

  /// Fetches the project SDK configuration from the server.
  Future<SdkConfig> getConfig({CancelToken? cancelToken}) async {
    _ensureInitialized();
    final result = await _getConfigUseCase!.call(
      _publishableKey!,
      cancelToken: cancelToken,
    );
    return result.fold(
      (failure) => throw _mapFailureToException(failure),
      (data) => data,
    );
  }

  /// Associates the current device with an external user ID in the host app.
  Future<void> identify({
    required String? externalUserId,
    CancelToken? cancelToken,
  }) async {
    _ensureInitialized();
    if (externalUserId != null && externalUserId.length > 255) {
      throw const FeedbackOsValidationException(
        'externalUserId cannot exceed 255 characters.',
      );
    }

    final result = await _identifyUseCase!.call(
      externalUserId,
      cancelToken: cancelToken,
    );

    result.fold(
      (failure) => throw _mapFailureToException(failure),
      (_) {
        _activeExternalUserId = externalUserId;
      },
    );
  }

  /// Disassociates any active external user ID from the device.
  Future<void> clearIdentity({CancelToken? cancelToken}) async {
    await identify(externalUserId: null, cancelToken: cancelToken);
  }

  /// Submits feedback (bug or feature request) to the FeedbackOS API.
  Future<FeedbackSubmitResult> submitFeedback({
    required FeedbackType type,
    required String title,
    String description = '',
    String? category,
    List<String> screenshotUploadIds = const [],
    String? clientSubmissionId,
    FeedbackDeviceInfo? customDeviceInfo,
    CancelToken? cancelToken,
  }) async {
    _ensureInitialized();

    final submissionId = clientSubmissionId ?? const Uuid().v4().toLowerCase();
    final device =
        customDeviceInfo ?? await _deviceInfoProvider!.getDeviceInfo();

    final submission = FeedbackSubmission(
      clientSubmissionId: submissionId,
      type: type,
      title: title,
      description: description,
      category: category,
      device: device,
      screenshotUploadIds: screenshotUploadIds,
    );

    try {
      submission.validate();
    } on ArgumentError catch (e) {
      throw FeedbackOsValidationException(e.message.toString());
    }

    final result = await _submitFeedbackUseCase!.call(
      submission,
      cancelToken: cancelToken,
    );

    return result.fold(
      (failure) => throw _mapFailureToException(failure),
      (item) => FeedbackSubmitResult(
        status: FeedbackSubmitStatus.sent,
        itemId: item.id,
        clientSubmissionId: submissionId,
        item: item,
      ),
    );
  }

  /// Resets the SDK state. Mainly used in unit and integration testing.
  Future<void> reset() async {
    _isInitialized = false;
    _publishableKey = null;
    _options = null;
    _deviceIdStore = null;
    _deviceInfoProvider = null;
    _httpClient = null;
    _repository = null;
    _getConfigUseCase = null;
    _pingUseCase = null;
    _identifyUseCase = null;
    _submitFeedbackUseCase = null;
    _activeExternalUserId = null;
  }

  FeedbackOsException _mapFailureToException(Failure failure) {
    return switch (failure) {
      AuthenticationFailure() => FeedbackOsAuthenticationException(
          failure.message,
          code: failure.code ?? 'invalid_key',
          statusCode: failure.statusCode ?? 401,
        ),
      SubscriptionFailure() => FeedbackOsSubscriptionException(
          failure.message,
          code: failure.code ?? 'subscription_required',
          statusCode: failure.statusCode ?? 402,
        ),
      ValidationFailure() => FeedbackOsValidationException(
          failure.message,
          code: failure.code ?? 'invalid_request',
          statusCode: failure.statusCode ?? 400,
        ),
      PayloadTooLargeFailure() => FeedbackOsPayloadTooLargeException(
          failure.message,
          statusCode: failure.statusCode ?? 413,
        ),
      RateLimitFailure() => FeedbackOsRateLimitException(
          failure.message,
          statusCode: failure.statusCode ?? 429,
          retryAfter: failure.retryAfter,
        ),
      NetworkFailure() => FeedbackOsNetworkException(
          failure.message,
          statusCode: failure.statusCode,
        ),
      StorageFailure() => FeedbackOsStorageException(failure.message),
      ServerFailure() => FeedbackOsServerException(
          failure.message,
          code: failure.code ?? 'internal_error',
          statusCode: failure.statusCode ?? 500,
        ),
      _ => FeedbackOsServerException(failure.message),
    };
  }
}
