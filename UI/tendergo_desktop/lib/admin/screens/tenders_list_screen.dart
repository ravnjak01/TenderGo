import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tendergo/shared/controllers/tender_list_controller.dart';
import 'package:tendergo/shared/models/dto/tender_dto.dart';
import 'package:tendergo/shared/providers/auth_provider.dart';
import 'package:tendergo/shared/providers/tender_provider.dart';
import 'package:tendergo/shared/routes/nav_observer.dart';
import 'package:tendergo/shared/services/tender_service.dart';
import 'package:tendergo/shared/widgets/common/app_dialogs.dart';
import 'package:tendergo/shared/widgets/feedback/screen_state_widget.dart';
import 'package:tendergo/shared/widgets/feedback/snackbar_helper.dart';
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

class _AdminTenderListScreenState extends State<AdminTenderListScreen>
    with RouteAware {
  final TenderListController _controller = TenderListController();

  TenderProvider? _tenderProvider;

 @override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!mounted) return;

    _tenderProvider = context.read<TenderProvider>();
    _tenderProvider!.fetchActiveTenders();
    _tenderProvider!.fetchCategories();


    //context.read<NotificationProvider>().startPolling();
  });
}

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void didPopNext() {
    _tenderProvider?.fetchCategories();
    _tenderProvider?.fetchActiveTenders(silent: true);
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

  void _onSearchSubmitted(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      _tenderProvider?.clearSearch();
      _tenderProvider?.fetchActiveTenders();
      return;
    }

    _tenderProvider?.searchTenders(trimmed);
    _tenderProvider?.logSearchActivity(trimmed);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _cancelTender(TenderDto tender) async {
    final confirmed = await AppDialogs.showConfirm(
      context: context,
      title: 'Cancel tender',
      content: 'Are you sure you want to cancel this tender?',
      cancelLabel: 'No',
      confirmLabel: 'Yes, Cancel',
      isDestructive: true,
    );
    if (!confirmed || !mounted) return;

    final provider = context.read<TenderProvider>();
    final ok = await provider.cancelTender(tender.id);
    if (!mounted) return;

    if (ok) {
      SnackbarHelper.show(context, 'Tender canceled successfully.');
    } else {
      SnackbarHelper.show(
        context,
        provider.error ?? 'Failed to cancel tender',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF4F2EB),
      child: _buildBody(),
    );
  }

  Widget _buildBody() {
    return Consumer2<TenderProvider, AuthProvider>(
      builder: (context, provider, auth, _) {
        final isAdmin = auth.isAdmin;
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
                onSubmitted: _onSearchSubmitted,
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
                showCancelAction: isAdmin,
                onCancelTender: isAdmin ? _cancelTender : null,
              ),
            ],
          ),
        );
      },
    );
  }
}
