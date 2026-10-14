import 'package:dio/dio.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/feedback_os_dio_client.dart';
import '../models/create_upload_request_model.dart';
import '../models/upload_reservation_model.dart';

abstract interface class UploadRemoteDataSource {
  Future<UploadReservationModel> reserveUpload({
    required String contentType,
    required int byteSize,
    CancelToken? cancelToken,
  });
}

class UploadRemoteDataSourceImpl implements UploadRemoteDataSource {
  final FeedbackOsHttpClient _client;

  UploadRemoteDataSourceImpl({required FeedbackOsHttpClient client})
      : _client = client;

  @override
  Future<UploadReservationModel> reserveUpload({
    required String contentType,
    required int byteSize,
    CancelToken? cancelToken,
  }) async {
    final body = CreateUploadRequestModel(
      contentType: contentType,
      byteSize: byteSize,
    );

    final response = await _client.post<Map<String, dynamic>>(
      ApiEndpoints.uploads,
      data: body.toJson(),
      cancelToken: cancelToken,
      includeAuthHeaders: true,
    );

    return UploadReservationModel.fromJson(response.data ?? {});
  }
}
