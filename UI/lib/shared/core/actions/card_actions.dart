import 'package:flutter/material.dart';
import 'package:tendergo/admin/widgets/action_button_widget.dart';

class CardActions extends StatelessWidget {
  const CardActions({
    this.onView,
    required this.isClosed,
  });

  final VoidCallback? onView;
  final bool isClosed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 9, 14, 4),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFE5E3DC), width: 0.5)),
      ),
      child: Row(
        children: [
          ActionButton(
            label: 'View details',
            isPrimary: !isClosed,
            onTap: onView,
          ),
        ],
      ),
    );
  }
}