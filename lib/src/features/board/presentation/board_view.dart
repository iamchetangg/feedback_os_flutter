import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/styles.dart';
import '../domain/entities/board_item.dart';
import '../state/board_bloc.dart';
import '../state/board_event.dart';
import '../state/board_state.dart';

/// Community feedback board view with sorting, pagination, and upvoting.
class BoardView extends StatelessWidget {
  final VoidCallback? onBack;

  const BoardView({super.key, this.onBack});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('Community Board', style: AppStyles.titleMedium),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: onBack != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF374151)),
                onPressed: onBack,
              )
            : null,
      ),
      body: BlocConsumer<BoardBloc, BoardState>(
        listener: (context, state) {
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!, style: AppStyles.labelMedium.copyWith(color: Colors.white)),
                backgroundColor: const Color(0xFFDC2626),
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
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Text('Sort by:', style: AppStyles.bodySmall),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text('Top'),
            selected: state.sort == 'top',
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
    if (state.status == BoardStatus.loading && state.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.status == BoardStatus.failure && state.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Color(0xFFDC2626)),
            const SizedBox(height: 12),
            Text(state.errorMessage ?? 'Failed to load community board',
                style: AppStyles.bodyMedium),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.read<BoardBloc>().add(BoardStarted(sort: state.sort)),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.items.isEmpty) {
      return const Center(
        child: Text('No feature requests yet.', style: AppStyles.bodyMedium),
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
              onPressed: () => context.read<BoardBloc>().add(const BoardNextPageRequested()),
              icon: const Icon(Icons.expand_more),
              label: const Text('Load More'),
            ),
          );
        }

        final item = state.items[index];
        return _buildItemCard(context, item);
      },
    );
  }

  Widget _buildItemCard(BuildContext context, BoardItem item) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
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
                        style: AppStyles.titleSmall,
                      ),
                    ),
                    _buildStatusChip(item.status),
                  ],
                ),
                if (item.description.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    item.description,
                    style: AppStyles.bodySmall,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (item.category != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(item.category!, style: AppStyles.labelSmall),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (item.isMine)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'You submitted',
                          style: AppStyles.labelSmall.copyWith(color: const Color(0xFF4F46E5)),
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
          color: hasVoted ? const Color(0xFFEEF2FF) : const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: hasVoted ? const Color(0xFF6366F1) : const Color(0xFFE5E7EB),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.keyboard_arrow_up,
              size: 20,
              color: hasVoted ? const Color(0xFF4F46E5) : const Color(0xFF6B7280),
            ),
            Text(
              '${item.voteCount}',
              style: AppStyles.labelSmall.copyWith(
                fontWeight: FontWeight.w700,
                color: hasVoted ? const Color(0xFF4F46E5) : const Color(0xFF374151),
              ),
            ),
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
      default:
        bg = const Color(0xFFF3F4F6);
        fg = const Color(0xFF4B5563);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.replaceAll('_', ' '),
        style: AppStyles.labelSmall.copyWith(color: fg, fontWeight: FontWeight.w600),
      ),
    );
  }
}
