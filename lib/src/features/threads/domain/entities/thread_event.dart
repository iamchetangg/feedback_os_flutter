import 'package:equatable/equatable.dart';

/// Represents a system or timeline event in a feedback thread (e.g. status changed).
class ThreadEvent extends Equatable {
  final String id;
  final String type;
  final String? oldStatus;
  final String? newStatus;
  final DateTime createdAt;

  const ThreadEvent({
    required this.id,
    required this.type,
    this.oldStatus,
    this.newStatus,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, type, oldStatus, newStatus, createdAt];
}
