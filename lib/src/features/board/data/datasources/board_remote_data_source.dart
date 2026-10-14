import 'package:dio/dio.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/feedback_os_dio_client.dart';
import '../models/board_page_model.dart';
import '../models/roadmap_model.dart';
import '../models/vote_result_model.dart';

abstract interface class BoardRemoteDataSource {
  Future<BoardPageModel> getBoard({
    String sort = 'top',
    String? cursor,
    int limit = 25,
    CancelToken? cancelToken,
  });

  Future<RoadmapModel> getRoadmap({
    CancelToken? cancelToken,
  });

  Future<VoteResultModel> voteItem({
    required String itemId,
    CancelToken? cancelToken,
  });

  Future<VoteResultModel> unvoteItem({
    required String itemId,
    CancelToken? cancelToken,
  });
}

class BoardRemoteDataSourceImpl implements BoardRemoteDataSource {
  final FeedbackOsHttpClient _client;

  BoardRemoteDataSourceImpl({
    required FeedbackOsHttpClient client,
  }) : _client = client;

  @override
  Future<BoardPageModel> getBoard({
    String sort = 'top',
    String? cursor,
    int limit = 25,
    CancelToken? cancelToken,
  }) async {
    final query = <String, dynamic>{
      'sort': sort,
      'limit': limit,
    };
    if (cursor != null && cursor.isNotEmpty) {
      query['cursor'] = cursor;
    }

    final response = await _client.get<Map<String, dynamic>>(
      ApiEndpoints.board,
      queryParameters: query,
      cancelToken: cancelToken,
    );

    return BoardPageModel.fromJson(response.data ?? {});
  }

  @override
  Future<RoadmapModel> getRoadmap({CancelToken? cancelToken}) async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiEndpoints.roadmap,
      cancelToken: cancelToken,
    );

    return RoadmapModel.fromJson(response.data ?? {});
  }

  @override
  Future<VoteResultModel> voteItem({
    required String itemId,
    CancelToken? cancelToken,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiEndpoints.itemVote(itemId),
      cancelToken: cancelToken,
    );

    return VoteResultModel.fromJson(response.data ?? {});
  }

  @override
  Future<VoteResultModel> unvoteItem({
    required String itemId,
    CancelToken? cancelToken,
  }) async {
    final response = await _client.delete<Map<String, dynamic>>(
      ApiEndpoints.itemVote(itemId),
      cancelToken: cancelToken,
    );

    return VoteResultModel.fromJson(response.data ?? {});
  }
}
