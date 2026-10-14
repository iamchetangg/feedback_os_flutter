import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('My Feedback', style: AppStyles.titleMedium),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: onBack != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF374151)),
                onPressed: onBack,
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
          if (state.status == ThreadsStatus.loading && state.items.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.status == ThreadsStatus.failure && state.items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline,
                      size: 48, color: Color(0xFFDC2626)),
                  const SizedBox(height: 12),
                  Text(state.errorMessage ?? 'Failed to load your feedback',
                      style: AppStyles.bodyMedium),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () =>
                        context.read<ThreadsBloc>().add(const MyItemsStarted()),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state.items.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined,
                      size: 56, color: Color(0xFF9CA3AF)),
                  SizedBox(height: 12),
                  Text('You have not submitted any feedback yet.',
                      style: AppStyles.bodyMedium),
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
    final isBug = item.type.toLowerCase() == 'bug';

    return InkWell(
      onTap: () => onItemTap?.call(item.id),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: item.hasUnread
                ? const Color(0xFF6366F1)
                : const Color(0xFFE5E7EB),
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
                color:
                    isBug ? const Color(0xFFFEE2E2) : const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isBug ? Icons.bug_report_outlined : Icons.lightbulb_outline,
                size: 20,
                color:
                    isBug ? const Color(0xFFDC2626) : const Color(0xFF4F46E5),
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
                          style: AppStyles.titleSmall,
                        ),
                      ),
                      if (item.hasUnread) ...[
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF4F46E5),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      _buildStatusChip(item.status),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (item.category != null) ...[
                        Text(item.category!, style: AppStyles.labelSmall),
                        const SizedBox(width: 8),
                        const Text('•', style: AppStyles.labelSmall),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        '${item.createdAt.year}-${item.createdAt.month.toString().padLeft(2, '0')}-${item.createdAt.day.toString().padLeft(2, '0')}',
                        style: AppStyles.labelSmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, size: 20, color: Color(0xFF9CA3AF)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color bg;
    Color fg;
    switch (status.toLowerCase()) {
      case 'planned':
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFB45309);
        break;
      case 'in_progress':
        bg = const Color(0xFFDBEAFE);
        fg = const Color(0xFF1D4ED8);
        break;
      case 'shipped':
        bg = const Color(0xFFD1FAE5);
        fg = const Color(0xFF047857);
        break;
      case 'closed':
        bg = const Color(0xFFF3F4F6);
        fg = const Color(0xFF6B7280);
        break;
      default:
        bg = const Color(0xFFECFDF5);
        fg = const Color(0xFF059669);
    }

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
