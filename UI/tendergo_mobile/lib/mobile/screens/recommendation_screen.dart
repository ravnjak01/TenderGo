import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:tendergo/mobile/routes/routes.dart';
import 'package:tendergo/shared/core/actions/back_button.dart';
import 'package:tendergo/mobile/widgets/tender/tender_recommendation_card_widget.dart';
import '../../shared/providers/recommendation_provider.dart';

class RecommendedForYouMobileScreen extends StatefulWidget {
  final void Function(int tenderId)? onTenderTapped;

  const RecommendedForYouMobileScreen({
    super.key,
    this.onTenderTapped,
  });

  @override
  State<RecommendedForYouMobileScreen> createState() =>
      _RecommendedForYouMobileScreenState();
}

class _RecommendedForYouMobileScreenState extends State<RecommendedForYouMobileScreen> {
  static const _storage = FlutterSecureStorage();
  late final RecommendationProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = RecommendationProvider();
    _loadRecommendations();
  }
Future<void> _loadRecommendations() async {
    // Čist poziv, provajder i servis sami rješavaju autorizaciju u pozadini
    await _provider.loadForUser();
  }

  Future<void> _refresh() async {
    await _provider.loadForUser();
  }

  @override
  void dispose() {
    _provider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _provider,
      child: Scaffold(
        appBar: AppBar(
          leading: const CustomBackButton(),
        title: Flexible(
  child: Text(
    'Recommended For You',
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
  ),
),
          actions: [
            Consumer<RecommendationProvider>(
              builder: (_, provider, _) => IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: provider.isLoading ? null : _refresh,
              ),
            ),
          ],
        ),
        body: Consumer<RecommendationProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Finding tenders for you...'),
                  ],
                ),
              );
            }

            if (provider.state == RecommendationState.error) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 12),
                    Text(provider.errorMessage ?? 'Something went wrong'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _refresh,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            if (!provider.hasData) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.explore_outlined, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No recommendations yet',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Browse and bid on tenders\nto get personalized suggestions.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            // Čisti mobilni prikaz sa Pull-to-Refresh i listom
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                itemCount: provider.recommendations.length,
                itemBuilder: (context, index) {
                  final rec = provider.recommendations[index];
                  return TenderRecommendationCard(
                    tender: rec,
                    onTap: () {
                      widget.onTenderTapped?.call(rec.tenderId);
                      if (widget.onTenderTapped == null) {
                        Navigator.of(context).pushNamed(
                          AppRoutes.tenderDetails,
                          arguments: rec.tenderId,
                        );
                      }
                    },
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}