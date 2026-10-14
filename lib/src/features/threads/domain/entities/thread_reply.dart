import 'package:equatable/equatable.dart';

/// Represents a reply in a feedback discussion thread.
class ThreadReply extends Equatable {
  final String id;
  final String body;
  final String authorType;
  final DateTime createdAt;

  const ThreadReply({
    required this.id,
    required this.body,
    required this.authorType,
    required this.createdAt,
  });

  bool get isAdmin => authorType.toLowerCase() == 'admin';
  bool get isUser => authorType.toLowerCase() == 'user';

  @override
  List<Object?> get props => [id, body, authorType, createdAt];
}
