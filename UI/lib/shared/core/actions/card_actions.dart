import 'package:flutter/material.dart';
import 'package:tendergo/shared/widgets/common/action_button.dart';

class CardActions extends StatelessWidget {
  const CardActions({
    this.onView,
    required this.isClosed,
    this.onCancelTender,
  });

  final VoidCallback? onView;
  final bool isClosed;
  final VoidCallback? onCancelTender;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 9, 14, 4),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFE5E3DC), width: 0.5)),
      ),
      child: Row(
        children: [
          if (onCancelTender != null) ...[
            ActionButton(
              label: 'Cancel tender',
              isPrimary: false,
              isDestructive: true,
              onTap: onCancelTender,
              showLabel: true,
              icon: Icons.cancel_outlined,
            ),
            const SizedBox(width: 8),
          ],
          ActionButton(
            label: 'View details',
            isPrimary: !isClosed,
            onTap: onView,
            showLabel: true,
            icon: Icons.arrow_forward_ios_rounded,
          ),
        ],
      ),
    );
  }
}