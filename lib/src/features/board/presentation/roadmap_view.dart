import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/styles.dart';
import '../../../../core/theme/theme.dart';
import '../domain/entities/board_item.dart';
import '../state/board_bloc.dart';
import '../state/board_event.dart';
import '../state/board_state.dart';

enum RoadmapStage { planned, inProgress, shipped }

/// Grouped roadmap view displaying planned, in-progress, and shipped features.
class RoadmapView extends StatefulWidget {
  final VoidCallback? onBack;
  final VoidCallback? onOpenDashboard;
  final VoidCallback? onOpenBoard;
  final VoidCallback? onOpenMyFeedback;
  final bool isFromBoard;
  final bool isEmbedded;
  final void Function(String itemId)? onItemTap;

  const RoadmapView({
    super.key,
    this.onBack,
    this.onOpenDashboard,
    this.onOpenBoard,
    this.onOpenMyFeedback,
    this.isFromBoard = false,
    this.isEmbedded = false,
    this.onItemTap,
  });

  @override
  State<RoadmapView> createState() => _RoadmapViewState();
}

class _RoadmapViewState extends State<RoadmapView> {
  RoadmapStage _selectedStage = RoadmapStage.planned;

  @override
  Widget build(BuildContext context) {
    final theme = FeedbackOSTheme.of(context);
    final effectiveOpenBoard = widget.onOpenBoard ??
        (widget.isFromBoard ? () => Navigator.of(context).pop() : null);
    final effectiveOpenDashboard = widget.onOpenDashboard ??
        (widget.isFromBoard ? () => Navigator.of(context).pop() : null);

    final content = BlocBuilder<BoardBloc, BoardState>(
      builder: (context, state) {
        if (state.status == BoardStatus.loading && state.roadmap == null) {
          return Center(
            child: CircularProgressIndicator(color: theme.accentColor),
          );
        }

        if (state.status == BoardStatus.failure && state.roadmap == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: theme.errorColor),
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
        final plannedItems = roadmap?.planned ?? const [];
        final inProgressItems = roadmap?.inProgress ?? const [];
        final shippedItems = roadmap?.shipped ?? const [];

        final currentItems = switch (_selectedStage) {
          RoadmapStage.planned => plannedItems,
          RoadmapStage.inProgress => inProgressItems,
          RoadmapStage.shipped => shippedItems,
        };

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                children: [
                  _buildStageChip(
                    stage: RoadmapStage.planned,
                    label: 'Planned',
                    count: plannedItems.length,
                    theme: theme,
                  ),
                  const SizedBox(width: 6),
                  _buildStageChip(
                    stage: RoadmapStage.inProgress,
                    label: 'In progress',
                    count: inProgressItems.length,
                    theme: theme,
                  ),
                  const SizedBox(width: 6),
                  _buildStageChip(
                    stage: RoadmapStage.shipped,
                    label: 'Shipped',
                    count: shippedItems.length,
                    theme: theme,
                  ),
                ],
              ),
            ),
            Expanded(
              child: currentItems.isEmpty
                  ? Center(
                      child: Text(
                        'Nothing here yet.',
                        style: AppStyles.bodyMedium.copyWith(
                          color: theme.placeholderColor,
                          fontSize: 13,
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(14, 4, 14, 80),
                      itemCount: currentItems.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = currentItems[index];
                        return _buildRoadmapCard(context, item, theme);
                      },
                    ),
            ),
          ],
        );
      },
    );

    if (widget.isEmbedded) {
      return Container(
        color: theme.backgroundColor,
        child: content,
      );
    }

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Feedback',
          style: AppStyles.titleAppBar.copyWith(color: theme.titleColor),
        ),
        centerTitle: true,
        backgroundColor: theme.surfaceColor,
        elevation: 0.5,
        leading: widget.onBack != null
            ? IconButton(
                icon: Icon(Icons.arrow_back_ios_new_rounded,
                    color: theme.titleColor, size: 20),
                onPressed: widget.onBack,
              )
            : null,
        actions: [
          if (effectiveOpenBoard != null)
            IconButton(
              key: const Key('roadmap_open_board_button'),
              tooltip: 'Feedback Board',
              icon: Icon(Icons.forum_outlined, color: theme.titleColor),
              onPressed: effectiveOpenBoard,
            ),
          if (effectiveOpenDashboard != null)
            IconButton(
              key: const Key('roadmap_open_dashboard_button'),
              tooltip: 'Feedback Dashboard',
              icon: Icon(Icons.dashboard_outlined, color: theme.titleColor),
              onPressed: effectiveOpenDashboard,
            ),
          if (widget.onOpenMyFeedback != null)
            IconButton(
              key: const Key('roadmap_open_my_feedback_button'),
              tooltip: 'Track My Requests',
              icon: Icon(Icons.inbox_outlined, color: theme.titleColor),
              onPressed: widget.onOpenMyFeedback,
            ),
        ],
      ),
      body: content,
    );
  }

  Widget _buildStageChip({
    required RoadmapStage stage,
    required String label,
    required int count,
    required FeedbackOSTheme theme,
  }) {
    final isSelected = _selectedStage == stage;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedStage = stage;
        });
      },
      child: Container(
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? theme.accentSoftColor : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isSelected ? Colors.transparent : theme.borderMutedColor,
          ),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppStyles.chipLabel.copyWith(
                color: isSelected ? theme.accentColor : theme.mutedTextColor,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              '$count',
              style: AppStyles.meta.copyWith(
                color: isSelected
                    ? theme.accentColor
                    : theme.mutedTextColor.withAlpha(190),
                fontSize: 11.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoadmapCard(
    BuildContext context,
    BoardItem item,
    FeedbackOSTheme theme,
  ) {
    return GestureDetector(
      onTap: () => widget.onItemTap?.call(item.id),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.surfaceColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.borderColor),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: AppStyles.cardTitle.copyWith(
                      color: theme.titleColor,
                    ),
                  ),
                  if (item.description.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      item.description,
                      style: AppStyles.bodySmall.copyWith(
                        color: theme.mutedTextColor,
                        fontSize: 12.5,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.thumb_up_alt_outlined,
                  size: 13,
                  color: theme.mutedTextColor,
                ),
                const SizedBox(width: 4),
                Text(
                  '${item.voteCount}',
                  style: AppStyles.meta.copyWith(
                    color: theme.mutedTextColor,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
