import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tendergo_admin/models/dto/tender_dto.dart';
import 'package:tendergo_admin/models/ui/tendercardmodel.dart';
import 'package:tendergo_admin/providers/tender_provider.dart';
import 'package:tendergo_admin/services/tender_service.dart';
import 'package:tendergo_admin/models/enums/tenderstatus.dart';
import 'package:tendergo_admin/widgets/tender_widget.dart';

class TenderListScreen extends StatefulWidget {
  final TenderService tenderService;

  const TenderListScreen({super.key, required this.tenderService});

  @override
  State<TenderListScreen> createState() => _TenderListScreenState();
}

class _TenderListScreenState extends State<TenderListScreen> {
  final Set<int> _savedIds = {};

  // Maps your existing TenderStatus enum → TenderCardWidget's TenderStatus enum
  TenderStatus _mapStatus(TenderStatus status) {
    switch (status) {
      case TenderStatus.open:
        return TenderStatus.open;
      case TenderStatus.closed:
        return TenderStatus.closed;
      default:
        return TenderStatus.open;
    }
  }

  // Converts TenderDto → TenderModel expected by the card widget
TenderCardModel _toCardModel(TenderDto dto) {
  return TenderCardModel(
    id: dto.id.toString(),
    
    title: dto.title,
    category: dto.categoryName, 
    
    status: _mapStatus(dto.status),
    
    // maxBudget mapiramo na valueKM
    valueKM: dto.maxBudget,
    
    // Datumi
    deadline: dto.deadline,
    postedAt: dto.postedAt,
    
    // Pošto u tvom DTO trenutno nemaš listu tagova, 
    // možemo poslati praznu listu ili fiksne tagove (Public, Infrastructure)
    tags: [dto.locationName, dto.country], 
    
    // Izvlačimo URL iz TenderImageDto objekta ako postoji
    imageUrl: dto.images?.imageUrl, 
  );
}

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<TenderProvider>(
      create: (_) => TenderProvider(widget.tenderService)..fetchActiveTenders(),
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F2EB),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            'TenderGo',
            style: TextStyle(
              color: Color(0xFF185FA5),
              fontWeight: FontWeight.w500,
              fontSize: 18,
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(0.5),
            child: Container(height: 0.5, color: const Color(0xFFE5E3DC)),
          ),
        ),
        body: Consumer<TenderProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (provider.error != null) {
              return Center(child: Text('Greška: ${provider.error}'));
            }

            final tenders = provider.tenders;

            if (tenders.isEmpty) {
              return const Center(child: Text('Nema dostupnih tendera.'));
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                // Responsive column count
                int crossAxisCount = 1;
                if (constraints.maxWidth >= 900) {
                  crossAxisCount = 3;
                } else if (constraints.maxWidth >= 600) {
                  crossAxisCount = 2;
                }

               return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  int crossAxisCount = 1;
                  if (constraints.maxWidth >= 900) crossAxisCount = 3;
                  else if (constraints.maxWidth >= 600) crossAxisCount = 2;

                  final cardWidth = (constraints.maxWidth - 16 * (crossAxisCount + 1)) / crossAxisCount;

      return Wrap(
        spacing: 14,
        runSpacing: 14,
        children: tenders.map((dto) {
          final model = _toCardModel(dto);
          return SizedBox(
            width: cardWidth,
            child: TenderCardWidget(
              tender: model,
              isSaved: _savedIds.contains(dto.id),
              onTap: () => Navigator.pushNamed(context, '/tender-detail', arguments: dto),
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
  ),
);
              },
            );
          },
        ),
      ),
    );
  }
}