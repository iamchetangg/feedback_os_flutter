import '../../domain/entities/unread_count.dart';

class UnreadCountModel extends UnreadCount {
  const UnreadCountModel({required super.count});

  factory UnreadCountModel.fromJson(Map<String, dynamic> json) {
    return UnreadCountModel(
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'count': count,
    };
  }
}
