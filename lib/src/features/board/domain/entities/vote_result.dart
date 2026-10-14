import 'package:equatable/equatable.dart';

/// Represents the updated vote state for a feedback item.
class VoteResult extends Equatable {
  final int voteCount;
  final bool hasVoted;

  const VoteResult({
    required this.voteCount,
    required this.hasVoted,
  });

  @override
  List<Object?> get props => [voteCount, hasVoted];
}
