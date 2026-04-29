import 'package:flutter/material.dart';
import 'package:tendergo/shared/core/theme/app_theme.dart';
import 'package:tendergo/shared/models/dto/tender_dto.dart';
import 'package:tendergo/shared/routes/routes.dart';
import 'package:tendergo/shared/services/bid_service.dart';
import 'package:tendergo/shared/services/dio_client.dart';
import 'package:tendergo/shared/services/tender_service.dart';
import 'package:tendergo/shared/widgets/feedback/screen_state_widget.dart';
import 'package:tendergo/shared/widgets/tender/tender_bid_form.dart';
import 'package:tendergo/shared/widgets/tender/tender_info_section.dart';

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

  Widget _buildCreatorSection(TenderDto tender) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          final userId = tender.createdByUserId.trim();
          if (userId.isEmpty) return;
          Navigator.of(context).pushNamed(
            AppRoutes.userPublicProfile,
            arguments: userId,
          );
        },
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.outline),
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.primary.withValues(alpha: 0.14),
                child: Text(
                  _creatorInitials(tender.createdByFullname),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tender.createdByFullname,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'View creator profile',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
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

              return SingleChildScrollView(
                child: Container(
                  color: AppColors.surface,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TenderInfoCard(tender: tender, imageHeight: 220),
                      const SizedBox(height: 16),
                      _buildCreatorSection(tender),
                      const SizedBox(height: 16),
                      TenderBidForm(
                        tender: tender,
                        bidService: _bidService,
                        onBidSuccess: () => setState(
                          () => _tenderFuture = _loadTender(tender.id),
                        ),
                      ),
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
}