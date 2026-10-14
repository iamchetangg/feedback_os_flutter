import 'package:equatable/equatable.dart';
import 'thread_event.dart';
import 'thread_reply.dart';

/// Represents complete details of a feedback thread including conversation replies and history events.
class ThreadDetail extends Equatable {
  final String id;
  final String title;
  final String description;
  final String type;
  final String? category;
  final String status;
  final DateTime createdAt;
  final List<ThreadReply> replies;
  final List<ThreadEvent> events;

  const ThreadDetail({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    this.category,
    required this.status,
    required this.createdAt,
    this.replies = const [],
    this.events = const [],
  });

  ThreadDetail copyWith({
    String? id,
    String? title,
    String? description,
    String? type,
    String? category,
    String? status,
    DateTime? createdAt,
    List<ThreadReply>? replies,
    List<ThreadEvent>? events,
  }) {
    return ThreadDetail(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      category: category ?? this.category,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      replies: replies ?? this.replies,
      events: events ?? this.events,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        type,
        category,
        status,
        createdAt,
        replies,
        events,
      ];
}
