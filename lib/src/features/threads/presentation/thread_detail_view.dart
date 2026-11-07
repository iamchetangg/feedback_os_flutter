import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/theme/styles.dart';
import '../domain/entities/thread_detail.dart';
import '../domain/entities/thread_event.dart';
import '../domain/entities/thread_reply.dart';
import '../state/threads_bloc.dart';
import '../state/threads_event.dart';
import '../state/threads_state.dart';

/// Screen displaying a specific feedback discussion thread and message replies.
class ThreadDetailView extends StatefulWidget {
  final String itemId;
  final VoidCallback? onBack;

  const ThreadDetailView({
    super.key,
    required this.itemId,
    this.onBack,
  });

  @override
  State<ThreadDetailView> createState() => _ThreadDetailViewState();
}

class _ThreadDetailViewState extends State<ThreadDetailView> {
  final TextEditingController _replyController = TextEditingController();

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  void _sendReply() {
    final text = _replyController.text.trim();
    if (text.isEmpty) return;

    context.read<ThreadsBloc>().add(ThreadReplySubmitted(
          itemId: widget.itemId,
          message: text,
        ));
    _replyController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FeedbackOSTheme.of(context);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Feedback Thread',
          style: AppStyles.titleMedium.copyWith(color: theme.titleColor),
        ),
        backgroundColor: theme.surfaceColor,
        elevation: 0.5,
        leading: widget.onBack != null
            ? IconButton(
                icon: Icon(Icons.arrow_back, color: theme.titleColor),
                onPressed: widget.onBack,
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
          if (state.status == ThreadsStatus.loading &&
              state.selectedThread == null) {
            return Center(
              child: CircularProgressIndicator(color: theme.primaryColor),
            );
          }

          if (state.selectedThread == null) {
            return Center(
              child: Text(
                'Thread not found.',
                style:
                    AppStyles.bodyMedium.copyWith(color: theme.mutedTextColor),
              ),
            );
          }

          final detail = state.selectedThread!;
          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildHeaderCard(context, detail),
                    const SizedBox(height: 20),
                    _buildTimeline(context, detail),
                  ],
                ),
              ),
              _buildReplyBar(context, state.isSendingReply),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context, ThreadDetail detail) {
    final theme = FeedbackOSTheme.of(context);

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
                  detail.title,
                  style:
                      AppStyles.titleMedium.copyWith(color: theme.titleColor),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.primaryLightColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  detail.status.replaceAll('_', ' ').toUpperCase(),
                  style: AppStyles.labelSmall.copyWith(
                    color: theme.primaryColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (detail.description.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              detail.description,
              style: AppStyles.bodyMedium.copyWith(color: theme.textColor),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              if (detail.category != null) ...[
                Text(
                  detail.category!,
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
                '${detail.createdAt.year}-${detail.createdAt.month.toString().padLeft(2, '0')}-${detail.createdAt.day.toString().padLeft(2, '0')}',
                style:
                    AppStyles.labelSmall.copyWith(color: theme.mutedTextColor),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline(BuildContext context, ThreadDetail detail) {
    final theme = FeedbackOSTheme.of(context);

    // Collect all timeline items (replies and events) sorted by createdAt
    final items = <_TimelineItem>[
      ...detail.replies.map((r) => _TimelineItem.reply(r)),
      ...detail.events.map((e) => _TimelineItem.event(e)),
    ]..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Text(
            'No replies yet. Send a message below to start the conversation.',
            style: AppStyles.bodySmall.copyWith(color: theme.mutedTextColor),
          ),
        ),
      );
    }

    return Column(
      children: items.map((item) {
        if (item.isEvent) {
          return _buildEventTile(context, item.event!);
        } else {
          return _buildReplyBubble(context, item.reply!);
        }
      }).toList(),
    );
  }

  Widget _buildEventTile(BuildContext context, ThreadEvent event) {
    final theme = FeedbackOSTheme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: theme.secondaryBackgroundColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            event.newStatus != null
                ? 'Status updated to: ${event.newStatus!.replaceAll('_', ' ')}'
                : 'Timeline update: ${event.type}',
            style:
                AppStyles.labelSmall.copyWith(color: theme.secondaryTextColor),
          ),
        ),
      ),
    );
  }

  Widget _buildReplyBubble(BuildContext context, ThreadReply reply) {
    final theme = FeedbackOSTheme.of(context);
    final isAdmin = reply.isAdmin;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment:
            isAdmin ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          Container(
            constraints: const BoxConstraints(maxWidth: 300),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isAdmin ? theme.primaryLightColor : theme.surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color:
                    isAdmin ? theme.primaryLightBorderColor : theme.borderColor,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isAdmin
                          ? (reply.authorName != null &&
                                  reply.authorName!.trim().isNotEmpty
                              ? reply.authorName!.trim()
                              : 'FeedbackOS Team')
                          : 'You',
                      style: AppStyles.labelSmall.copyWith(
                        fontWeight: FontWeight.w700,
                        color:
                            isAdmin ? theme.primaryDarkColor : theme.titleColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${reply.createdAt.hour.toString().padLeft(2, '0')}:${reply.createdAt.minute.toString().padLeft(2, '0')}',
                      style: AppStyles.labelSmall
                          .copyWith(fontSize: 10, color: theme.mutedTextColor),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  reply.body,
                  style: AppStyles.bodyMedium.copyWith(color: theme.textColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReplyBar(BuildContext context, bool isSending) {
    final theme = FeedbackOSTheme.of(context);

    return Container(
      color: theme.surfaceColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _replyController,
                style: AppStyles.bodyMedium.copyWith(color: theme.textColor),
                decoration: InputDecoration(
                  hintText: 'Type your reply...',
                  hintStyle: AppStyles.bodyMedium
                      .copyWith(color: theme.placeholderColor),
                  filled: true,
                  fillColor: theme.backgroundColor,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: theme.borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: theme.borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: theme.primaryColor),
                  ),
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendReply(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: isSending
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.primaryColor,
                      ),
                    )
                  : Icon(Icons.send, color: theme.primaryColor),
              onPressed: isSending ? null : _sendReply,
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineItem {
  final ThreadReply? reply;
  final ThreadEvent? event;
  final DateTime createdAt;

  _TimelineItem.reply(this.reply)
      : event = null,
        createdAt = reply!.createdAt;

  _TimelineItem.event(this.event)
      : reply = null,
        createdAt = event!.createdAt;

  bool get isEvent => event != null;
}
