import 'package:flutter/material.dart';
import 'package:tendergo/shared/core/theme/app_theme.dart';
import 'package:tendergo/shared/models/dto/tender_dto.dart';
import 'package:tendergo/shared/services/bid_service.dart';
import 'package:tendergo/shared/services/dio_client.dart';
import 'package:tendergo/shared/services/tender_service.dart';
import 'package:tendergo/shared/widgets/feedback/screen_state_widget.dart';
import 'package:tendergo/shared/widgets/tender/tender_bid_form.dart';
import 'package:tendergo/shared/widgets/tender/tender_info_section.dart';

class AdminTenderDetailsScreen extends StatefulWidget {
  final TenderService tenderService;
  final int? tenderId;
  final bool embedded;

  const AdminTenderDetailsScreen({
    super.key,
    required this.tenderService,
    this.tenderId,
    this.embedded = false,
  });

  @override
  State<AdminTenderDetailsScreen> createState() => _AdminTenderDetailsScreenState();
}

class _AdminTenderDetailsScreenState extends State<AdminTenderDetailsScreen> {
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

              return LayoutBuilder(
                builder: (context, constraints) {
                  final bool isWide = constraints.maxWidth >= 980;

                  return SingleChildScrollView(
                    child: Container(
                      color: AppColors.surface,
                      padding: const EdgeInsets.all(24),
                      child: isWide
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: TenderInfoSection(
                                    tender: tender,
                                    imageHeight: 320,
                                    titleStyle: Theme.of(context)
                                        .textTheme
                                        .headlineMedium
                                        ?.copyWith(
                                          color: AppColors.textPrimary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ),
                                const SizedBox(width: 24),
                                Expanded(
                                  child: TenderBidForm(
                                    tender: tender,
                                    bidService: _bidService,
                                    onBidSuccess: () => setState(
                                      () => _tenderFuture = _loadTender(tender.id),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TenderInfoSection(
                                  tender: tender,
                                  imageHeight: 320,
                                  titleStyle: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                const SizedBox(height: 24),
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