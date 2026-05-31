import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:tendergo/shared/core/actions/back_button.dart';
import 'package:tendergo/shared/core/theme/app_theme.dart';
import 'package:tendergo/shared/models/dto/tender_dto.dart';
import 'package:tendergo/shared/services/bid_service.dart';
import 'package:tendergo/shared/services/dio_client.dart';
import 'package:tendergo/shared/services/recommendation_service.dart';
import 'package:tendergo/shared/services/tender_service.dart';
import 'package:tendergo/shared/widgets/feedback/screen_state_widget.dart';
import 'package:tendergo/shared/widgets/tender/similar_tenders_section.dart';
import 'package:tendergo/shared/widgets/tender/tender_bid_form.dart';
import 'package:tendergo/shared/widgets/tender/tender_info_section.dart';
import 'package:tendergo/shared/widgets/tender/tender_description_card.dart';
import 'package:tendergo/shared/widgets/tender/tender_details_meta_card.dart';
import 'package:tendergo/shared/widgets/tender/tender_poster_card.dart';

class AdminTenderDetailsScreen extends StatefulWidget {
  final TenderService tenderService;
  final int? tenderId;
  final bool embedded;
  final VoidCallback? onBack;

  const AdminTenderDetailsScreen({
    super.key,
    required this.tenderService,
    this.tenderId,
    this.embedded = false,
    this.onBack,
  });

  @override
  State<AdminTenderDetailsScreen> createState() =>
      _AdminTenderDetailsScreenState();
}

class _AdminTenderDetailsScreenState extends State<AdminTenderDetailsScreen> {
  static const _storage = FlutterSecureStorage();
  Future<TenderDto>? _tenderFuture;
  bool _initialized = false;
  int? _resolvedTenderId;
  int? _loggedViewTenderId;
  Timer? _viewLogTimer;
  late final BidService _bidService;
  late final RecommendationService _recommendationService;

  @override
  void initState() {
    super.initState();
    _bidService = BidService(DioClient.getDio());
    _recommendationService = RecommendationService(DioClient.getDio());
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

  void _scheduleViewActivity(int tenderId) {
    if (_loggedViewTenderId == tenderId) return;
    _loggedViewTenderId = tenderId;
    _viewLogTimer?.cancel();
    _viewLogTimer = Timer(
      const Duration(seconds: 5),
      () => unawaited(_logViewActivityAsync(tenderId)),
    );
  }

  Future<void> _logViewActivityAsync(int tenderId) async {
    try {
      final token = await _storage.read(key: 'jwt_token') ?? '';
      await _recommendationService.logViewActivity(
        tenderId: tenderId,
        authToken: token,
        durationSeconds: 5,
      );
    } catch (e) {
      debugPrint('Failed to log tender view activity: $e');
    }
  }

  Future<TenderDto> _loadTender(int id) async {
    final dynamic data = await widget.tenderService.getById(id);
    if (data is TenderDto) {
      if (mounted) _scheduleViewActivity(id);
      return data;
    }
    if (data is Map<String, dynamic>) {
      if (mounted) _scheduleViewActivity(id);
      return TenderDto.fromJson(data);
    }
    throw Exception('Unexpected tender payload from backend.');
  }

  @override
  void dispose() {
    _viewLogTimer?.cancel();
    super.dispose();
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
                  message:
                      snapshot.error?.toString() ??
                      'Could not load tender details.',
                  onRetry: () {
                    final id = _resolvedTenderId;
                    if (id == null) return;

                    final newFuture = _loadTender(id);

                    setState(() {
                      _tenderFuture = newFuture;
                    });
                  },
                );
              }

              final tender = snapshot.data!;

              // Uklonjen LayoutBuilder i mobilni layout - sada je fiksni desktop prikaz
              return SingleChildScrollView(
                child: Container(
                  color: AppColors.surface,
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // LIJEVA KOLONA (Glavni detalji o tenderu)
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (widget.embedded) ...[
                              CustomBackButton(onPressed: widget.onBack),
                              const SizedBox(height: 16),
                            ],
                            TenderInfoSection(
                              tender: tender,
                              imageHeight: 320,
                              showDescription: false,
                              titleStyle: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 24),
                            TenderDescriptionCard(
                              description: tender.description,
                            ),
                            const SizedBox(height: 20),
                            TenderDetailsMetaCard(tender: tender),
                            const SizedBox(height: 24),
                            SimilarTendersSection(tenderId: tender.id),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),

                      // DESNA KOLONA (Poster info i Bid forma)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TenderPosterCard(tender: tender),
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
        leading: CustomBackButton(onPressed: widget.onBack),
      ),
      body: content,
    );
  }
}
