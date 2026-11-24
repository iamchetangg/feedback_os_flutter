import 'dart:convert';
import '../../domain/entities/feedback_os_event.dart';

/// Parses a raw realtime text frame into a [FeedbackOSEvent].
///
/// Returns `null` for control frames (`hello`, `pong`), unknown event types
/// (forward compatibility) and malformed payloads. Never throws.
FeedbackOSEvent? parseRealtimeFrame(Object? frame) {
  if (frame is! String) return null;
  final text = frame.trim();
  if (text.isEmpty || !text.startsWith('{')) return null;

  final Object? decoded;
  try {
    decoded = jsonDecode(text);
  } catch (_) {
    return null;
  }
  if (decoded is! Map<String, dynamic>) return null;

  final itemId = decoded['item_id'];
  final createdAt = _parseDate(decoded['created_at']);

  switch (decoded['type']) {
    case 'reply.created':
      final replyId = decoded['reply_id'];
      if (itemId is! String || replyId is! String) return null;
      final author = decoded['author_name'];
      final preview = decoded['preview'];
      return ReplyReceived(
        itemId: itemId,
        replyId: replyId,
        authorName: author is String && author.isNotEmpty ? author : null,
        preview: preview is String ? preview : '',
        createdAt: createdAt,
      );
    case 'item.status_changed':
      final toStatus = decoded['to_status'];
      if (itemId is! String || toStatus is! String) return null;
      final fromStatus = decoded['from_status'];
      return StatusChanged(
        itemId: itemId,
        fromStatus: fromStatus is String ? fromStatus : null,
        toStatus: toStatus,
        createdAt: createdAt,
      );
    default:
      // `hello` and any future/unknown types are ignored.
      return null;
  }
}

DateTime _parseDate(Object? value) {
  if (value is String) {
    final parsed = DateTime.tryParse(value);
    if (parsed != null) return parsed.toUtc();
  }
  return DateTime.now().toUtc();
}
