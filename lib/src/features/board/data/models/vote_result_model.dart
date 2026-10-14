import '../../domain/entities/vote_result.dart';

class VoteResultModel extends VoteResult {
  const VoteResultModel({
    required super.voteCount,
    required super.hasVoted,
  });

  factory VoteResultModel.fromJson(Map<String, dynamic> json) {
    return VoteResultModel(
      voteCount: (json['vote_count'] as num?)?.toInt() ?? 0,
      hasVoted: (json['has_voted'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vote_count': voteCount,
      'has_voted': hasVoted,
    };
  }
}
