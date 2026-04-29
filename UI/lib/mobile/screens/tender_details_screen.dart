import 'package:flutter/material.dart';
import 'package:tendergo/shared/core/theme/app_theme.dart';
import 'package:tendergo/shared/models/dto/tender_dto.dart';
import 'package:tendergo/shared/routes/routes.dart';
import 'package:tendergo/shared/services/bid_service.dart';
import 'package:tendergo/shared/services/dio_client.dart';
import 'package:tendergo/shared/services/tender_service.dart';
import 'package:tendergo/shared/widgets/feedback/screen_state_widget.dart';
import 'package:tendergo/shared/widgets/tender/tender_bid_form.dart';
import 'package:tendergo/shared/widgets/tender/tender_detail_formatters.dart';
import 'package:tendergo/shared/widgets/tender/tender_image_gallery.dart';

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
  State<MobileTenderDetailsScreen> createState() =>
      _MobileTenderDetailsScreenState();
}

class _MobileTenderDetailsScreenState extends State<MobileTenderDetailsScreen> {
  Future<TenderDto>? _tenderFuture;
  bool _initialized = false;
  int? _resolvedTenderId;
  late final BidService _bidService;
  late PageController _imagePageController;
  int _currentImagePage = 0;

  @override
  void initState() {
    super.initState();
    _bidService = BidService(DioClient.getDio());
    _imagePageController = PageController();
  }

  @override
  void dispose() {
    _imagePageController.dispose();
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

  String _creatorInitials(String fullName) {
    final parts = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList(growable: false);

    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  Widget _buildImageGallery(TenderDto tender) {
    final imageUrls = extractTenderImageUrls(tender);
    if (imageUrls.isEmpty) {
      return Container(
        height: 220,
        color: AppColors.surfaceVariant,
        child: const Center(
          child: Icon(Icons.image_not_supported_outlined, size: 48),
        ),
      );
    }

    return SizedBox(
      height: 220,
      child: Stack(
        children: [
          PageView.builder(
            controller: _imagePageController,
            onPageChanged: (idx) => setState(() => _currentImagePage = idx),
            itemCount: imageUrls.length,
            itemBuilder: (context, idx) {
              return Image.network(
                imageUrls[idx],
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: AppColors.surfaceVariant,
                  child: const Icon(Icons.broken_image_outlined),
                ),
              );
            },
          ),
          // Badge: Image count
          Positioned(
            top: 14,
            right: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Text(
                '${_currentImagePage + 1} / ${imageUrls.length}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: const Color.fromARGB(255, 255, 255, 255),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          // Pagination dots
          Positioned(
            bottom: 10,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                imageUrls.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 6,
                  width: i == _currentImagePage ? 18 : 6,
                  decoration: BoxDecoration(
                    color: i == _currentImagePage
                        ? Colors.white
                        : Colors.white38,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleSection(TenderDto tender) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        tender.title,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w800,
          height: 1.25,
        ),
      ),
    );
  }

  Widget _buildDescriptionSection(TenderDto tender) {
    final description = (tender.description ?? 'No description provided.')
        .trim();
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: _buildSectionCard(
        'Description',
        child: Text(
          description,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
            height: 1.6,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard(String label, {required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildTenderInfoSection(TenderDto tender) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: _buildSectionCard(
        'Tender Info',
        child: Column(
          children: [
            _buildDetailRow(
              Icons.account_balance_wallet_outlined,
              'Budget',
              formatTenderBudget(tender.maxBudget),
            ),
            _buildDetailRow(
              Icons.location_on_outlined,
              'Location',
              tender.locationName,
            ),
            _buildDetailRow(
              Icons.work_outline,
              'Category',
              tender.categoryName,
            ),
            _buildDetailRow(
              Icons.access_time,
              'Posted',
              formatTenderDate(tender.postedAt),
            ),
            _buildDetailRow(
              Icons.calendar_today_outlined,
              'Deadline',
              formatTenderDate(tender.deadline),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(color: AppColors.outline, height: 1),
            ),
            _buildPosterRow(tender),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String key,
    String val, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Text(
            key,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
          const Spacer(),
          Text(
            val,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: valueColor ?? AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPosterRow(TenderDto tender) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          final userId = tender.createdByUserId.trim();
          if (userId.isEmpty) return;
          Navigator.of(
            context,
          ).pushNamed(AppRoutes.userPublicProfile, arguments: userId);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.primary.withOpacity(0.2),
                    child: Text(
                      _creatorInitials(tender.createdByFullname),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      tender.createdByFullname,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 46),
                child: Text(
                  'Posted by',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_tenderFuture == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(child: Text('Missing tender id.')),
      );
    }

    if (widget.embedded) {
      return FutureBuilder<TenderDto>(
        future: _tenderFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const ScreenLoadingState();
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return ScreenErrorState(
              message:
                  snapshot.error?.toString() ??
                  'Could not load tender details.',
              onRetry: () {
                final id = _resolvedTenderId;
                if (id == null) return;
                setState(() => _tenderFuture = _loadTender(id));
              },
            );
          }
          final tender = snapshot.data!;
          return SingleChildScrollView(child: _buildContent(tender));
        },
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: FutureBuilder<TenderDto>(
        future: _tenderFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const ScreenLoadingState();
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return ScreenErrorState(
              message:
                  snapshot.error?.toString() ??
                  'Could not load tender details.',
              onRetry: () {
                final id = _resolvedTenderId;
                if (id == null) return;
                setState(() => _tenderFuture = _loadTender(id));
              },
            );
          }
          final tender = snapshot.data!;

          return CustomScrollView(
            slivers: [
              // App Bar
              SliverAppBar(
                pinned: true,
                elevation: 0,
                backgroundColor: AppColors.background.withOpacity(0.88),
                leading: _buildHeaderIcon(
                  Icons.arrow_back_ios_rounded,
                  () => Navigator.of(context).pop(),
                ),
                title: const Text('Tender Details'),
               
              ),
              // Content
              SliverToBoxAdapter(child: _buildContent(tender)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeaderIcon(IconData icon, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.outline),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Icon(icon, size: 18),
        ),
      ),
    );
  }

  Widget _buildContent(TenderDto tender) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image gallery
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: _buildImageGallery(tender),
            ),
            // Title section
            _buildTitleSection(tender),
            // Description
            _buildDescriptionSection(tender),
            // Tender info
            _buildTenderInfoSection(tender),
            // Divider with "PLACE YOUR BID"
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Row(
                children: [
                  const Expanded(child: Divider(color: AppColors.outline)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'PLACE YOUR BID',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textSecondary,
                        letterSpacing: 1,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider(color: AppColors.outline)),
                ],
              ),
            ),
            // Your Proposal form
            _buildSectionCard(
              'Your Proposal',
              child: TenderBidForm(
                tender: tender,
                bidService: _bidService,
                onBidSuccess: () =>
                    setState(() => _tenderFuture = _loadTender(tender.id)),
              ),
            ),
           
          ],
        ),
      ),
    );
  }
}
