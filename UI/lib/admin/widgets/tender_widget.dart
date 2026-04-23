import 'package:flutter/material.dart';
import 'package:tendergo/shared/core/actions/card_actions.dart';
import 'package:tendergo/shared/core/utils/extensions/string_extensions.dart';
import 'package:tendergo/shared/models/dto/category_dto.dart';
import 'package:tendergo/shared/models/enums/tenderstatus.dart';
import 'package:tendergo/shared/models/ui/tendercardmodel.dart';
import 'package:tendergo/shared/widgets/tender/card_image_widget.dart';
import 'package:tendergo/shared/widgets/tender/tag_chip_widget.dart';


// ─── Main widget ────────────────────────────────────────────────────────────────

class AdminTenderCardWidget extends StatelessWidget {
  const AdminTenderCardWidget({
    super.key,
    required this.tender,
    this.onTap,
    this.onSave,
    this.isSaved = false,
  });

  final TenderCardModel tender;
  final VoidCallback? onTap;
  final VoidCallback? onSave;
  final bool isSaved;


// Glavna metoda build koja sastavlja cijelu karticu koristeći manje widgete za različite dijelove (slika, tijelo, akcije)
  @override
  Widget build(BuildContext context) {
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
            TenderCardImage(
              imageUrl: tender.imageUrl,
              theme: themeForCategory(tender.category), // Ako si ostavio ovu logiku
              height: 140, // Možeš je fiksirati za desktop
            ),
            _CardBody(tender: tender),
            CardActions(
              onView: onTap,
              onSave: onSave,
              isSaved: isSaved,
              isClosed: tender.status == TenderStatus.closed,
            ),
          ],
        ),
      ),
    );
  }
}



// ─── Card body ──────────────────────────────────────────────────────────────────

class _CardBody extends StatelessWidget {
  const _CardBody({required this.tender});
  final TenderCardModel tender;



 @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10), 
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row za Kategoriju i Lokaciju
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Row(
                children: [
                  const Icon(Icons.pin_drop_outlined, size: 12, color: Color(0xFF185FA5)),
                  const SizedBox(width: 4),
                  Text(
                    tender.locationName,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF5F5E5A),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 5),

          // Title
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
            Wrap(
                children: [
              TenderTag(label: tender.category), 
                ],
            ),
            const SizedBox(height: 12),
          

          // Divider
          const Divider(height: 1, thickness: 0.5, color: Color(0xFFE5E3DC)),
          const SizedBox(height: 12),

          // Meta row (Time, Deadline i Budget)
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      timeAgo(tender.postedAt),
                      style: const TextStyle(fontSize: 11, color: Color(0xFFB4B2A9)),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.access_time_rounded, size: 13, color: Color(0xFF888780)),
                        const SizedBox(width: 4),
                        Text(
                          formatDeadline(tender.deadline),
                          style: const TextStyle(
                            fontSize: 12, 
                            color: Color(0xFF5F5E5A),
                            fontWeight: FontWeight.w500
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Budget
              Text(
                formatValue(tender.valueKM),
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
  }}








