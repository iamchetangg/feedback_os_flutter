import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('Feedback Thread', style: AppStyles.titleMedium),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: widget.onBack != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF374151)),
                onPressed: widget.onBack,
              )
            : null,
      ),
      body: BlocConsumer<ThreadsBloc, ThreadsState>(
        listener: (context, state) {
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!,
                    style: AppStyles.labelMedium.copyWith(color: Colors.white)),
                backgroundColor: const Color(0xFFDC2626),
              ),
            );
          }
        },
        builder: (context, state) {
          if (state.status == ThreadsStatus.loading && state.selectedThread == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.selectedThread == null) {
            return const Center(
              child: Text('Thread not found.', style: AppStyles.bodyMedium),
            );
          }

          final detail = state.selectedThread!;
          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildHeaderCard(detail),
                    const SizedBox(height: 20),
                    _buildTimeline(detail),
                  ],
                ),
              ),
              _buildReplyBar(state.isSendingReply),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeaderCard(ThreadDetail detail) {
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
                child: Text(detail.title, style: AppStyles.titleMedium),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  detail.status.replaceAll('_', ' ').toUpperCase(),
                  style: AppStyles.labelSmall.copyWith(
                    color: const Color(0xFF4F46E5),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (detail.description.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(detail.description, style: AppStyles.bodyMedium),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              if (detail.category != null) ...[
                Text(detail.category!, style: AppStyles.labelSmall),
                const SizedBox(width: 8),
                const Text('•', style: AppStyles.labelSmall),
                const SizedBox(width: 8),
              ],
              Text(
                '${detail.createdAt.year}-${detail.createdAt.month.toString().padLeft(2, '0')}-${detail.createdAt.day.toString().padLeft(2, '0')}',
                style: AppStyles.labelSmall,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline(ThreadDetail detail) {
    // Collect all timeline items (replies and events) sorted by createdAt
    final items = <_TimelineItem>[
      ...detail.replies.map((r) => _TimelineItem.reply(r)),
      ...detail.events.map((e) => _TimelineItem.event(e)),
    ]..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    if (items.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Text(
            'No replies yet. Send a message below to start the conversation.',
            style: AppStyles.bodySmall,
          ),
        ),
      );
    }

    return Column(
      children: items.map((item) {
        if (item.isEvent) {
          return _buildEventTile(item.event!);
        } else {
          return _buildReplyBubble(item.reply!);
        }
      }).toList(),
    );
  }

  Widget _buildEventTile(ThreadEvent event) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            event.newStatus != null
                ? 'Status updated to: ${event.newStatus!.replaceAll('_', ' ')}'
                : 'Timeline update: ${event.type}',
            style: AppStyles.labelSmall,
          ),
        ),
      ),
    );
  }

  Widget _buildReplyBubble(ThreadReply reply) {
    final isAdmin = reply.isAdmin;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Align(
        alignment: isAdmin ? Alignment.centerLeft : Alignment.centerRight,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 300),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isAdmin ? const Color(0xFFEEF2FF) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isAdmin ? const Color(0xFFC7D2FE) : const Color(0xFFE5E7EB),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isAdmin ? 'FeedbackOS Team' : 'You',
                    style: AppStyles.labelSmall.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isAdmin ? const Color(0xFF4338CA) : const Color(0xFF374151),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${reply.createdAt.hour.toString().padLeft(2, '0')}:${reply.createdAt.minute.toString().padLeft(2, '0')}',
                    style: AppStyles.labelSmall.copyWith(fontSize: 10),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(reply.body, style: AppStyles.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReplyBar(bool isSending) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _replyController,
                decoration: InputDecoration(
                  hintText: 'Type your reply...',
                  hintStyle: AppStyles.bodyMedium.copyWith(color: const Color(0xFF9CA3AF)),
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendReply(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send, color: Color(0xFF4F46E5)),
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
