import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tendergo/shared/controllers/tender_list_controller.dart';
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
  final TenderListController _controller = TenderListController();

  // Cached provider reference — safe to use in dispose().
  TenderProvider? _tenderProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _tenderProvider = context.read<TenderProvider>();
      _tenderProvider!.fetchActiveTenders();
      _tenderProvider!.fetchCategories();
      _controller.startPolling(() {
        if (!mounted) return;
        if (!_tenderProvider!.isSearchActive) {
          _tenderProvider!.fetchActiveTenders();
        }
      });
    });
  }

  void _onSearchChanged(String query) {
    _controller.onSearchChanged(
      query,
      onClear: () {
        if (!mounted) return;
        _tenderProvider?.clearSearch();
        _tenderProvider?.fetchActiveTenders();
      },
      onSearch: (q) {
        if (!mounted) return;
        _tenderProvider?.searchTenders(q);
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
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
                controller: _controller.searchController,
                onChanged: _onSearchChanged,
                onClear: () => _controller.clearSearch(() {
                  if (!mounted) return;
                  _tenderProvider?.clearSearch();
                  _tenderProvider?.fetchActiveTenders();
                }),
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