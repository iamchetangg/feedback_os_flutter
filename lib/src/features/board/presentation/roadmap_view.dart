import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/styles.dart';
import '../domain/entities/board_item.dart';
import '../state/board_bloc.dart';
import '../state/board_event.dart';
import '../state/board_state.dart';

/// Grouped roadmap view displaying planned, in-progress, and shipped features.
class RoadmapView extends StatelessWidget {
  final VoidCallback? onBack;

  const RoadmapView({super.key, this.onBack});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        appBar: AppBar(
          title: const Text('Product Roadmap', style: AppStyles.titleMedium),
          backgroundColor: Colors.white,
          elevation: 0.5,
          leading: onBack != null
              ? IconButton(
                  icon: const Icon(Icons.arrow_back, color: Color(0xFF374151)),
                  onPressed: onBack,
                )
              : null,
          bottom: const TabBar(
            labelColor: Color(0xFF4F46E5),
            unselectedLabelColor: Color(0xFF6B7280),
            indicatorColor: Color(0xFF4F46E5),
            tabs: [
              Tab(text: 'Planned'),
              Tab(text: 'In Progress'),
              Tab(text: 'Shipped'),
            ],
          ),
        ),
        body: BlocBuilder<BoardBloc, BoardState>(
          builder: (context, state) {
            if (state.status == BoardStatus.loading && state.roadmap == null) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state.status == BoardStatus.failure && state.roadmap == null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 48, color: Color(0xFFDC2626)),
                    const SizedBox(height: 12),
                    Text(state.errorMessage ?? 'Failed to load roadmap',
                        style: AppStyles.bodyMedium),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () =>
                          context.read<BoardBloc>().add(const RoadmapStarted()),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            final roadmap = state.roadmap;
            return TabBarView(
              children: [
                _buildList(context, roadmap?.planned ?? const []),
                _buildList(context, roadmap?.inProgress ?? const []),
                _buildList(context, roadmap?.shipped ?? const []),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context, List<BoardItem> items) {
    if (items.isEmpty) {
      return const Center(
        child: Text('No items in this stage.', style: AppStyles.bodyMedium),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = items[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(item.title, style: AppStyles.titleSmall),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.thumb_up_alt_outlined,
                          size: 14, color: Color(0xFF6B7280)),
                      const SizedBox(width: 4),
                      Text('${item.voteCount}', style: AppStyles.labelSmall),
                    ],
                  ),
                ],
              ),
              if (item.description.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  item.description,
                  style: AppStyles.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (item.category != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(item.category!, style: AppStyles.labelSmall),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
