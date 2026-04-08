import 'package:flutter/material.dart';
import 'package:tendergo_admin/models/dto/category_dto.dart';
import 'package:tendergo_admin/models/enums/tenderstatus.dart';
import 'package:tendergo_admin/models/ui/tendercardmodel.dart';
import 'package:tendergo_admin/widgets/action_button_widget.dart';
import 'package:tendergo_admin/widgets/status_badge_widget.dart';


// ─── Main widget ────────────────────────────────────────────────────────────────

class TenderCardWidget extends StatelessWidget {
  const TenderCardWidget({
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
            _CardImage(tender: tender),
            _CardBody(tender: tender),
            _CardActions(
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

// ─── Image / placeholder area ───────────────────────────────────────────────────

class _CardImage extends StatelessWidget {
  const _CardImage({required this.tender});
  final TenderCardModel tender;

  @override
  Widget build(BuildContext context) {
    final theme = themeForCategory(tender.category);

    return SizedBox(
      height: 140,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Image or placeholder
          tender.imageUrl != null
              ? Image.network(
                  tender.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _Placeholder(theme: theme),
                )
              : _Placeholder(theme: theme),

          // Status badge
          Positioned(
            top: 10,
            left: 10,
            child: StatusBadge(status: tender.status),
          ),
        ],
      ),
    );
  }
}

//REZERVNA OPCIJA U SLUCAJU DA TENDER NEMA SLIKU
class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.theme});
  final CategoryTheme theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: theme.bg,
      alignment: Alignment.center,
      child: Icon(theme.icon, size: 48, color: theme.bg.withOpacity(1).withAlpha(80)),
    );
  }
}



// ─── Card body ──────────────────────────────────────────────────────────────────

class _CardBody extends StatelessWidget {
  const _CardBody({required this.tender});
  final TenderCardModel tender;

//metoda za prikazivanje vremena proteklog od objave tendera
  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24)   return '${diff.inHours} hr ago';
    return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
  }

//metoda za prikazivanje fiksnog datuma isteka tendera
  String _formatDeadline(DateTime dt) {
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

//metoda za formatiranje novcanih vrijednosti
  String _formatValue(double v) {
    if (v >= 1000) {
      final s = v.toStringAsFixed(0);
      // insert dot every 3 digits from right
      final buf = StringBuffer();
      for (int i = 0; i < s.length; i++) {
        if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
        buf.write(s[i]);
      }
      return '${buf.toString()} KM';
    }
    return '${v.toStringAsFixed(0)} KM';
  }

 @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10), // Malo pojačan donji padding
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
                    tender.location,
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
              _Tag(label: tender.category), 
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
                      _timeAgo(tender.postedAt),
                      style: const TextStyle(fontSize: 11, color: Color(0xFFB4B2A9)),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.access_time_rounded, size: 13, color: Color(0xFF888780)),
                        const SizedBox(width: 4),
                        Text(
                          _formatDeadline(tender.deadline),
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
                _formatValue(tender.valueKM),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF185FA5), // Plava boja da istakne vrijednost
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }}

// ─── Tag chip ───────────────────────────────────────────────────────────────────

class _Tag extends StatelessWidget {
  const _Tag({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {

    final theme = themeForCategory(label);
    
    
    const primaryColor = Color(0xFF185FA5);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
       color: theme.bg, 
        borderRadius: BorderRadius.circular(6), 
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.2),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 11, color: Color(0xFF5F5E5A)),
      ),
    );
  }
}

// ─── Card actions ───────────────────────────────────────────────────────────────

class _CardActions extends StatelessWidget {
  const _CardActions({
    this.onView,
    this.onSave,
    required this.isSaved,
    required this.isClosed,
  });

  final VoidCallback? onView;
  final VoidCallback? onSave;
  final bool isSaved;
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
          const SizedBox(width: 8),
          ActionButton(
            label: isSaved ? 'Saved' : 'Save',
            isPrimary: false,
            onTap: onSave,
          ),
        ],
      ),
    );
  }
}




