import 'package:flutter/material.dart';
import 'package:tendergo/shared/core/theme/app_theme.dart';
import 'package:tendergo/shared/models/dto/tender_dto.dart';
import 'package:tendergo/shared/services/dio_client.dart';
import 'package:tendergo/shared/services/tender_service.dart';
import 'package:tendergo/shared/widgets/tender/tender_details_meta_card.dart';
import 'package:tendergo/shared/widgets/tender/tender_info_section.dart';
import 'package:intl/intl.dart';

class AdminTenderDetailsScreen extends StatefulWidget {
final int tenderId;

  const AdminTenderDetailsScreen({super.key, required this. tenderId});

@override
  State<AdminTenderDetailsScreen> createState() => _AdminTenderDetailsScreenState();
}


class _AdminTenderDetailsScreenState extends State<AdminTenderDetailsScreen> {
  late TenderService _tenderService;
  TenderDto? _tenderDetails;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tenderService = TenderService(DioClient.getDio());
    _loadTenderDetails();
  }

  Future<void> _loadTenderDetails() async {
    try {
      final data = await _tenderService.getById(widget.tenderId); 
      setState(() {
        _tenderDetails = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }
  
 @override
Widget build(BuildContext context) {
  if (_isLoading) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Detalji tendera')),
      body: const Center(child: CircularProgressIndicator()),
    );
  }

  if (_error != null) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Detalji tendera')),
      body: Center(child: Text('Greška pri učitavanju: $_error')),
    );
  }

  return Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(
      title: const Text('Detalji tendera'),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.of(context).pop(),
      ),
    ),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TenderInfoSection(
                  tender: _tenderDetails!,
                  imageHeight: 360,
                  showDescription: true,
                  titleStyle: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 24),
                TenderDetailsMetaCard(tender: _tenderDetails!),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
}
