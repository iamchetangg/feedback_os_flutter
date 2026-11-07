import "package:equatable/equatable.dart";

/// Represents a reply in a feedback discussion thread.
class ThreadReply extends Equatable {
  final String id;
  final String body;
  final String authorType;
  final String? authorName;
  final DateTime createdAt;

  const ThreadReply({
    required this.id,
    required this.body,
    required this.authorType,
    this.authorName,
    required this.createdAt,
  });

  bool get isAdmin =>
      authorType.toLowerCase() == "admin" ||
      authorType.toLowerCase() == "developer";
  bool get isUser =>
      authorType.toLowerCase() == "user" || authorType.toLowerCase() == "me";

  @override
  List<Object?> get props => [id, body, authorType, authorName, createdAt];
}
