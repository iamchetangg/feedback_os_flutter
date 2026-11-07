import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/theme/styles.dart';
import '../domain/entities/board_item.dart';
import '../state/board_bloc.dart';
import '../state/board_event.dart';
import '../state/board_state.dart';

/// Grouped roadmap view displaying planned, in-progress, and shipped features.
class RoadmapView extends StatelessWidget {
  final VoidCallback? onBack;
  final VoidCallback? onOpenDashboard;
  final VoidCallback? onOpenBoard;
  final VoidCallback? onOpenMyFeedback;

  const RoadmapView({
    super.key,
    this.onBack,
    this.onOpenDashboard,
    this.onOpenBoard,
    this.onOpenMyFeedback,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FeedbackOSTheme.of(context);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: theme.backgroundColor,
        appBar: AppBar(
          title: Text(
            'Product Roadmap',
            style: AppStyles.titleMedium.copyWith(color: theme.titleColor),
          ),
          backgroundColor: theme.surfaceColor,
          elevation: 0.5,
          leading: onBack != null
              ? IconButton(
                  icon: Icon(Icons.arrow_back, color: theme.titleColor),
                  onPressed: onBack,
                )
              : null,
          actions: [
            if (onOpenBoard != null)
              IconButton(
                key: const Key('roadmap_open_board_button'),
                tooltip: 'Feedback Board',
                icon: Icon(Icons.forum_outlined, color: theme.titleColor),
                onPressed: onOpenBoard,
              ),
            if (onOpenDashboard != null)
              IconButton(
                key: const Key('roadmap_open_dashboard_button'),
                tooltip: 'Feedback Dashboard',
                icon: Icon(Icons.dashboard_outlined, color: theme.titleColor),
                onPressed: onOpenDashboard,
              ),
            if (onOpenMyFeedback != null)
              IconButton(
                key: const Key('roadmap_open_my_feedback_button'),
                tooltip: 'Track My Requests',
                icon: Icon(Icons.inbox_outlined, color: theme.titleColor),
                onPressed: onOpenMyFeedback,
              ),
          ],
          bottom: TabBar(
            labelColor: theme.primaryColor,
            unselectedLabelColor: theme.mutedTextColor,
            indicatorColor: theme.primaryColor,
            tabs: const [
              Tab(text: 'Planned'),
              Tab(text: 'In Progress'),
              Tab(text: 'Shipped'),
            ],
          ),
        ),
        body: BlocBuilder<BoardBloc, BoardState>(
          builder: (context, state) {
            if (state.status == BoardStatus.loading && state.roadmap == null) {
              return Center(
                child: CircularProgressIndicator(color: theme.primaryColor),
              );
            }

            if (state.status == BoardStatus.failure && state.roadmap == null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline,
                        size: 48, color: theme.errorColor),
                    const SizedBox(height: 12),
                    Text(
                      state.errorMessage ?? 'Failed to load roadmap',
                      style: AppStyles.bodyMedium
                          .copyWith(color: theme.secondaryTextColor),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.buttonColor,
                        foregroundColor: theme.onPrimaryColor,
                      ),
                      onPressed: () =>
                          context.read<BoardBloc>().add(const RoadmapStarted()),
                      child: Text(
                        'Retry',
                        style: AppStyles.labelMedium
                            .copyWith(color: theme.onPrimaryColor),
                      ),
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
    final theme = FeedbackOSTheme.of(context);

    if (items.isEmpty) {
      return Center(
        child: Text(
          'No items in this stage.',
          style: AppStyles.bodyMedium.copyWith(color: theme.mutedTextColor),
        ),
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
            color: theme.surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.title,
                      style: AppStyles.titleSmall
                          .copyWith(color: theme.titleColor),
                    ),
                  ),
                  Row(
                    children: [
                      Icon(Icons.thumb_up_alt_outlined,
                          size: 14, color: theme.mutedTextColor),
                      const SizedBox(width: 4),
                      Text(
                        '${item.voteCount}',
                        style: AppStyles.labelSmall
                            .copyWith(color: theme.mutedTextColor),
                      ),
                    ],
                  ),
                ],
              ),
              if (item.description.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  item.description,
                  style: AppStyles.bodySmall
                      .copyWith(color: theme.secondaryTextColor),
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
                    color: theme.secondaryBackgroundColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    item.category!,
                    style: AppStyles.labelSmall
                        .copyWith(color: theme.secondaryTextColor),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
