import '../../domain/entities/roadmap.dart';
import 'board_item_model.dart';

class RoadmapModel extends Roadmap {
  const RoadmapModel({
    required super.planned,
    required super.inProgress,
    required super.shipped,
  });

  factory RoadmapModel.fromJson(Map<String, dynamic> json) {
    List<BoardItemModel> parseList(dynamic raw) {
      if (raw is List) {
        return raw
            .map(
                (item) => BoardItemModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return const [];
    }

    return RoadmapModel(
      planned: parseList(json['planned']),
      inProgress: parseList(json['in_progress']),
      shipped: parseList(json['shipped']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'planned': planned
          .map((item) => BoardItemModel.fromEntity(item).toJson())
          .toList(),
      'in_progress': inProgress
          .map((item) => BoardItemModel.fromEntity(item).toJson())
          .toList(),
      'shipped': shipped
          .map((item) => BoardItemModel.fromEntity(item).toJson())
          .toList(),
    };
  }
}
