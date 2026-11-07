import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/theme/styles.dart';
import '../../../core/utils/image_compressor.dart';
import '../../../core/utils/screenshot_picker.dart';
import '../../uploads/domain/entities/screenshot_attachment.dart';
import '../domain/entities/feedback_submit_result.dart';
import '../domain/entities/feedback_type.dart';
import '../state/feedback_bloc.dart';
import '../state/feedback_event.dart';
import '../state/feedback_state.dart';

/// Interactive modal sheet providing the new in-app UI for submitting feedback.
class FeedbackFormSheet extends StatelessWidget {
  final VoidCallback? onDismiss;
  final Future<ScreenshotAttachment?> Function()? onPickAttachment;
  final bool shouldShowCategory;
  final FeedbackType initialType;
  final VoidCallback? onViewMyRequests;

  const FeedbackFormSheet({
    super.key,
    this.onDismiss,
    this.onPickAttachment,
    this.initialType = FeedbackType.bug,
    this.shouldShowCategory = true,
    this.onViewMyRequests,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FeedbackOSTheme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: theme.backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      ),
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: BlocConsumer<FeedbackBloc, FeedbackState>(
              listener: (context, state) {},
              builder: (context, state) {
                if (state.isSuccess) {
                  return _SuccessView(
                    result: state.submissionResult,
                    state: state,
                    onClose: () {
                      onDismiss?.call();
                      Navigator.of(context, rootNavigator: true)
                          .pop(state.submissionResult);
                    },
                    onViewMyRequests: () {
                      Navigator.of(context, rootNavigator: true)
                          .pop(state.submissionResult);
                      onViewMyRequests?.call();
                    },
                  );
                }

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top drag grab handle
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: theme.borderMutedColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Header row: New request & Close X
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'New request',
                            style: AppStyles.titleHeader
                                .copyWith(color: theme.titleColor),
                          ),
                        ),
                        IconButton(
                          key: const Key('feedback_close_button'),
                          icon: Icon(Icons.close, color: theme.secondaryTextColor),
                          onPressed: () {
                            onDismiss?.call();
                            Navigator.of(context, rootNavigator: true).pop();
                          },
                          splashRadius: 20,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Section 1: What's this about?
                    if (shouldShowCategory) ...[
                      Text(
                        "What's this about?",
                        style: AppStyles.labelMedium
                            .copyWith(color: theme.secondaryTextColor),
                      ),
                      const SizedBox(height: 8),
                      const _TypeCards(),
                      const SizedBox(height: 16),
                    ],

                    // Section 2: Title
                    Text(
                      'Title',
                      style: AppStyles.labelMedium
                          .copyWith(color: theme.secondaryTextColor),
                    ),
                    const SizedBox(height: 6),
                    const _TitleField(),
                    const SizedBox(height: 16),

                    // Section 3: Details (Optional)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Details',
                          style: AppStyles.labelMedium
                              .copyWith(color: theme.secondaryTextColor),
                        ),
                        Text(
                          'Optional',
                          style: AppStyles.bodySmall
                              .copyWith(color: theme.mutedTextColor),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const _DescriptionField(),
                    const SizedBox(height: 16),

                    // Section 4: Screenshots
                    _ScreenshotAttachmentsSection(
                      onPickAttachment: onPickAttachment,
                    ),

                    if (state.errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        state.errorMessage!,
                        style:
                            AppStyles.error.copyWith(color: theme.errorColor),
                        textAlign: TextAlign.center,
                      ),
                    ],

                    const SizedBox(height: 24),
                    const _SubmitButton(),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Backward compatibility wrapper for [FeedbackFormSheet].
class FeedbackFormDialog extends StatelessWidget {
  final VoidCallback? onDismiss;
  final Future<ScreenshotAttachment?> Function()? onPickAttachment;
  final bool shouldShowCategory;
  final FeedbackType initialType;
  final VoidCallback? onViewMyRequests;

  const FeedbackFormDialog({
    super.key,
    this.onDismiss,
    this.onPickAttachment,
    this.initialType = FeedbackType.bug,
    this.shouldShowCategory = true,
    this.onViewMyRequests,
  });

  @override
  Widget build(BuildContext context) {
    return FeedbackFormSheet(
      onDismiss: onDismiss,
      onPickAttachment: onPickAttachment,
      initialType: initialType,
      shouldShowCategory: shouldShowCategory,
      onViewMyRequests: onViewMyRequests,
    );
  }
}

class _TypeCards extends StatelessWidget {
  const _TypeCards();

  @override
  Widget build(BuildContext context) {
    final currentType = context.select((FeedbackBloc b) => b.state.type);

    final isBug = currentType == FeedbackType.bug;
    final isIdea = currentType == FeedbackType.feature;

    return Row(
      children: [
        Expanded(
          child: _TypeCard(
            key: const Key('feedback_type_bug'),
            title: 'Report bug',
            icon: Icons.bug_report_outlined,
            isSelected: isBug,
            onTap: () {
              context
                  .read<FeedbackBloc>()
                  .add(const FeedbackTypeChanged(FeedbackType.bug));
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _TypeCard(
            key: const Key('feedback_type_feature'),
            title: 'Idea or request',
            icon: Icons.lightbulb_outline,
            isSelected: isIdea,
            onTap: () {
              context
                  .read<FeedbackBloc>()
                  .add(const FeedbackTypeChanged(FeedbackType.feature));
            },
          ),
        ),
      ],
    );
  }
}

class _TypeCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeCard({
    super.key,
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FeedbackOSTheme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 62,
        decoration: BoxDecoration(
          color: isSelected ? theme.accentSoftColor : theme.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? theme.accentColor : theme.borderMutedColor,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? theme.accentColor : theme.secondaryTextColor,
            ),
            const SizedBox(height: 5),
            Text(
              title,
              style: AppStyles.chipLabel.copyWith(
                color: isSelected ? theme.textColor : theme.secondaryTextColor,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TitleField extends StatelessWidget {
  const _TitleField();

  @override
  Widget build(BuildContext context) {
    final theme = FeedbackOSTheme.of(context);
    final type = context.select((FeedbackBloc b) => b.state.type);
    final hint = type == FeedbackType.bug
        ? 'Cannot save my profile'
        : 'Dark mode for the map';

    return TextFormField(
      key: const Key('feedback_title_field'),
      style: AppStyles.cardTitle.copyWith(color: theme.textColor),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppStyles.bodyMedium.copyWith(color: theme.mutedTextColor),
        filled: true,
        fillColor: theme.surfaceColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.borderMutedColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.borderMutedColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.accentColor, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      onChanged: (value) {
        context.read<FeedbackBloc>().add(FeedbackTitleChanged(value));
      },
    );
  }
}

class _DescriptionField extends StatelessWidget {
  const _DescriptionField();

  @override
  Widget build(BuildContext context) {
    final theme = FeedbackOSTheme.of(context);

    return TextFormField(
      key: const Key('feedback_description_field'),
      style: AppStyles.bodyMedium.copyWith(color: theme.textColor),
      minLines: 2,
      maxLines: 4,
      decoration: InputDecoration(
        hintText: 'Tapping Save just spins. Tried twice.',
        hintStyle: AppStyles.bodySmall.copyWith(color: theme.mutedTextColor),
        filled: true,
        fillColor: theme.surfaceColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.borderMutedColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.borderMutedColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.accentColor, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      onChanged: (value) {
        context.read<FeedbackBloc>().add(FeedbackDescriptionChanged(value));
      },
    );
  }
}

class _ScreenshotAttachmentsSection extends StatelessWidget {
  final Future<ScreenshotAttachment?> Function()? onPickAttachment;

  const _ScreenshotAttachmentsSection({this.onPickAttachment});

  @override
  Widget build(BuildContext context) {
    final theme = FeedbackOSTheme.of(context);
    final attachments = context.select((FeedbackBloc b) => b.state.attachments);
    final canAdd = context.select((FeedbackBloc b) => b.state.canAddAttachment);
    final picker = onPickAttachment ?? defaultScreenshotPicker;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Screenshots',
              style: AppStyles.labelMedium
                  .copyWith(color: theme.secondaryTextColor),
            ),
            Text(
              '${attachments.length} of 3',
              style: AppStyles.bodySmall.copyWith(color: theme.mutedTextColor),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (int i = 0; i < attachments.length; i++)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _AttachmentThumbnail(
                    index: i,
                    attachment: attachments[i],
                  ),
                ),
              if (canAdd)
                _AddAttachmentButton(
                  onTap: () async {
                    final picked = await picker();
                    if (picked != null && context.mounted) {
                      final compressed = ImageCompressor.compressAttachment(
                        bytes: picked.bytes,
                        fileName: picked.fileName,
                        localFilePath: picked.localFilePath,
                      );
                      context
                          .read<FeedbackBloc>()
                          .add(FeedbackAttachmentAdded(compressed));
                    }
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AttachmentThumbnail extends StatelessWidget {
  final int index;
  final ScreenshotAttachment attachment;

  const _AttachmentThumbnail({
    required this.index,
    required this.attachment,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FeedbackOSTheme.of(context);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 52,
          height: 70,
          decoration: BoxDecoration(
            color: theme.cardSecondaryColor,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: theme.borderColor),
          ),
          clipBehavior: Clip.antiAlias,
          child: attachment.bytes.isNotEmpty
              ? Image.memory(
                  attachment.bytes,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.image,
                    color: theme.mutedTextColor,
                  ),
                )
              : Icon(
                  Icons.image,
                  color: theme.mutedTextColor,
                ),
        ),
        Positioned(
          top: -6,
          right: -6,
          child: GestureDetector(
            key: Key('feedback_remove_attachment_$index'),
            onTap: () {
              context
                  .read<FeedbackBloc>()
                  .add(FeedbackAttachmentRemoved(index));
            },
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: theme.cardSecondaryColor,
                shape: BoxShape.circle,
                border: Border.all(color: theme.borderMutedColor),
              ),
              child: Icon(
                Icons.close,
                size: 11,
                color: theme.textColor,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AddAttachmentButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AddAttachmentButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = FeedbackOSTheme.of(context);

    return GestureDetector(
      key: const Key('feedback_add_attachment_button'),
      onTap: onTap,
      child: Container(
        width: 52,
        height: 70,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: theme.borderMutedColor,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              size: 20,
              color: theme.secondaryTextColor,
            ),
            const SizedBox(height: 3),
            Text(
              'Add',
              style: AppStyles.stepperLabel
                  .copyWith(color: theme.secondaryTextColor),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  const _SubmitButton();

  @override
  Widget build(BuildContext context) {
    final theme = FeedbackOSTheme.of(context);
    final canSubmit = context.select((FeedbackBloc b) => b.state.canSubmit);
    final isSubmitting =
        context.select((FeedbackBloc b) => b.state.isSubmitting);
    final type = context.select((FeedbackBloc b) => b.state.type);

    final label = type == FeedbackType.bug ? 'Send report' : 'Send request';

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            key: const Key('feedback_submit_button'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.accentColor,
              disabledBackgroundColor: theme.accentColor.withAlpha(70),
              foregroundColor: theme.accentOnColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
              ),
              elevation: 0,
            ),
            onPressed: canSubmit && !isSubmitting
                ? () {
                    context.read<FeedbackBloc>().add(const FeedbackSubmitted());
                  }
                : null,
            child: isSubmitting
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.accentOnColor,
                    ),
                  )
                : Text(
                    label,
                    style: AppStyles.buttonPrimary
                        .copyWith(color: theme.accentOnColor),
                  ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Replies show up in My requests.',
          style: AppStyles.bodySmall.copyWith(color: theme.mutedTextColor),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _SuccessView extends StatelessWidget {
  final FeedbackSubmitResult? result;
  final FeedbackState state;
  final VoidCallback onClose;
  final VoidCallback onViewMyRequests;

  const _SuccessView({
    required this.result,
    required this.state,
    required this.onClose,
    required this.onViewMyRequests,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FeedbackOSTheme.of(context);
    final isQueued = result?.status == FeedbackSubmitStatus.queued;
    final isBug = state.type == FeedbackType.bug;
    final attachmentCount = state.attachments.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: theme.borderMutedColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Align(
            alignment: Alignment.topRight,
            child: IconButton(
              key: const Key('feedback_close_button'),
              icon: Icon(Icons.close, color: theme.secondaryTextColor),
              onPressed: onClose,
              splashRadius: 20,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: isQueued
                  ? theme.warningBackgroundColor
                  : theme.accentSoftColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isQueued ? Icons.schedule_outlined : Icons.check,
              size: 32,
              color: isQueued ? theme.warningColor : theme.accentColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isQueued ? 'Saved for Later' : 'Thanks, we got it',
            style: AppStyles.titleLarge
                .copyWith(color: theme.titleColor, fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            isQueued
                ? 'Your feedback is saved offline and will automatically be sent once connectivity returns.'
                : "The team will reply here. You'll get a notification when they reply or when the status changes.",
            style:
                AppStyles.bodyMedium.copyWith(color: theme.secondaryTextColor),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          // Summary Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.surfaceColor,
              border: Border.all(color: theme.borderColor),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        state.title.isNotEmpty
                            ? state.title
                            : 'Submitted request',
                        style: AppStyles.cardTitle
                            .copyWith(color: theme.titleColor),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${isBug ? 'Bug' : 'Idea'} · $attachmentCount screenshot${attachmentCount == 1 ? '' : 's'}',
                        style: AppStyles.bodySmall
                            .copyWith(color: theme.secondaryTextColor),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: theme.statusBackgroundColor('open'),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: theme.statusColor('open'),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Open',
                        style: AppStyles.pillLabel.copyWith(
                          color: theme.statusForegroundColor('open'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Action Buttons
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              key: const Key('feedback_view_requests_button'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.accentColor,
                foregroundColor: theme.accentOnColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
                elevation: 0,
              ),
              onPressed: onViewMyRequests,
              child: Text(
                'View my requests',
                style: AppStyles.buttonPrimary
                    .copyWith(color: theme.accentOnColor),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton(
              key: const Key('feedback_success_done_button'),
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.textColor,
                side: BorderSide(color: theme.borderMutedColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
              onPressed: onClose,
              child: Text(
                'Back to app',
                style: AppStyles.buttonPrimary.copyWith(
                  color: theme.textColor,
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
