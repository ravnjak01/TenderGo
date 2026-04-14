import 'package:flutter/material.dart';
import 'package:tendergo_admin/models/dto/tender_dto.dart';
import 'package:tendergo_admin/services/tender_service.dart';
import 'package:tendergo_admin/widgets/tender_widget.dart';
import 'package:tendergo_admin/screens/tender_details_screen.dart';

class TenderGrid extends StatefulWidget {
  final List<TenderDto> tenders;
  final TenderService tenderService;
  final ValueChanged<int>? onTenderSelected;

  const TenderGrid({
    super.key,
    required this.tenders,
    required this.tenderService,
    this.onTenderSelected,
  });

  @override
  State<TenderGrid> createState() => _TenderGridState();
}

class _TenderGridState extends State<TenderGrid> {
  final Set<int> _savedIds = {};

  @override
  Widget build(BuildContext context) {
    if (widget.tenders.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: Text('No tenders match the selected filters.')),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 1;
        if (constraints.maxWidth >= 900) {
          crossAxisCount = 3;
        } else if (constraints.maxWidth >= 600) {
          crossAxisCount = 2;
        }

        final spacing = 14.0;
        final cardWidth =
            (constraints.maxWidth - spacing * (crossAxisCount - 1)) /
            crossAxisCount;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: widget.tenders.map((dto) {
            final model = dto.toCardModel(dto);
            return SizedBox(
              width: cardWidth,
              child: TenderCardWidget(
                tender: model,
                isSaved: _savedIds.contains(dto.id),
                onTap: () {
                  if (widget.onTenderSelected != null) {
                    widget.onTenderSelected!(dto.id);
                    return;
                  }
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => TenderDetailsScreen(
                        tenderService: widget.tenderService,
                        tenderId: dto.id,
                      ),
                    ),
                  );
                },
                onSave: () {
                  setState(() {
                    if (_savedIds.contains(dto.id)) {
                      _savedIds.remove(dto.id);
                    } else {
                      _savedIds.add(dto.id);
                    }
                  });
                },
              ),
            );
          }).toList(),
        );
      },
    );
  }
}