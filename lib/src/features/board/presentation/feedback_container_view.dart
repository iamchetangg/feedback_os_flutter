import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/styles.dart';
import '../../../../core/theme/theme.dart';
import '../../../feedback_os.dart';
import '../../threads/presentation/my_feedback_list_view.dart';
import '../../threads/state/threads_bloc.dart';
import '../../threads/state/threads_event.dart';
import '../state/board_bloc.dart';
import '../state/board_event.dart';
import 'board_view.dart';
import 'roadmap_view.dart';

/// Unified main container screen for the FeedbackOS experience.
///
/// Houses the App Bar, a 3-tab segmented control ('Board' | 'Roadmap' | 'My requests'),
/// and the floating '+ New request' button that launches feedback submission.
class FeedbackContainerView extends StatefulWidget {
  final int initialTabIndex;
  final VoidCallback? onBack;

  const FeedbackContainerView({
    super.key,
    this.initialTabIndex = 0,
    this.onBack,
  });

  @override
  State<FeedbackContainerView> createState() => _FeedbackContainerViewState();
}

class _FeedbackContainerViewState extends State<FeedbackContainerView> {
  late int _selectedTab;

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTabIndex.clamp(0, 2);
  }

  void _openThread(String itemId) {
    FeedbackOS.instance.openThreadDetail(
      context: context,
      itemId: itemId,
    );
  }

  Future<void> _openNewRequest() async {
    final result = await FeedbackOS.instance.showFeedback(
      context: context,
      onViewMyRequests: () {
        setState(() {
          _selectedTab = 2;
        });
      },
    );

    if (result != null && mounted) {
      context.read<ThreadsBloc>().add(const MyItemsStarted());
      context.read<BoardBloc>().add(const BoardStarted());
      context.read<BoardBloc>().add(const RoadmapStarted());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FeedbackOSTheme.of(context);
    final hasUnread = context.select<ThreadsBloc, bool>(
      (b) => b.state.items.any((item) => item.hasUnread),
    );

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
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: theme.titleColor, size: 20),
          onPressed: widget.onBack ?? () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          _buildSegmentedTabs(context, theme, hasUnread),
          const SizedBox(height: 8),
          Expanded(
            child: IndexedStack(
              index: _selectedTab,
              children: [
                BoardView(
                  isEmbedded: true,
                  onItemTap: _openThread,
                ),
                RoadmapView(
                  isEmbedded: true,
                  onItemTap: _openThread,
                ),
                MyFeedbackListView(
                  isEmbedded: true,
                  onItemTap: _openThread,
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openNewRequest,
        backgroundColor: theme.accentColor,
        foregroundColor: theme.accentOnColor,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(23)),
        icon: Icon(Icons.add, color: theme.accentOnColor, size: 20),
        label: Text(
          'New request',
          style: AppStyles.buttonPrimary.copyWith(
            color: theme.accentOnColor,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildSegmentedTabs(
    BuildContext context,
    FeedbackOSTheme theme,
    bool hasUnread,
  ) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 10, 14, 0),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: theme.borderColor),
      ),
      child: Row(
        children: [
          _buildTabButton(
            index: 0,
            label: 'Board',
            theme: theme,
          ),
          _buildTabButton(
            index: 1,
            label: 'Roadmap',
            theme: theme,
          ),
          _buildTabButton(
            index: 2,
            label: 'My requests',
            theme: theme,
            showDot: hasUnread && _selectedTab != 2,
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required int index,
    required String label,
    required FeedbackOSTheme theme,
    bool showDot = false,
  }) {
    final isSelected = _selectedTab == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTab = index;
          });
        },
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 32,
          decoration: BoxDecoration(
            color: isSelected ? theme.cardSecondaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? const [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: (isSelected
                        ? AppStyles.tabLabelSelected
                        : AppStyles.tabLabel)
                    .copyWith(
                  color: isSelected ? theme.titleColor : theme.mutedTextColor,
                  fontSize: 13,
                ),
              ),
              if (showDot) ...[
                const SizedBox(width: 5),
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: theme.accentColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
