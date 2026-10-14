import 'package:equatable/equatable.dart';

/// Represents count of unread replies or status changes for the current user.
class UnreadCount extends Equatable {
  final int count;

  const UnreadCount({required this.count});

  @override
  List<Object?> get props => [count];
}
