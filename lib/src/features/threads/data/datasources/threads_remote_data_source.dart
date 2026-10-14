import 'package:dio/dio.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/feedback_os_dio_client.dart';
import '../models/my_feedback_item_model.dart';
import '../models/thread_detail_model.dart';
import '../models/thread_reply_model.dart';
import '../models/unread_count_model.dart';

abstract interface class ThreadsRemoteDataSource {
  Future<UnreadCountModel> getUnreadCount({CancelToken? cancelToken});

  Future<List<MyFeedbackItemModel>> getMyItems({CancelToken? cancelToken});

  Future<ThreadDetailModel> getThreadDetail({
    required String itemId,
    CancelToken? cancelToken,
  });

  Future<ThreadReplyModel> sendReply({
    required String itemId,
    required String message,
    CancelToken? cancelToken,
  });

  Future<void> markThreadRead({
    required String itemId,
    CancelToken? cancelToken,
  });
}

class ThreadsRemoteDataSourceImpl implements ThreadsRemoteDataSource {
  final FeedbackOsHttpClient _client;

  ThreadsRemoteDataSourceImpl({
    required FeedbackOsHttpClient client,
  }) : _client = client;

  @override
  Future<UnreadCountModel> getUnreadCount({CancelToken? cancelToken}) async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiEndpoints.meUnread,
      cancelToken: cancelToken,
    );

    return UnreadCountModel.fromJson(response.data ?? {});
  }

  @override
  Future<List<MyFeedbackItemModel>> getMyItems(
      {CancelToken? cancelToken}) async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiEndpoints.meItems,
      cancelToken: cancelToken,
    );

    final rawList = response.data?['data'] as List<dynamic>? ?? const [];
    return rawList
        .map((item) =>
            MyFeedbackItemModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<ThreadDetailModel> getThreadDetail({
    required String itemId,
    CancelToken? cancelToken,
  }) async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiEndpoints.meItemDetail(itemId),
      cancelToken: cancelToken,
    );

    return ThreadDetailModel.fromJson(response.data ?? {});
  }

  @override
  Future<ThreadReplyModel> sendReply({
    required String itemId,
    required String message,
    CancelToken? cancelToken,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiEndpoints.meItemReplies(itemId),
      data: {'body': message},
      cancelToken: cancelToken,
    );

    return ThreadReplyModel.fromJson(response.data ?? {});
  }

  @override
  Future<void> markThreadRead({
    required String itemId,
    CancelToken? cancelToken,
  }) async {
    await _client.post<dynamic>(
      ApiEndpoints.meItemRead(itemId),
      cancelToken: cancelToken,
    );
  }
}
