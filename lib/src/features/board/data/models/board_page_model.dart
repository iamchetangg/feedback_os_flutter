import '../../domain/entities/board_page.dart';
import 'board_item_model.dart';

class BoardPageModel extends BoardPage {
  const BoardPageModel({
    required super.items,
    super.nextCursor,
  });

  factory BoardPageModel.fromJson(Map<String, dynamic> json) {
    final rawList = json['data'] as List<dynamic>? ?? const [];
    final items = rawList
        .map((item) => BoardItemModel.fromJson(item as Map<String, dynamic>))
        .toList();
    final nextCursor = json['next_cursor'] as String?;
    return BoardPageModel(
      items: items,
      nextCursor: nextCursor,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data': items
          .map((item) => BoardItemModel.fromEntity(item).toJson())
          .toList(),
      if (nextCursor != null) 'next_cursor': nextCursor,
    };
  }
}
