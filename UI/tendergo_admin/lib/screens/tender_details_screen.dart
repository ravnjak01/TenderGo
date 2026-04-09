import 'package:flutter/material.dart';
import 'package:tendergo_admin/core/theme/app_theme.dart';
import 'package:tendergo_admin/models/dto/tender_dto.dart';
import 'package:tendergo_admin/services/tender_service.dart';

class TenderDetailsScreen extends StatefulWidget {
  final TenderService tenderService;
  final int? tenderId;

  const TenderDetailsScreen({
    super.key,
    required this.tenderService,
    this.tenderId,
  });

  @override
  State<TenderDetailsScreen> createState() => _TenderDetailsScreenState();
}

class _TenderDetailsScreenState extends State<TenderDetailsScreen> {
  Future<TenderDto>? _tenderFuture;
  bool _initialized = false;
  int _activeImageIndex = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;

    final args = ModalRoute.of(context)?.settings.arguments;
    int? resolvedId = widget.tenderId;

    if (resolvedId == null) {
      if (args is int) {
        resolvedId = args;
      } else if (args is TenderDto) {
        resolvedId = args.id;
      }
    }

    if (resolvedId != null) {
      _tenderFuture = _loadTender(resolvedId);
    }
  }

  Future<TenderDto> _loadTender(int id) async {
    final dynamic data = await widget.tenderService.getById(id);
    if (data is TenderDto) return data;
    if (data is Map<String, dynamic>) return TenderDto.fromJson(data);
    throw Exception('Unexpected tender payload from backend.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Tender details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _tenderFuture == null
          ? const Center(child: Text('Missing tender id.'))
          : FutureBuilder<TenderDto>(
              future: _tenderFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError || !snapshot.hasData) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final tender = snapshot.data!;
                final imageUrls = _extractImageUrls(tender);

                return SingleChildScrollView(
                  child: Container(
                    color: AppColors.surface,
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Category Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            tender.categoryName,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 2. Title
                        Text(
                          tender.title,
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 16),

                        // 3. Meta info (Date, Location, Budget)
                        Wrap(
                          spacing: 20,
                          runSpacing: 10,
                          children: [
                            _metaItem(Icons.calendar_today_outlined, 'Posted ${_formatDate(tender.postedAt)}'),
                            _metaItem(Icons.location_on_outlined, tender.locationName),
                            _metaItem(Icons.account_balance_wallet_outlined, 'Budget: ${_formatBudget(tender.maxBudget)}'),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // 4. Images Section (if any)
                        if (imageUrls.isNotEmpty) ...[
                          _imageSection(imageUrls),
                          const SizedBox(height: 32),
                        ],

                        // 5. Project Description Header
                        const Text(
                          'Project Description',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // 6. Description Body
                        Text(
                          (tender.description ?? 'No description provided.').trim(),
                          style: const TextStyle(
                            fontSize: 15,
                            color: AppColors.textSecondary,
                            height: 1.6,
                          ),
                        ),
                        
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _metaItem(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
      ],
    );
  }

  Widget _imageSection(List<String> imageUrls) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: PageView.builder(
              itemCount: imageUrls.length,
              onPageChanged: (i) => setState(() => _activeImageIndex = i),
              itemBuilder: (context, index) => Image.network(
                imageUrls[index],
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: AppColors.surfaceVariant,
                  child: const Icon(Icons.broken_image, color: AppColors.textDisabled),
                ),
              ),
            ),
          ),
        ),
        if (imageUrls.length > 1) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              imageUrls.length,
              (index) => Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _activeImageIndex == index ? AppColors.primary : AppColors.textDisabled,
                ),
              ),
            ),
          ),
        ]
      ],
    );
  }

  List<String> _extractImageUrls(TenderDto tender) {
    return (tender.images ?? []).map((img) => img.imageUrl.trim()).where((url) => url.isNotEmpty).toList();
  }

  String _formatDate(DateTime date) => "${date.day} ${_months[date.month - 1]} ${date.year}";
  
  String _formatBudget(double value) => "${value.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} KM";

  static const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
}