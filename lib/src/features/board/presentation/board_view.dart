import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/styles.dart';
import '../../../../core/theme/theme.dart';
import '../domain/entities/board_item.dart';
import '../state/board_bloc.dart';
import '../state/board_event.dart';
import '../state/board_state.dart';

/// Community feedback board view with sorting, pagination, and upvoting.
class BoardView extends StatelessWidget {
  final VoidCallback? onBack;
  final VoidCallback? onOpenDashboard;
  final VoidCallback? onOpenRoadmap;
  final bool isFromRoadmap;
  final bool isEmbedded;
  final void Function(String itemId)? onItemTap;

  const BoardView({
    super.key,
    this.onBack,
    this.onOpenDashboard,
    this.onOpenRoadmap,
    this.isFromRoadmap = false,
    this.isEmbedded = false,
    this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FeedbackOSTheme.of(context);
    final effectiveOpenRoadmap = onOpenRoadmap ??
        (isFromRoadmap ? () => Navigator.of(context).pop() : null);

    final content = BlocConsumer<BoardBloc, BoardState>(
      listener: (context, state) {
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.errorMessage!,
                style:
                    AppStyles.labelMedium.copyWith(color: theme.onPrimaryColor),
              ),
              backgroundColor: theme.errorColor,
            ),
          );
        }
      },
      builder: (context, state) {
        return Column(
          children: [
            _buildSortBar(context, state, theme),
            Expanded(child: _buildContent(context, state, theme)),
          ],
        );
      },
    );

    if (isEmbedded) {
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
        leading: onBack != null
            ? IconButton(
                icon: Icon(Icons.arrow_back_ios_new_rounded,
                    color: theme.titleColor, size: 20),
                onPressed: onBack,
              )
            : null,
        actions: [
          if (effectiveOpenRoadmap != null)
            IconButton(
              key: const Key('board_open_roadmap_button'),
              tooltip: 'Product Roadmap',
              icon: Icon(Icons.map_outlined, color: theme.titleColor),
              onPressed: effectiveOpenRoadmap,
            ),
          if (onOpenDashboard != null)
            IconButton(
              key: const Key('board_open_dashboard_button'),
              tooltip: 'Track My Requests',
              icon: Icon(Icons.inbox_outlined, color: theme.titleColor),
              onPressed: onOpenDashboard,
            ),
        ],
      ),
      body: content,
    );
  }

  Widget _buildSortBar(
    BuildContext context,
    BoardState state,
    FeedbackOSTheme theme,
  ) {
    final isTop = state.sort == 'top';
    final isNew = state.sort == 'new';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          Text(
            'Sort',
            style: AppStyles.bodySmall.copyWith(
              color: theme.mutedTextColor,
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          _buildChip(
            label: 'Top',
            isSelected: isTop,
            theme: theme,
            onTap: () {
              if (!isTop) {
                context.read<BoardBloc>().add(const BoardSortChanged('top'));
              }
            },
          ),
          const SizedBox(width: 6),
          _buildChip(
            label: 'Newest',
            isSelected: isNew,
            theme: theme,
            onTap: () {
              if (!isNew) {
                context.read<BoardBloc>().add(const BoardSortChanged('new'));
              }
            },
          ),
          const Spacer(),
          Text(
            '${state.items.length} requests',
            style: AppStyles.meta.copyWith(
              color: theme.placeholderColor,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip({
    required String label,
    required bool isSelected,
    required FeedbackOSTheme theme,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
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
        child: Text(
          label,
          style: AppStyles.chipLabel.copyWith(
            color: isSelected ? theme.accentColor : theme.mutedTextColor,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    BoardState state,
    FeedbackOSTheme theme,
  ) {
    if (state.status == BoardStatus.loading && state.items.isEmpty) {
      return Center(
        child: CircularProgressIndicator(color: theme.accentColor),
      );
    }

    if (state.status == BoardStatus.failure && state.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.errorColor),
            const SizedBox(height: 12),
            Text(
              state.errorMessage ?? 'Failed to load community board',
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
                  context.read<BoardBloc>().add(BoardStarted(sort: state.sort)),
              child: Text(
                'Retry',
                style:
                    AppStyles.labelMedium.copyWith(color: theme.onPrimaryColor),
              ),
            ),
          ],
        ),
      );
    }

    if (state.items.isEmpty) {
      return Center(
        child: Text(
          'No feature requests yet.',
          style: AppStyles.bodyMedium.copyWith(color: theme.mutedTextColor),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 80),
      itemCount: state.items.length + (state.hasMore ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        if (index >= state.items.length) {
          return Center(
            child: TextButton.icon(
              onPressed: () =>
                  context.read<BoardBloc>().add(const BoardNextPageRequested()),
              icon: Icon(Icons.expand_more, color: theme.accentColor),
              label: Text(
                'Load More',
                style:
                    AppStyles.labelMedium.copyWith(color: theme.accentColor),
              ),
            ),
          );
        }

        final item = state.items[index];
        return _buildItemCard(context, item, theme);
      },
    );
  }

  Widget _buildItemCard(
    BuildContext context,
    BoardItem item,
    FeedbackOSTheme theme,
  ) {
    final replyLabel =
        item.replyCount == 1 ? '1 reply' : '${item.replyCount} replies';

    return GestureDetector(
      onTap: () => onItemTap?.call(item.id),
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
            _buildVoteButton(context, item, theme),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: AppStyles.cardTitle
                              .copyWith(color: theme.titleColor),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildStatusChip(context, item.status, theme),
                    ],
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
                  const SizedBox(height: 9),
                  Row(
                    children: [
                      if (item.isMine) ...[
                        Text(
                          'You submitted',
                          style: AppStyles.meta.copyWith(
                            color: theme.accentColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          ' · ',
                          style: AppStyles.meta
                              .copyWith(color: theme.placeholderColor),
                        ),
                      ],
                      Text(
                        replyLabel,
                        style: AppStyles.meta
                            .copyWith(color: theme.placeholderColor),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoteButton(
    BuildContext context,
    BoardItem item,
    FeedbackOSTheme theme,
  ) {
    final hasVoted = item.hasVoted;

    return GestureDetector(
      onTap: () {
        context.read<BoardBloc>().add(BoardItemVoteToggled(item.id));
      },
      child: Container(
        width: 42,
        height: 50,
        decoration: BoxDecoration(
          color: hasVoted ? theme.accentSoftColor : theme.cardSecondaryColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: hasVoted ? theme.accentColor : theme.borderMutedColor,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.keyboard_arrow_up_rounded,
              size: 16,
              color: hasVoted ? theme.accentColor : theme.titleColor,
            ),
            Text(
              '${item.voteCount}',
              style: AppStyles.cardTitle.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: hasVoted ? theme.accentColor : theme.titleColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(
    BuildContext context,
    String status,
    FeedbackOSTheme theme,
  ) {
    final bg = theme.statusBackgroundColor(status);
    final fg = theme.statusForegroundColor(status);
    final dotColor = theme.statusColor(status);

    return Container(
      height: 20,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            _formatStatusLabel(status),
            style: AppStyles.pillLabel.copyWith(
              color: fg,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatStatusLabel(String status) {
    final normalized = status.toLowerCase().replaceAll('-', '_').trim();
    return switch (normalized) {
      'in_progress' || 'in progress' => 'In progress',
      'planned' => 'Planned',
      'shipped' || 'completed' => 'Shipped',
      'open' || 'under_review' => 'Open',
      'closed' || 'declined' => 'Closed',
      _ => status.replaceAll('_', ' '),
    };
  }
}
