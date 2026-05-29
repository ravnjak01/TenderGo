import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:tendergo/shared/core/actions/back_button.dart';
import 'package:tendergo/shared/providers/recommendation_provider.dart';
import 'package:tendergo/shared/routes/routes.dart';
import 'package:tendergo/shared/widgets/tender/tender_recommendation_card_widget.dart';

const double _kMaxContentWidth = 1100;

class RecommendedForYouDesktopScreen extends StatefulWidget {
  final void Function(int tenderId)? onTenderTapped;

  const RecommendedForYouDesktopScreen({
    super.key,
    this.onTenderTapped,
  });

  @override
  State<RecommendedForYouDesktopScreen> createState() =>
      _RecommendedForYouDesktopScreenState();
}

class _RecommendedForYouDesktopScreenState extends State<RecommendedForYouDesktopScreen> {
  static const _storage = FlutterSecureStorage();
  late final RecommendationProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = RecommendationProvider();
    _loadRecommendations();
  }

  Future<void> _loadRecommendations() async {
    final token = await _storage.read(key: 'jwt_token') ?? '';
    await _provider.loadForUser(authToken: token);
  }

  Future<void> _refresh() async {
    final token = await _storage.read(key: 'jwt_token') ?? '';
    await _provider.loadForUser(authToken: token);
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
          title: const Text('Recommended For You'),
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

            // Čisti desktop prikaz sa GridView i ConstrainedBox-om
            return RefreshIndicator(
              onRefresh: _refresh,
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: _kMaxContentWidth),
                  child: GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      mainAxisExtent: 390,
                    ),
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
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}