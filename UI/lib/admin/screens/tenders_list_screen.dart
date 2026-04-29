import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tendergo/shared/providers/tender_provider.dart';
import 'package:tendergo/shared/services/tender_service.dart';
import 'package:tendergo/shared/widgets/feedback/screen_state_widget.dart';
import 'package:tendergo/shared/widgets/tender/filter_bar_widget.dart';
import 'package:tendergo/shared/widgets/tender/grid_widget.dart';
import 'package:tendergo/shared/widgets/tender/search_bar_widget.dart';

class AdminTenderListScreen extends StatefulWidget {
  final TenderService tenderService;
  final bool embedded;
  final ValueChanged<int>? onTenderSelected;

  const AdminTenderListScreen({
    super.key,
    required this.tenderService,
    this.embedded = false,
    this.onTenderSelected,
  });

  @override
  State<AdminTenderListScreen> createState() => _AdminTenderListScreenState();
}

class _AdminTenderListScreenState extends State<AdminTenderListScreen> {
  Timer? _pollingTimer;
  Timer? _debounce;
  static const _pollingInterval = Duration(minutes: 5);
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<TenderProvider>();
      provider.fetchActiveTenders();
      provider.fetchCategories();
      _startPolling();
    });
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(_pollingInterval, (_) {
      if (!mounted) return;
      final provider = context.read<TenderProvider>();
      if (!provider.isSearchActive) {
        provider.fetchActiveTenders();
      }
    });
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      final provider = context.read<TenderProvider>();
      if (query.trim().isEmpty) {
        provider.clearSearch();
        provider.fetchActiveTenders();
      } else {
        provider.searchTenders(query);
      }
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF4F2EB),
      child: _buildBody(),
    );
  }

  Widget _buildBody() {
    return Consumer<TenderProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && !provider.isSearchActive) {
          return const ScreenLoadingState();
        }

        if (provider.error != null && provider.filteredTenders.isEmpty) {
          return ScreenErrorState(
            message: provider.error!,
            onRetry: () => context.read<TenderProvider>().fetchActiveTenders(),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TenderSearchBar(
                controller: _searchController,
                onChanged: _onSearchChanged,
                onClear: () {
                  _searchController.clear();
                  _onSearchChanged('');
                },
                isLoading: provider.isLoading && provider.isSearchActive,
              ),
              const SizedBox(height: 8),
              TenderFilterBar(tenderCount: provider.filteredTenders.length),
              TenderGrid(
                tenders: provider.filteredTenders,
                tenderService: widget.tenderService,
                onTenderSelected: widget.onTenderSelected,
              ),
            ],
          ),
        );
      },
    );
  }
}