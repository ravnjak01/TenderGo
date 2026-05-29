import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:tendergo/shared/models/dto/tenderrecommendation_dto.dart';
import 'package:tendergo/shared/routes/routes.dart';
import 'package:tendergo/shared/services/dio_client.dart';
import 'package:tendergo/shared/services/recommendation_service.dart';
import 'package:tendergo/shared/widgets/tender/tender_recommendation_card_widget.dart';

class SimilarTendersSection extends StatefulWidget {
  const SimilarTendersSection({
    super.key,
    required this.tenderId,
    this.limit = 4,
    this.onTenderTapped,
  });

  final int tenderId;
  final int limit;
  final ValueChanged<int>? onTenderTapped;

  @override
  State<SimilarTendersSection> createState() => _SimilarTendersSectionState();
}

class _SimilarTendersSectionState extends State<SimilarTendersSection> {
  static const _storage = FlutterSecureStorage();
  late final RecommendationService _service;
  late Future<List<TenderRecommendation>> _future;

  @override
  void initState() {
    super.initState();
    _service = RecommendationService(DioClient.getDio());
    _future = _loadSimilarTenders();
  }

  @override
  void didUpdateWidget(covariant SimilarTendersSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tenderId != widget.tenderId ||
        oldWidget.limit != widget.limit) {
      _future = _loadSimilarTenders();
    }
  }

  Future<List<TenderRecommendation>> _loadSimilarTenders() async {
    final token = await _storage.read(key: 'jwt_token') ?? '';
    return _service.getSimilarTenders(
      tenderId: widget.tenderId,
      authToken: token,
      topN: widget.limit,
    );
  }

  void _openTender(int tenderId) {
    widget.onTenderTapped?.call(tenderId);
    if (widget.onTenderTapped == null) {
      Navigator.of(context).pushNamed(
        AppRoutes.tenderDetails,
        arguments: tenderId,
      );
    }
  }

  void _retry() {
    setState(() {
      _future = _loadSimilarTenders();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FutureBuilder<List<TenderRecommendation>>(
      future: _future,
      builder: (context, snapshot) {
        final isLoading = snapshot.connectionState == ConnectionState.waiting;
        final recommendations = snapshot.data ?? const <TenderRecommendation>[];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Similar tenders',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            if (isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (snapshot.hasError)
              _SimilarTendersMessage(
                icon: Icons.error_outline_rounded,
                title: 'Could not load similar tenders',
                actionLabel: 'Retry',
                onAction: _retry,
              )
            else if (recommendations.isEmpty)
              const _SimilarTendersMessage(
                icon: Icons.manage_search_rounded,
                title: 'No similar tenders yet',
              )
            else
              ...recommendations.map(
                (recommendation) => TenderRecommendationCard(
                  tender: recommendation,
                  onTap: () => _openTender(recommendation.tenderId),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _SimilarTendersMessage extends StatelessWidget {
  const _SimilarTendersMessage({
    required this.icon,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.45),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          Icon(icon, color: theme.colorScheme.primary),
          const SizedBox(height: 8),
          Text(title, textAlign: TextAlign.center),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: onAction,
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}
