import 'package:dio/dio.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/feedback_os_dio_client.dart';
import '../models/sdk_config_model.dart';
import '../models/sdk_ping_model.dart';

abstract interface class FeedbackRemoteDataSource {
  Future<SdkConfigModel> getConfig(String publishableKey,
      {CancelToken? cancelToken});
  Future<SdkPingModel> ping({CancelToken? cancelToken});
  Future<void> identify(String? externalUserId, {CancelToken? cancelToken});
  Future<Map<String, dynamic>> submitFeedback(
    Map<String, dynamic> payload, {
    CancelToken? cancelToken,
  });
}

class FeedbackRemoteDataSourceImpl implements FeedbackRemoteDataSource {
  final FeedbackOsHttpClient _client;

  FeedbackRemoteDataSourceImpl({required FeedbackOsHttpClient client})
      : _client = client;

  @override
  Future<SdkConfigModel> getConfig(
    String publishableKey, {
    CancelToken? cancelToken,
  }) async {
    // Config route GET /v1/sdk/config/{key} has key in path, public/cacheable
    final response = await _client.get<Map<String, dynamic>>(
      ApiEndpoints.config(publishableKey),
      cancelToken: cancelToken,
      includeAuthHeaders: false, // Key is in path
    );

    return SdkConfigModel.fromJson(response.data ?? {});
  }

  @override
  Future<SdkPingModel> ping({CancelToken? cancelToken}) async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiEndpoints.ping,
      cancelToken: cancelToken,
      includeAuthHeaders: true,
    );

    return SdkPingModel.fromJson(response.data ?? {});
  }

  @override
  Future<void> identify(
    String? externalUserId, {
    CancelToken? cancelToken,
  }) async {
    await _client.post<void>(
      ApiEndpoints.identify,
      data: {'external_user_id': externalUserId},
      cancelToken: cancelToken,
      includeAuthHeaders: true,
    );
  }

  @override
  Future<Map<String, dynamic>> submitFeedback(
    Map<String, dynamic> payload, {
    CancelToken? cancelToken,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiEndpoints.feedback,
      data: payload,
      cancelToken: cancelToken,
      includeAuthHeaders: true,
    );

    return response.data ?? {};
  }
}
