import 'package:flutter/material.dart';
import 'package:tendergo/shared/core/theme/app_theme.dart';
import 'package:tendergo/shared/models/dto/tender_dto.dart';
import 'package:tendergo/shared/services/bid_service.dart';
import 'package:tendergo/shared/services/dio_client.dart';
import 'package:tendergo/shared/services/tender_service.dart';
import 'package:tendergo/shared/widgets/feedback/screen_state_widget.dart';
import 'package:tendergo/shared/widgets/tender/tender_bid_form.dart';
import 'package:tendergo/shared/widgets/tender/tender_description_card.dart';
import 'package:tendergo/shared/widgets/tender/tender_details_meta_card.dart';
import 'package:tendergo/shared/widgets/tender/tender_info_section.dart';
import 'package:tendergo/shared/widgets/tender/tender_poster_card.dart';

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

  @override
  void initState() {
    super.initState();
    _bidService = BidService(DioClient.getDio());
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
    if (_tenderFuture == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(child: Text('Missing tender id.')),
      );
    }

    if (widget.embedded) {
      return _buildEmbeddedView();
    }

    return _buildFullScreenView();
  }

  Widget _buildEmbeddedView() {
    return FutureBuilder<TenderDto>(
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
        return SingleChildScrollView(child: _buildContent(snapshot.data!));
      },
    );
  }

  Widget _buildFullScreenView() {
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
              message: snapshot.error?.toString() ?? 'Could not load tender details.',
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
              SliverToBoxAdapter(child: _buildContent(tender)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildContent(TenderDto tender) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title and overview
          TenderInfoSection(tender: tender, imageHeight: 220),
          const SizedBox(height: 20),

          // Description
          TenderDescriptionCard(description: tender.description),
          const SizedBox(height: 20),

          // Detailed meta information
          TenderDetailsMetaCard(tender: tender),
          const SizedBox(height: 20),

          // Poster information
          TenderPosterCard(tender: tender),
          const SizedBox(height: 24),

          // Bid section divider
          Row(
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
          const SizedBox(height: 24),

          // Bid form
          TenderBidForm(
            tender: tender,
            bidService: _bidService,
            onBidSuccess: () =>
                setState(() => _tenderFuture = _loadTender(tender.id)),
          ),
          const SizedBox(height: 24),
        ],
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
}
