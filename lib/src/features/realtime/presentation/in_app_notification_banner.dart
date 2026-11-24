import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/theme/styles.dart';
import '../../../../core/theme/theme.dart';
import '../domain/entities/feedback_os_event.dart';

/// Title and message shown in the banner for [event].
({String title, String message}) bannerContentFor(FeedbackOSEvent event) {
  return switch (event) {
    ReplyReceived(:final authorName, :final preview) => (
        title: authorName == null ? 'New reply' : 'New reply from $authorName',
        message: preview,
      ),
    StatusChanged(:final toStatus) => (
        title: 'Status updated: ${toStatus.replaceAll('_', ' ')}',
        message: '',
      ),
  };
}

/// Shows a lightweight, auto-dismissing banner at the top of an [Overlay].
///
/// Only one banner is visible at a time; a new one replaces the previous.
class InAppNotificationBanner {
  final Duration displayDuration;

  OverlayEntry? _entry;
  Timer? _timer;

  InAppNotificationBanner({
    this.displayDuration = const Duration(seconds: 4),
  });

  bool get isShowing => _entry != null;

  void show({
    required OverlayState overlay,
    required String title,
    required String message,
    required FeedbackOSTheme theme,
    VoidCallback? onTap,
  }) {
    dismiss();
    final entry = OverlayEntry(
      builder: (context) => _BannerView(
        title: title,
        message: message,
        theme: theme,
        onTap: () {
          dismiss();
          onTap?.call();
        },
        onDismissed: dismiss,
      ),
    );
    _entry = entry;
    overlay.insert(entry);
    _timer = Timer(displayDuration, dismiss);
  }

  void dismiss() {
    _timer?.cancel();
    _timer = null;
    final entry = _entry;
    _entry = null;
    if (entry != null && entry.mounted) entry.remove();
  }
}

class _BannerView extends StatelessWidget {
  final String title;
  final String message;
  final FeedbackOSTheme theme;
  final VoidCallback onTap;
  final VoidCallback onDismissed;

  const _BannerView({
    required this.title,
    required this.message,
    required this.theme,
    required this.onTap,
    required this.onDismissed,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: -1, end: 0),
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            builder: (context, offset, child) => FractionalTranslation(
              translation: Offset(0, offset),
              child: child,
            ),
            child: Dismissible(
              key: const ValueKey('feedbackos_in_app_banner'),
              direction: DismissDirection.up,
              onDismissed: (_) => onDismissed(),
              child: Material(
                key: const Key('feedbackos_in_app_banner'),
                color: theme.surfaceColor,
                elevation: 6,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: onTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: theme.borderColor),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.chat_bubble_outline_rounded,
                          color: theme.primaryColor,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppStyles.cardTitle
                                    .copyWith(color: theme.titleColor),
                              ),
                              if (message.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  message,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppStyles.bodyMedium
                                      .copyWith(color: theme.mutedTextColor),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
