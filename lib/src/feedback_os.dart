import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'config/feedback_os_options.dart';
import 'core/errors/exceptions.dart';
import 'core/errors/failures.dart';
import 'core/network/feedback_os_dio_client.dart';
import 'features/feedback/data/datasources/feedback_remote_data_source.dart';
import 'features/feedback/data/datasources/queue_sync_engine.dart';
import 'features/feedback/data/datasources/sqlite_submission_store.dart';
import 'features/feedback/data/datasources/submission_store.dart';
import 'features/feedback/data/models/feedback_submission_model.dart';
import 'features/feedback/data/repositories/feedback_repository_impl.dart';
import 'features/feedback/domain/entities/feedback_device_info.dart';
import 'features/feedback/domain/entities/feedback_submit_result.dart';
import 'features/feedback/domain/entities/feedback_submission.dart';
import 'features/feedback/domain/entities/feedback_type.dart';
import 'features/feedback/domain/entities/queued_feedback.dart';
import 'features/feedback/domain/entities/sdk_config_entity.dart';
import 'features/feedback/domain/entities/sdk_ping_entity.dart';
import 'features/feedback/domain/repositories/feedback_repository.dart';
import 'features/feedback/domain/usecases/get_sdk_config_usecase.dart';
import 'features/feedback/domain/usecases/identify_user_usecase.dart';
import 'features/feedback/domain/usecases/ping_sdk_usecase.dart';
import 'features/feedback/domain/usecases/submit_feedback_usecase.dart';
import 'features/feedback/presentation/feedback_form.dart';
import 'features/feedback/state/feedback_bloc.dart';
import 'features/feedback/state/feedback_event.dart';
import 'features/uploads/data/datasources/binary_uploader.dart';
import 'features/uploads/data/datasources/upload_remote_data_source.dart';
import 'features/uploads/data/repositories/upload_repository_impl.dart';
import 'features/uploads/domain/entities/screenshot_attachment.dart';
import 'features/uploads/domain/repositories/upload_repository.dart';
import 'features/uploads/domain/usecases/upload_screenshot_use_case.dart';
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
  SubmissionStore? _submissionStore;
  QueueSyncEngine? _queueSyncEngine;
  FeedbackOsHttpClient? _httpClient;
  FeedbackRepository? _repository;
  UploadRepository? _uploadRepository;

  GetSdkConfigUseCase? _getConfigUseCase;
  PingSdkUseCase? _pingUseCase;
  IdentifyUserUseCase? _identifyUseCase;
  SubmitFeedbackUseCase? _submitFeedbackUseCase;
  UploadScreenshotUseCase? _uploadScreenshotUseCase;

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

  /// Internal access to offline submission store.
  SubmissionStore get submissionStore {
    _ensureInitialized();
    return _submissionStore!;
  }

  /// Internal access to upload repository.
  UploadRepository get uploadRepository {
    _ensureInitialized();
    return _uploadRepository!;
  }

  /// Internal access to upload screenshot use case.
  UploadScreenshotUseCase get uploadScreenshotUseCase {
    _ensureInitialized();
    return _uploadScreenshotUseCase!;
  }

  /// Initializes the FeedbackOS SDK.
  ///
  /// Safe to call repeatedly with the same [publishableKey].
  /// Opens durable local storage without requiring network access.
  Future<void> initialize({
    required String publishableKey,
    FeedbackOSOptions? options,
    DeviceIdStore? deviceIdStore,
    DeviceInfoProvider? deviceInfoProvider,
    SubmissionStore? submissionStore,
    FeedbackOsHttpClient? httpClient,
    UploadRepository? uploadRepository,
    BinaryUploader? binaryUploader,
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
    _submissionStore = submissionStore ?? SqliteSubmissionStore();

    // Open persistent offline storage
    await _submissionStore!.open();

    _httpClient = httpClient ??
        FeedbackOsDioClient(
          publishableKey: sanitizedKey,
          getDeviceId: () => _deviceIdStore!.getOrCreateDeviceId(),
          options: _options!,
        );

    final remoteDataSource = FeedbackRemoteDataSourceImpl(client: _httpClient!);
    _repository = FeedbackRepositoryImpl(remoteDataSource: remoteDataSource);

    final uploadRemoteDataSource =
        UploadRemoteDataSourceImpl(client: _httpClient!);
    _uploadRepository = uploadRepository ??
        UploadRepositoryImpl(
          remoteDataSource: uploadRemoteDataSource,
          binaryUploader: binaryUploader ?? DioBinaryUploader(),
        );

    _getConfigUseCase = GetSdkConfigUseCase(_repository!);
    _pingUseCase = PingSdkUseCase(_repository!);
    _identifyUseCase = IdentifyUserUseCase(_repository!);
    _submitFeedbackUseCase = SubmitFeedbackUseCase(_repository!);
    _uploadScreenshotUseCase = UploadScreenshotUseCase(_uploadRepository!);

    _queueSyncEngine = QueueSyncEngine(
      store: _submissionStore!,
      remoteDataSource: remoteDataSource,
      options: _options!,
      appScope: sanitizedKey,
      getActiveUserId: () async => _activeExternalUserId,
      setActiveUserId: (id) async => _activeExternalUserId = id,
    );

    _isInitialized = true;

    // Trigger non-blocking sync of pending submissions
    unawaited(_queueSyncEngine!.flushQueue());
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

  /// Uploads a screenshot attachment directly to the presigned storage URL.
  Future<String> uploadScreenshot({
    required ScreenshotAttachment attachment,
    CancelToken? cancelToken,
  }) async {
    _ensureInitialized();
    final result = await _uploadScreenshotUseCase!.call(
      attachment: attachment,
      cancelToken: cancelToken,
    );
    return result.fold(
      (failure) => throw _mapFailureToException(failure),
      (uploadId) => uploadId,
    );
  }

  /// Submits feedback (bug or feature request) following persist-before-send delivery.
  ///
  /// 1. Validates local payload bounds.
  /// 2. Commits submission to durable offline queue.
  /// 3. Attempts immediate transmission.
  /// 4. If delivered (HTTP 201/200), removes from queue and returns status `sent`.
  /// 5. If network fails, leaves in queue with scheduled retry and returns status `queued`.
  Future<FeedbackSubmitResult> submitFeedback({
    required FeedbackType type,
    required String title,
    String description = '',
    String? category,
    List<ScreenshotAttachment> attachments = const [],
    List<String> screenshotUploadIds = const [],
    String? clientSubmissionId,
    FeedbackDeviceInfo? customDeviceInfo,
    CancelToken? cancelToken,
  }) async {
    _ensureInitialized();

    final effectiveUploadIds = List<String>.from(screenshotUploadIds);
    if (attachments.isNotEmpty) {
      for (final attachment in attachments) {
        if (attachment.uploadId != null) {
          effectiveUploadIds.add(attachment.uploadId!);
        } else {
          final uploadResult = await _uploadScreenshotUseCase!.call(
            attachment: attachment,
            cancelToken: cancelToken,
          );
          final uploadId = uploadResult.fold(
            (failure) => throw _mapFailureToException(failure),
            (id) => id,
          );
          effectiveUploadIds.add(uploadId);
        }
      }
    }

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
      screenshotUploadIds: effectiveUploadIds,
    );

    try {
      submission.validate();
    } on ArgumentError catch (e) {
      throw FeedbackOsValidationException(e.message.toString());
    }

    // Check queue bounds
    final totalCount =
        await _submissionStore!.getTotalCount(appScope: _publishableKey!);
    if (totalCount >= _options!.maxOfflineQueueSize) {
      throw FeedbackOsStorageException(
        'Offline queue capacity reached (${_options!.maxOfflineQueueSize} items). '
        'Cannot accept new feedback submissions until space is freed.',
      );
    }

    // 1. Persist before send
    final submissionModel = FeedbackSubmissionModel.fromEntity(submission);
    final now = DateTime.now().toUtc();
    final queuedItem = QueuedFeedback(
      clientSubmissionId: submissionId,
      payloadJson: jsonEncode(submissionModel.toJson()),
      appScope: _publishableKey!,
      externalUserId: _activeExternalUserId,
      createdAt: now,
      nextAttemptAt: now,
      status: QueueStatus.pending,
    );

    try {
      await _submissionStore!.insert(queuedItem);
    } catch (e) {
      throw FeedbackOsStorageException(
        'Failed to persist feedback submission to offline storage: $e',
      );
    }

    // 2. Attempt immediate delivery
    try {
      final result = await _submitFeedbackUseCase!.call(
        submission,
        cancelToken: cancelToken,
      );

      return await result.fold(
        (failure) async {
          final exception = _mapFailureToException(failure);

          if (exception is FeedbackOsValidationException ||
              exception is FeedbackOsPayloadTooLargeException) {
            // Permanent rejection -> mark failed and throw
            await _submissionStore!.markPermanentlyFailed(
              submissionId,
              errorCode: exception.code ?? 'invalid_request',
              errorMessage: exception.message,
            );
            throw exception;
          } else if (exception is FeedbackOsAuthenticationException ||
              exception is FeedbackOsSubscriptionException) {
            // Auth / billing issue -> keep in queue, throw exception
            await _submissionStore!.scheduleRetry(
              submissionId,
              nextAttemptAt: now.add(const Duration(minutes: 5)),
              attemptCount: 1,
              errorCode: exception.code ?? 'auth_error',
              errorMessage: exception.message,
            );
            throw exception;
          } else {
            // Network or transient 5xx -> scheduled in queue, return queued status
            await _submissionStore!.scheduleRetry(
              submissionId,
              nextAttemptAt: now.add(const Duration(seconds: 10)),
              attemptCount: 1,
              errorCode: exception.code ?? 'network_error',
              errorMessage: exception.message,
            );
            return FeedbackSubmitResult(
              status: FeedbackSubmitStatus.queued,
              clientSubmissionId: submissionId,
            );
          }
        },
        (item) async {
          // Delivered successfully! Remove from queue and return sent result
          await _submissionStore!.remove(submissionId);
          return FeedbackSubmitResult(
            status: FeedbackSubmitStatus.sent,
            itemId: item.id,
            clientSubmissionId: submissionId,
            item: item,
          );
        },
      );
    } catch (e) {
      if (e is FeedbackOsException) rethrow;

      // Other unexpected exceptions treat as queued
      await _submissionStore!.scheduleRetry(
        submissionId,
        nextAttemptAt: now.add(const Duration(seconds: 10)),
        attemptCount: 1,
        errorCode: 'network_error',
        errorMessage: e.toString(),
      );
      return FeedbackSubmitResult(
        status: FeedbackSubmitStatus.queued,
        clientSubmissionId: submissionId,
      );
    }
  }

  /// Triggers an immediate transmission attempt for all due queued feedback items.
  ///
  /// Returns the number of feedback items successfully delivered.
  Future<int> flushQueue() async {
    _ensureInitialized();
    return _queueSyncEngine!.flushQueue();
  }

  /// Returns the number of items currently pending or awaiting retry in the queue.
  Future<int> getQueuedCount() async {
    _ensureInitialized();
    return _submissionStore!.getPendingCount(appScope: _publishableKey!);
  }

  /// Returns the number of permanently failed items in the queue.
  Future<int> getFailedCount() async {
    _ensureInitialized();
    return _submissionStore!.getFailedCount(appScope: _publishableKey!);
  }

  /// Discards all permanently failed feedback items from the queue.
  Future<void> clearFailedSubmissions() async {
    _ensureInitialized();
    await _submissionStore!.clearPermanentlyFailed(appScope: _publishableKey!);
  }

  /// Displays the interactive FeedbackOS submission dialog.
  ///
  /// Safe to call from any valid [BuildContext].
  /// Adheres to project Golden Rule 6: Bloc is instantiated outside the UI tree
  /// and injected cleanly via BlocProvider.
  Future<FeedbackSubmitResult?> showFeedback({
    required BuildContext context,
    FeedbackType initialType = FeedbackType.bug,
    List<ScreenshotAttachment> initialAttachments = const [],
    Future<ScreenshotAttachment?> Function()? onPickAttachment,
    FeedbackBloc? customBloc,
  }) async {
    _ensureInitialized();

    final bloc = customBloc ??
        FeedbackBloc(
          submitHandler: ({
            required type,
            required title,
            required description,
            category,
            attachments = const [],
          }) =>
              submitFeedback(
            type: type,
            title: title,
            description: description,
            category: category,
            attachments: attachments,
          ),
          getConfigUseCase: _getConfigUseCase,
          publishableKey: _publishableKey,
        );

    bloc.add(FeedbackFormStarted(
      initialType: initialType,
      initialAttachments: initialAttachments,
    ));

    return showDialog<FeedbackSubmitResult>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return BlocProvider<FeedbackBloc>.value(
          value: bloc,
          child: FeedbackFormDialog(
            onPickAttachment: onPickAttachment,
          ),
        );
      },
    );
  }

  /// Resets the SDK state and closes storage connections.
  Future<void> reset() async {
    if (_submissionStore != null) {
      try {
        await _submissionStore!.close();
      } catch (_) {}
    }

    _isInitialized = false;
    _publishableKey = null;
    _options = null;
    _deviceIdStore = null;
    _deviceInfoProvider = null;
    _submissionStore = null;
    _queueSyncEngine = null;
    _httpClient = null;
    _repository = null;
    _uploadRepository = null;
    _getConfigUseCase = null;
    _pingUseCase = null;
    _identifyUseCase = null;
    _submitFeedbackUseCase = null;
    _uploadScreenshotUseCase = null;
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
      UploadNotFoundFailure() => FeedbackOsUploadNotFoundException(
          failure.message,
          statusCode: failure.statusCode ?? 404,
        ),
      UploadInvalidFailure() => FeedbackOsUploadInvalidException(
          failure.message,
          statusCode: failure.statusCode ?? 422,
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
