import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/styles.dart';
import '../../uploads/domain/entities/screenshot_attachment.dart';
import '../domain/entities/feedback_submit_result.dart';
import '../domain/entities/feedback_type.dart';
import '../state/feedback_bloc.dart';
import '../state/feedback_event.dart';
import '../state/feedback_state.dart';

/// Modal dialog providing the user interface for submitting feedback.
class FeedbackFormDialog extends StatelessWidget {
  final VoidCallback? onDismiss;
  final Future<ScreenshotAttachment?> Function()? onPickAttachment;

  const FeedbackFormDialog({
    super.key,
    this.onDismiss,
    this.onPickAttachment,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      backgroundColor: Colors.white,
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: BlocConsumer<FeedbackBloc, FeedbackState>(
          listener: (context, state) {
            // Dismiss or notify if needed
          },
          builder: (context, state) {
            if (state.isSuccess) {
              return _SuccessView(
                result: state.submissionResult,
                onClose: () {
                  onDismiss?.call();
                  Navigator.of(context, rootNavigator: true)
                      .pop(state.submissionResult);
                },
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Header(
                    onClose: () {
                      onDismiss?.call();
                      Navigator.of(context, rootNavigator: true).pop();
                    },
                  ),
                  const SizedBox(height: 20),
                  const _TypeSelector(),
                  const SizedBox(height: 16),
                  if (state.availableCategories.isNotEmpty) ...[
                    const _CategoryDropdown(),
                    const SizedBox(height: 16),
                  ],
                  const _TitleField(),
                  const SizedBox(height: 16),
                  const _DescriptionField(),
                  const SizedBox(height: 16),
                  _ScreenshotAttachmentsSection(
                    onPickAttachment: onPickAttachment,
                  ),
                  if (state.errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      state.errorMessage!,
                      style: AppStyles.error,
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 24),
                  const _SubmitButton(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onClose;

  const _Header({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Send Feedback',
            style: AppStyles.titleLarge,
          ),
        ),
        IconButton(
          key: const Key('feedback_close_button'),
          icon: const Icon(Icons.close, color: Color(0xFF6B7280)),
          onPressed: onClose,
          splashRadius: 20,
        ),
      ],
    );
  }
}

class _TypeSelector extends StatelessWidget {
  const _TypeSelector();

  @override
  Widget build(BuildContext context) {
    final currentType = context.select((FeedbackBloc b) => b.state.type);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: _TypeButton(
              key: const Key('feedback_type_bug'),
              title: 'Bug Report',
              icon: Icons.bug_report_outlined,
              isSelected: currentType == FeedbackType.bug,
              onTap: () {
                context.read<FeedbackBloc>().add(
                      const FeedbackTypeChanged(FeedbackType.bug),
                    );
              },
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _TypeButton(
              key: const Key('feedback_type_feature'),
              title: 'Feature Idea',
              icon: Icons.lightbulb_outline,
              isSelected: currentType == FeedbackType.feature,
              onTap: () {
                context.read<FeedbackBloc>().add(
                      const FeedbackTypeChanged(FeedbackType.feature),
                    );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeButton({
    super.key,
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withAlpha(12),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected
                  ? const Color(0xFF111827)
                  : const Color(0xFF6B7280),
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: isSelected ? AppStyles.titleSmall : AppStyles.labelMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryDropdown extends StatelessWidget {
  const _CategoryDropdown();

  @override
  Widget build(BuildContext context) {
    final state = context.select((FeedbackBloc b) => b.state);

    return DropdownButtonFormField<String>(
      key: const Key('feedback_category_dropdown'),
      initialValue: state.category,
      decoration: InputDecoration(
        labelText: 'Category (Optional)',
        labelStyle: AppStyles.labelMedium,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      items: [
        const DropdownMenuItem<String>(
          value: null,
          child: Text('None', style: AppStyles.bodyMedium),
        ),
        ...state.availableCategories.map(
          (cat) => DropdownMenuItem(
            value: cat,
            child: Text(cat, style: AppStyles.bodyMedium),
          ),
        ),
      ],
      onChanged: (value) {
        context.read<FeedbackBloc>().add(FeedbackCategoryChanged(value));
      },
    );
  }
}

class _TitleField extends StatelessWidget {
  const _TitleField();

  @override
  Widget build(BuildContext context) {
    final type = context.select((FeedbackBloc b) => b.state.type);
    final hint = type == FeedbackType.bug
        ? 'What went wrong?'
        : 'What feature would you like to see?';

    return TextFormField(
      key: const Key('feedback_title_field'),
      style: AppStyles.bodyLarge,
      decoration: InputDecoration(
        labelText: 'Title *',
        hintText: hint,
        labelStyle: AppStyles.labelMedium,
        hintStyle: AppStyles.bodySmall,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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
    return TextFormField(
      key: const Key('feedback_description_field'),
      style: AppStyles.bodyLarge,
      maxLines: 4,
      decoration: InputDecoration(
        labelText: 'Description (Optional)',
        hintText: 'Add details, steps to reproduce, or suggestions...',
        labelStyle: AppStyles.labelMedium,
        hintStyle: AppStyles.bodySmall,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      onChanged: (value) {
        context.read<FeedbackBloc>().add(FeedbackDescriptionChanged(value));
      },
    );
  }
}

class _SubmitButton extends StatelessWidget {
  const _SubmitButton();

  @override
  Widget build(BuildContext context) {
    final canSubmit = context.select((FeedbackBloc b) => b.state.canSubmit);
    final isSubmitting =
        context.select((FeedbackBloc b) => b.state.isSubmitting);

    return ElevatedButton(
      key: const Key('feedback_submit_button'),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF2563EB),
        disabledBackgroundColor: const Color(0xFF93C5FD),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 0,
      ),
      onPressed: canSubmit && !isSubmitting
          ? () {
              context.read<FeedbackBloc>().add(const FeedbackSubmitted());
            }
          : null,
      child: isSubmitting
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Text('Send Feedback', style: AppStyles.labelLarge),
    );
  }
}

class _SuccessView extends StatelessWidget {
  final FeedbackSubmitResult? result;
  final VoidCallback onClose;

  const _SuccessView({required this.result, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final isQueued = result?.status == FeedbackSubmitStatus.queued;

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color:
                  isQueued ? const Color(0xFFFEF3C7) : const Color(0xFFDCFCE7),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isQueued ? Icons.schedule_outlined : Icons.check_circle_outline,
              size: 48,
              color:
                  isQueued ? const Color(0xFFD97706) : const Color(0xFF16A34A),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isQueued ? 'Saved for Later' : 'Thank You!',
            style: AppStyles.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            isQueued
                ? 'Your feedback is saved offline and will automatically be sent once connectivity returns.'
                : 'Your feedback has been received and helps us make the app better.',
            style: AppStyles.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              key: const Key('feedback_success_done_button'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF111827),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: onClose,
              child: const Text('Done', style: AppStyles.labelLarge),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScreenshotAttachmentsSection extends StatelessWidget {
  final Future<ScreenshotAttachment?> Function()? onPickAttachment;

  const _ScreenshotAttachmentsSection({this.onPickAttachment});

  @override
  Widget build(BuildContext context) {
    final attachments =
        context.select((FeedbackBloc b) => b.state.attachments);
    final canAdd =
        context.select((FeedbackBloc b) => b.state.canAddAttachment);

    if (attachments.isEmpty && onPickAttachment == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Screenshots (optional)', style: AppStyles.labelMedium),
            Text('${attachments.length}/3', style: AppStyles.bodySmall),
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
              if (canAdd && onPickAttachment != null)
                _AddAttachmentButton(
                  onTap: () async {
                    final picked = await onPickAttachment!();
                    if (picked != null && context.mounted) {
                      context
                          .read<FeedbackBloc>()
                          .add(FeedbackAttachmentAdded(picked));
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
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          clipBehavior: Clip.antiAlias,
          child: attachment.bytes.isNotEmpty
              ? Image.memory(
                  attachment.bytes,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.image,
                    color: Color(0xFF9CA3AF),
                  ),
                )
              : const Icon(
                  Icons.image,
                  color: Color(0xFF9CA3AF),
                ),
        ),
        Positioned(
          top: -4,
          right: -4,
          child: GestureDetector(
            key: Key('feedback_remove_attachment_$index'),
            onTap: () {
              context
                  .read<FeedbackBloc>()
                  .add(FeedbackAttachmentRemoved(index));
            },
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Color(0xFF1F2937),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                size: 12,
                color: Colors.white,
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
    return GestureDetector(
      key: const Key('feedback_add_attachment_button'),
      onTap: onTap,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFFD1D5DB),
          ),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              size: 20,
              color: Color(0xFF6B7280),
            ),
            SizedBox(height: 2),
            Text(
              'Add',
              style: AppStyles.labelSmall,
            ),
          ],
        ),
      ),
    );
  }
}

