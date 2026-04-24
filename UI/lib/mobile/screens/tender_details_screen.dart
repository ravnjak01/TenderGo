import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tendergo/shared/core/error/bid_error_handler.dart';
import 'package:tendergo/shared/core/theme/app_theme.dart';
import 'package:tendergo/shared/models/dto/bid_dto.dart';
import 'package:tendergo/shared/models/dto/tender_dto.dart';
import 'package:tendergo/shared/services/bid_service.dart';
import 'package:tendergo/shared/services/dio_client.dart';
import 'package:tendergo/shared/services/tender_service.dart';
import 'package:tendergo/shared/widgets/feedback/screen_state_widget.dart';

class MobileTenderDetailsScreen extends StatefulWidget {
  final TenderService tenderService;
  final int? tenderId;
  final bool embedded;

  const MobileTenderDetailsScreen({
    super.key,
    required this.tenderService,
    this.tenderId,
    this.embedded = false,
  });

  @override
  State<MobileTenderDetailsScreen> createState() => _MobileTenderDetailsScreenState();
}

class _MobileTenderDetailsScreenState extends State<MobileTenderDetailsScreen> {
  Future<TenderDto>? _tenderFuture;
  bool _initialized = false;
  int? _resolvedTenderId;
  int _activeImageIndex = 0;
  final _bidFormKey = GlobalKey<FormState>();
  late final BidService _bidService;
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _proposalController = TextEditingController();
  final TextEditingController _deliveryDaysController = TextEditingController();
  bool _isSubmittingBid = false;
  String? _bidError;

  @override
  void initState() {
    super.initState();
    _bidService = BidService(DioClient.getDio());
  }

  @override
  void dispose() {
    _priceController.dispose();
    _proposalController.dispose();
    _deliveryDaysController.dispose();
    super.dispose();
  }

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
      _resolvedTenderId = resolvedId;
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
    final content = _tenderFuture == null
        ? const Center(child: Text('Missing tender id.'))
        : FutureBuilder<TenderDto>(
            future: _tenderFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const ScreenLoadingState();
              }
              if (snapshot.hasError || !snapshot.hasData) {
                return ScreenErrorState(
                  message: snapshot.error?.toString() ?? 'Could not load tender details.',
                  onRetry: () {
                    final id = _resolvedTenderId;
                    if (id == null) return;
                    setState(() => _tenderFuture = _loadTender(id));
                  },
                );
              }

              final tender = snapshot.data!;
              final imageUrls = _extractImageUrls(tender);

              return SingleChildScrollView(
                child: Container(
                  color: AppColors.surface,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTenderSection(tender, imageUrls),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.primary.withOpacity(0.18)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.gavel_rounded, size: 18, color: AppColors.primary),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Submit your bid below',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildBidSection(tender),
                    ],
                  ),
                ),
              );
            },
          );

    if (widget.embedded) {
      return content;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Tender details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: content,
    );
  }

  Widget _buildTenderSection(TenderDto tender, List<String> imageUrls) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel(
            icon: Icons.description_outlined,
            label: 'Tender Overview',
          ),
          const SizedBox(height: 14),
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
          const SizedBox(height: 14),
          Text(
            tender.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 16,
            runSpacing: 10,
            children: [
              _metaItem(Icons.calendar_today_outlined, 'Posted ${_formatDate(tender.postedAt)}'),
              _metaItem(Icons.location_on_outlined, tender.locationName),
              _metaItem(Icons.account_balance_wallet_outlined, 'Budget: ${_formatBudget(tender.maxBudget)}'),
            ],
          ),
          const SizedBox(height: 20),
          if (imageUrls.isNotEmpty) ...[
            _imageSection(imageUrls),
            const SizedBox(height: 24),
          ],
          const Text(
            'Project Description',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            (tender.description ?? 'No description provided.').trim(),
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBidSection(TenderDto tender) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF2),
        border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 1.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Form(
        key: _bidFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionLabel(
              icon: Icons.gavel_rounded,
              label: 'Your Bid',
            ),
            const SizedBox(height: 12),
            const Text(
              'Send a Bid',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Submit your offer for "${tender.title}".',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _priceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              decoration: const InputDecoration(
                labelText: 'Offered price (KM)',
                hintText: 'e.g. 12500.00',
              ),
              validator: (value) {
                final normalized = (value ?? '').replaceAll(',', '.').trim();
                if (normalized.isEmpty) {
                  return 'Offered price is required.';
                }
                final parsed = double.tryParse(normalized);
                if (parsed == null || parsed <= 0) {
                  return 'Enter a valid price greater than 0.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _deliveryDaysController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Delivery days (optional)',
                hintText: 'e.g. 30',
              ),
              validator: (value) {
                final text = (value ?? '').trim();
                if (text.isEmpty) return null;
                final parsed = int.tryParse(text);
                if (parsed == null || parsed <= 0) {
                  return 'Delivery days must be a positive number.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _proposalController,
              minLines: 4,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'Proposal (optional)',
                hintText: 'Describe your delivery plan, scope, and terms.',
                alignLabelWithHint: true,
              ),
            ),
            if (_bidError != null) ...[
              const SizedBox(height: 12),
              Text(
                _bidError!,
                style: const TextStyle(
                  color: AppColors.error,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmittingBid ? null : () => _submitBid(tender),
                child: _isSubmittingBid
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Submit bid'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitBid(TenderDto tender) async {
    if (!_bidFormKey.currentState!.validate()) {
      return;
    }

    final normalizedPrice = _priceController.text.replaceAll(',', '.').trim();
    final offeredPrice = double.parse(normalizedPrice);
    final proposalText = _proposalController.text.trim();

    setState(() {
      _isSubmittingBid = true;
      _bidError = null;
    });

    try {
      await _bidService.create(
        BidInsertRequest(
          tenderId: tender.id,
          price: offeredPrice,
          note: proposalText.isEmpty ? null : proposalText,
        ),
      );

      if (!mounted) return;

      _priceController.clear();
      _proposalController.clear();
      _deliveryDaysController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bid sent successfully.')),
      );

      setState(() {
        _tenderFuture = _loadTender(tender.id);
      });
    } on BidAlreadyExistsException catch (e) {
      if (!mounted) return;
      setState(() {
        _bidError = e.message;
      });
    } on BidServiceException catch (e) {
      if (!mounted) return;
      setState(() {
        _bidError = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _bidError = 'Could not submit bid. Please try again.';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isSubmittingBid = false;
      });
    }
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
          child: SizedBox(
            height: 220,
            width: double.infinity,
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
        ],
      ],
    );
  }

  List<String> _extractImageUrls(TenderDto tender) {
    return tender.images
        .map((img) => DioClient.resolveImageUrl(img.imageUrl.trim()))
        .whereType<String>()
        .where((url) => url.isNotEmpty)
        .toList();
  }

  String _formatDate(DateTime date) => '${date.day} ${_months[date.month - 1]} ${date.year}';

  String _formatBudget(double value) =>
      '${value.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} KM';

  static const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            letterSpacing: 0.6,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
}