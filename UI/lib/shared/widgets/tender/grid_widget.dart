import 'package:flutter/material.dart';
import 'package:tendergo/shared/models/dto/tender_dto.dart';
import 'package:tendergo/shared/services/tender_service.dart';
import 'package:tendergo/admin/widgets/tender_widget.dart';
import 'package:tendergo/admin/screens/tender_details_screen.dart';

class TenderGrid extends StatelessWidget {
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
  Widget build(BuildContext context) {
    if (tenders.isEmpty) {
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
          children: tenders.map((dto) {
            final model = dto.toCardModel(dto);
            return SizedBox(
              width: cardWidth,
              child: AdminTenderCardWidget(
                tender: model,
                onTap: () {
                  if (onTenderSelected != null) {
                    onTenderSelected!(dto.id);
                    return;
                  }
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AdminTenderDetailsScreen(
                        tenderService: tenderService,
                        tenderId: dto.id,
                      ),
                    ),
                  );
                },
              ),
            );
          }).toList(),
        );
      },
    );
  }
}