import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/styles.dart';
import '../../../../core/theme/theme.dart';
import '../domain/entities/my_feedback_item.dart';
import '../state/threads_bloc.dart';
import '../state/threads_event.dart';
import '../state/threads_state.dart';

/// Screen displaying the list of feedback submitted by the current user/device.
class MyFeedbackListView extends StatelessWidget {
  final void Function(String itemId)? onItemTap;
  final VoidCallback? onBack;
  final bool isEmbedded;

  const MyFeedbackListView({
    super.key,
    this.onItemTap,
    this.onBack,
    this.isEmbedded = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FeedbackOSTheme.of(context);

    final content = BlocConsumer<ThreadsBloc, ThreadsState>(
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
        if (state.status == ThreadsStatus.loading && state.items.isEmpty) {
          return Center(
            child: CircularProgressIndicator(color: theme.accentColor),
          );
        }

        if (state.status == ThreadsStatus.failure && state.items.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: theme.errorColor),
                const SizedBox(height: 12),
                Text(
                  state.errorMessage ?? 'Failed to load your feedback',
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
                      context.read<ThreadsBloc>().add(const MyItemsStarted()),
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

        if (state.items.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_outlined,
                    size: 56, color: theme.placeholderColor),
                const SizedBox(height: 12),
                Text(
                  'You have not submitted any feedback yet.',
                  style: AppStyles.bodyMedium
                      .copyWith(color: theme.mutedTextColor),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 80),
          itemCount: state.items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final item = state.items[index];
            return _buildItemCard(context, item, theme);
          },
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
      ),
      body: content,
    );
  }

  Widget _buildItemCard(
    BuildContext context,
    MyFeedbackItem item,
    FeedbackOSTheme theme,
  ) {
    final subtitle = (item.latestReplyPreview != null &&
            item.latestReplyPreview!.isNotEmpty)
        ? item.latestReplyPreview!
        : (item.description != null && item.description!.isNotEmpty)
            ? item.description!
            : (item.category ?? item.type);

    return GestureDetector(
      onTap: () => onItemTap?.call(item.id),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.surfaceColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: item.hasUnread ? theme.accentColor : theme.borderColor,
            width: item.hasUnread ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
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
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: AppStyles.bodySmall.copyWith(
                      color: theme.mutedTextColor,
                      fontSize: 12.5,
                      height: 1.4,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 9),
                  if (item.hasUnread) ...[
                    Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: theme.accentColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'New reply',
                          style: AppStyles.meta.copyWith(
                            color: theme.accentColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          ' · ',
                          style: AppStyles.meta
                              .copyWith(color: theme.placeholderColor),
                        ),
                        Text(
                          _formatTimeAgo(
                              item.lastActivityAt ?? item.createdAt),
                          style: AppStyles.meta
                              .copyWith(color: theme.placeholderColor),
                        ),
                      ],
                    ),
                  ] else ...[
                    Row(
                      children: [
                        Text(
                          'Sent ${_formatTimeAgo(item.createdAt)}',
                          style: AppStyles.meta
                              .copyWith(color: theme.placeholderColor),
                        ),
                        Text(
                          ' · ',
                          style: AppStyles.meta
                              .copyWith(color: theme.placeholderColor),
                        ),
                        Text(
                          item.replyCount == 0
                              ? 'No replies yet'
                              : item.replyCount == 1
                                  ? '1 reply'
                                  : '${item.replyCount} replies',
                          style: AppStyles.meta
                              .copyWith(color: theme.placeholderColor),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              color: theme.placeholderColor,
              size: 20,
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

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.month}/${dateTime.day}';
    }
  }
}
