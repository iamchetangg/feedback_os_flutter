import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/styles.dart';
import '../../../../core/theme/theme.dart';
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
          'Your request',
          style: AppStyles.titleAppBar.copyWith(color: theme.titleColor),
        ),
        centerTitle: true,
        backgroundColor: theme.surfaceColor,
        elevation: 0.5,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: theme.titleColor, size: 20),
          onPressed: widget.onBack ?? () => Navigator.of(context).pop(),
        ),
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
              child: CircularProgressIndicator(color: theme.accentColor),
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
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  children: [
                    _buildHeaderCard(context, detail, theme),
                    const SizedBox(height: 14),
                    _buildTimeline(context, detail, theme),
                  ],
                ),
              ),
              _buildReplyBar(context, state.isSendingReply, theme),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeaderCard(
    BuildContext context,
    ThreadDetail detail,
    FeedbackOSTheme theme,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  detail.title,
                  style: AppStyles.cardTitle.copyWith(
                    color: theme.titleColor,
                    fontSize: 15.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _buildStatusChip(context, detail.status, theme),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${detail.description} · ${_formatMonthDay(detail.createdAt)}',
            style: AppStyles.bodySmall.copyWith(
              color: theme.mutedTextColor,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          _buildStageStepper(detail.status, theme),
        ],
      ),
    );
  }

  Widget _buildStageStepper(String currentStatus, FeedbackOSTheme theme) {
    final stages = ['Open', 'Planned', 'In progress', 'Shipped'];
    final normalized = currentStatus.toLowerCase().replaceAll('-', '_').trim();

    final currentIndex = switch (normalized) {
      'open' || 'under_review' => 0,
      'planned' => 1,
      'in_progress' || 'in progress' => 2,
      'shipped' || 'completed' => 3,
      _ => 0,
    };
    final fg = theme.statusForegroundColor(currentStatus);

    return Row(
      children: List.generate(stages.length, (index) {
        final isReached = index <= currentIndex;
        final isCurrent = index == currentIndex;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              left: index == 0 ? 0 : 2,
              right: index == stages.length - 1 ? 0 : 2,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color:
                        isReached ? fg : theme.borderMutedColor.withAlpha(50),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  stages[index],
                  style: (isCurrent
                          ? AppStyles.stepperLabelActive
                          : AppStyles.stepperLabel)
                      .copyWith(
                    color: isCurrent
                        ? fg
                        : isReached
                            ? theme.mutedTextColor
                            : theme.placeholderColor,
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildTimeline(
    BuildContext context,
    ThreadDetail detail,
    FeedbackOSTheme theme,
  ) {
    final items = <_TimelineItem>[
      ...detail.replies.map((r) => _TimelineItem.reply(r)),
      ...detail.events.map((e) => _TimelineItem.event(e)),
    ]..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Text(
            'No replies yet.',
            style: AppStyles.bodySmall.copyWith(color: theme.placeholderColor),
          ),
        ),
      );
    }

    return Column(
      children: items.map((item) {
        if (item.isEvent) {
          return _buildEventTile(context, item.event!, theme);
        } else {
          return _buildReplyBubble(context, item.reply!, theme);
        }
      }).toList(),
    );
  }

  Widget _buildEventTile(
    BuildContext context,
    ThreadEvent event,
    FeedbackOSTheme theme,
  ) {
    final status = event.newStatus ?? event.type;
    final formattedStatus = _formatStatusLabel(status);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: theme.statusBackgroundColor('planned'),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'Status changed to $formattedStatus',
            style: AppStyles.meta.copyWith(
              color: theme.statusPlannedColor,
              fontWeight: FontWeight.w500,
              fontSize: 11.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReplyBubble(
    BuildContext context,
    ThreadReply reply,
    FeedbackOSTheme theme,
  ) {
    final isAdmin = reply.isAdmin;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Align(
        alignment: isAdmin ? Alignment.centerLeft : Alignment.centerRight,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 260),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: isAdmin ? theme.cardSecondaryColor : theme.accentColor,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isAdmin ? 5 : 16),
              bottomRight: Radius.circular(isAdmin ? 16 : 5),
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
                    style: AppStyles.meta.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isAdmin ? theme.accentColor : theme.accentOnColor,
                      fontSize: 11.5,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${reply.createdAt.hour.toString().padLeft(2, '0')}:${reply.createdAt.minute.toString().padLeft(2, '0')}',
                    style: AppStyles.meta.copyWith(
                      color: isAdmin
                          ? theme.placeholderColor
                          : theme.accentOnColor.withAlpha(160),
                      fontSize: 10.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                reply.body,
                style: AppStyles.bodyMedium.copyWith(
                  color: isAdmin ? theme.textColor : theme.accentOnColor,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReplyBar(
    BuildContext context,
    bool isSending,
    FeedbackOSTheme theme,
  ) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        14,
        10,
        14,
        10 + MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: theme.backgroundColor,
        border: Border(top: BorderSide(color: theme.borderColor)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 42,
                child: TextField(
                  controller: _replyController,
                  style: AppStyles.bodyMedium.copyWith(color: theme.textColor),
                  decoration: InputDecoration(
                    hintText: 'Reply to the team',
                    hintStyle: AppStyles.bodyMedium
                        .copyWith(color: theme.placeholderColor),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    filled: true,
                    fillColor: theme.surfaceColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(21),
                      borderSide: BorderSide(color: theme.borderMutedColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(21),
                      borderSide: BorderSide(color: theme.borderMutedColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(21),
                      borderSide: BorderSide(color: theme.accentColor),
                    ),
                  ),
                  onSubmitted: (_) => _sendReply(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: isSending ? null : _sendReply,
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: theme.accentColor,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: isSending
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.accentOnColor,
                        ),
                      )
                    : Icon(
                        Icons.arrow_forward_rounded,
                        color: theme.accentOnColor,
                        size: 20,
                      ),
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

  String _formatMonthDay(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}';
  }
}

class _TimelineItem {
  final ThreadReply? reply;
  final ThreadEvent? event;
  final DateTime createdAt;
  final bool isEvent;

  _TimelineItem.reply(this.reply)
      : event = null,
        createdAt = reply!.createdAt,
        isEvent = false;

  _TimelineItem.event(this.event)
      : reply = null,
        createdAt = event!.createdAt,
        isEvent = true;
}
