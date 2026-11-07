import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/theme/styles.dart';
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

  const BoardView({
    super.key,
    this.onBack,
    this.onOpenDashboard,
    this.onOpenRoadmap,
    this.isFromRoadmap = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FeedbackOSTheme.of(context);
    final effectiveOpenRoadmap = onOpenRoadmap ??
        (isFromRoadmap ? () => Navigator.of(context).pop() : null);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Community Board',
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
      body: BlocConsumer<BoardBloc, BoardState>(
        listener: (context, state) {
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.errorMessage!,
                  style: AppStyles.labelMedium
                      .copyWith(color: theme.onPrimaryColor),
                ),
                backgroundColor: theme.errorColor,
              ),
            );
          }
        },
        builder: (context, state) {
          return Column(
            children: [
              _buildSortBar(context, state),
              Expanded(child: _buildContent(context, state)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSortBar(BuildContext context, BoardState state) {
    final theme = FeedbackOSTheme.of(context);

    return Container(
      color: theme.surfaceColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(
            'Sort by:',
            style: AppStyles.bodySmall.copyWith(color: theme.mutedTextColor),
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text('Top'),
            selected: state.sort == 'top',
            selectedColor: theme.primaryLightColor,
            side: BorderSide(color: theme.borderColor),
            labelStyle: state.sort == 'top'
                ? AppStyles.labelSmall.copyWith(
                    color: theme.primaryColor,
                    fontWeight: FontWeight.w600,
                  )
                : AppStyles.labelSmall.copyWith(color: theme.mutedTextColor),
            onSelected: (selected) {
              if (selected) {
                context.read<BoardBloc>().add(const BoardSortChanged('top'));
              }
            },
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text('Newest'),
            selected: state.sort == 'new',
            selectedColor: theme.primaryLightColor,
            side: BorderSide(color: theme.borderColor),
            labelStyle: state.sort == 'new'
                ? AppStyles.labelSmall.copyWith(
                    color: theme.primaryColor,
                    fontWeight: FontWeight.w600,
                  )
                : AppStyles.labelSmall.copyWith(color: theme.mutedTextColor),
            onSelected: (selected) {
              if (selected) {
                context.read<BoardBloc>().add(const BoardSortChanged('new'));
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, BoardState state) {
    final theme = FeedbackOSTheme.of(context);

    if (state.status == BoardStatus.loading && state.items.isEmpty) {
      return Center(
        child: CircularProgressIndicator(color: theme.primaryColor),
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
      padding: const EdgeInsets.all(16),
      itemCount: state.items.length + (state.hasMore ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index >= state.items.length) {
          return Center(
            child: TextButton.icon(
              onPressed: () =>
                  context.read<BoardBloc>().add(const BoardNextPageRequested()),
              icon: Icon(Icons.expand_more, color: theme.primaryColor),
              label: Text(
                'Load More',
                style:
                    AppStyles.labelMedium.copyWith(color: theme.primaryColor),
              ),
            ),
          );
        }

        final item = state.items[index];
        return _buildItemCard(context, item);
      },
    );
  }

  Widget _buildItemCard(BuildContext context, BoardItem item) {
    final theme = FeedbackOSTheme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.borderColor),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildVoteButton(context, item),
          const SizedBox(width: 14),
          Expanded(
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
                    _buildStatusChip(context, item.status),
                  ],
                ),
                if (item.description.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    item.description,
                    style: AppStyles.bodySmall
                        .copyWith(color: theme.secondaryTextColor),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (item.category != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
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
                      const SizedBox(width: 8),
                    ],
                    if (item.isMine)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.primaryLightColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'You submitted',
                          style: AppStyles.labelSmall
                              .copyWith(color: theme.primaryColor),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoteButton(BuildContext context, BoardItem item) {
    final theme = FeedbackOSTheme.of(context);
    final hasVoted = item.hasVoted;

    return InkWell(
      onTap: () {
        context.read<BoardBloc>().add(BoardItemVoteToggled(item.id));
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 48,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: hasVoted ? theme.primaryLightColor : theme.backgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: hasVoted ? theme.primaryColor : theme.borderColor,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.keyboard_arrow_up,
              size: 20,
              color: hasVoted ? theme.primaryColor : theme.mutedTextColor,
            ),
            Text(
              '${item.voteCount}',
              style: AppStyles.labelSmall.copyWith(
                fontWeight: FontWeight.w700,
                color: hasVoted ? theme.primaryColor : theme.titleColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context, String status) {
    final theme = FeedbackOSTheme.of(context);
    final bg = theme.statusBackgroundColor(status);
    final fg = theme.statusForegroundColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.replaceAll('_', ' '),
        style: AppStyles.labelSmall
            .copyWith(color: fg, fontWeight: FontWeight.w600),
      ),
    );
  }
}
