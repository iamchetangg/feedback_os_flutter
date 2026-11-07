import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/theme/styles.dart';
import '../domain/entities/my_feedback_item.dart';
import '../state/threads_bloc.dart';
import '../state/threads_event.dart';
import '../state/threads_state.dart';

/// Screen displaying the list of feedback submitted by the current user/device.
class MyFeedbackListView extends StatelessWidget {
  final void Function(String itemId)? onItemTap;
  final VoidCallback? onBack;

  const MyFeedbackListView({
    super.key,
    this.onItemTap,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FeedbackOSTheme.of(context);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'My Feedback',
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
      ),
      body: BlocConsumer<ThreadsBloc, ThreadsState>(
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
          if (state.status == ThreadsStatus.loading && state.items.isEmpty) {
            return Center(
              child: CircularProgressIndicator(color: theme.primaryColor),
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
            padding: const EdgeInsets.all(16),
            itemCount: state.items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = state.items[index];
              return _buildItemTile(context, item);
            },
          );
        },
      ),
    );
  }

  Widget _buildItemTile(BuildContext context, MyFeedbackItem item) {
    final theme = FeedbackOSTheme.of(context);
    final isBug = item.type.toLowerCase() == 'bug';

    return InkWell(
      onTap: () => onItemTap?.call(item.id),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: item.hasUnread ? theme.primaryColor : theme.borderColor,
            width: item.hasUnread ? 1.5 : 1.0,
          ),
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
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isBug ? theme.errorColor : theme.primaryColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isBug ? Icons.bug_report_outlined : Icons.lightbulb_outline,
                size: 20,
                color: isBug ? theme.onPrimaryColor : theme.onPrimaryColor,
              ),
            ),
            const SizedBox(width: 12),
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
                      if (item.hasUnread) ...[
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: theme.primaryColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      _buildStatusChip(context, item.status),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (item.category != null) ...[
                        Text(
                          item.category!,
                          style: AppStyles.labelSmall
                              .copyWith(color: theme.mutedTextColor),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '•',
                          style: AppStyles.labelSmall
                              .copyWith(color: theme.mutedTextColor),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        '${item.createdAt.year}-${item.createdAt.month.toString().padLeft(2, '0')}-${item.createdAt.day.toString().padLeft(2, '0')}',
                        style: AppStyles.labelSmall
                            .copyWith(color: theme.mutedTextColor),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, size: 20, color: theme.placeholderColor),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context, String status) {
    final theme = FeedbackOSTheme.of(context);
    final bg = theme.statusBackgroundColor(status);
    final fg = theme.statusForegroundColor(status);
    final dotColor = theme.statusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            status.replaceAll('_', ' '),
            style: AppStyles.labelSmall.copyWith(
              color: fg,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
