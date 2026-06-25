import 'package:flutter/material.dart';
import 'package:tendergo/shared/core/actions/card_actions.dart';
import 'package:tendergo/shared/core/utils/extensions/string_extensions.dart';
import 'package:tendergo/shared/models/dto/category_dto.dart';
import 'package:tendergo/shared/models/enums/tenderstatus.dart';
import 'package:tendergo/shared/models/ui/tendercardmodel.dart';
import 'package:tendergo/mobile/widgets/tender/card_image_widget.dart';
import 'package:tendergo/mobile/widgets/tender/tag_chip_widget.dart';

class MobileTenderCardWidget extends StatelessWidget {
  const MobileTenderCardWidget({
    super.key,
    required this.tender,
    this.onTap,
    this.onSave,
    this.isSaved = false,
    this.onCancelTender,
  });

  final TenderCardModel tender;
  final VoidCallback? onTap;
  final VoidCallback? onSave;
  final bool isSaved;
  final VoidCallback? onCancelTender;

  @override
  Widget build(BuildContext context) {
    final hasImage = tender.imageUrl?.trim().isNotEmpty ?? false;
    final saveAction = onSave;
    final cancelAction = onCancelTender;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E3DC), width: 0.5),
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasImage)
              Stack(
                children: [
                  TenderCardImage(
                    imageUrl: tender.imageUrl,
                    theme: themeForCategory(tender.category),
                    height: 130,
                  ),
                  if (saveAction != null)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: _SaveButton(isSaved: isSaved, onSave: saveAction),
                    ),
                  if (cancelAction != null)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: _CancelMenu(onCancelTender: cancelAction),
                    ),
                ],
              ),
            _CardBody(
              tender: tender,
              showInlineActions: !hasImage,
              isSaved: isSaved,
              onSave: onSave,
              onCancelTender: onCancelTender,
            ),
            CardActions(
              onView: onTap,
              isClosed: tender.status == TenderStatus.closed,
            ),
          ],
        ),
      ),
    );
  }
}

class _CardBody extends StatelessWidget {
  const _CardBody({
    required this.tender,
    required this.showInlineActions,
    required this.isSaved,
    this.onSave,
    this.onCancelTender,
  });

  final TenderCardModel tender;
  final bool showInlineActions;
  final bool isSaved;
  final VoidCallback? onSave;
  final VoidCallback? onCancelTender;

  @override
  Widget build(BuildContext context) {
    final saveAction = onSave;
    final cancelAction = onCancelTender;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (showInlineActions && saveAction != null) ...[
                _SaveButton(isSaved: isSaved, onSave: saveAction),
                const SizedBox(width: 8),
              ],
              const Icon(
                Icons.pin_drop_outlined,
                size: 12,
                color: Color(0xFF185FA5),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  tender.locationName,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF5F5E5A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (showInlineActions && cancelAction != null) ...[
                const SizedBox(width: 8),
                _CancelMenu(onCancelTender: cancelAction),
              ],
            ],
          ),
          const SizedBox(height: 5),
          Text(
            tender.title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
              height: 1.4,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          Wrap(children: [TenderTag(label: tender.category)]),
          const SizedBox(height: 12),
          const Divider(height: 1, thickness: 0.5, color: Color(0xFFE5E3DC)),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tender.postedAt.toTimeAgo(),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFFB4B2A9),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          size: 13,
                          color: Color(0xFF888780),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          tender.deadline.formatDeadline(),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF5F5E5A),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Text(
                tender.valueKM.formatCurrency(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF185FA5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  const _SaveButton({required this.isSaved, required this.onSave});

  final bool isSaved;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.9),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: IconButton(
        constraints: const BoxConstraints(),
        padding: const EdgeInsets.all(6),
        icon: Icon(
          isSaved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          size: 20,
          color: isSaved ? Colors.red : const Color(0xFF5F5E5A),
        ),
        onPressed: onSave,
      ),
    );
  }
}

class _CancelMenu extends StatelessWidget {
  const _CancelMenu({required this.onCancelTender});

  final VoidCallback onCancelTender;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.9),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert, size: 20),
        padding: EdgeInsets.zero,
        onSelected: (value) {
          if (value == 'cancel') onCancelTender();
        },
        itemBuilder: (context) => [
          const PopupMenuItem<String>(
            value: 'cancel',
            child: Text(
              'Cancel tender',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
