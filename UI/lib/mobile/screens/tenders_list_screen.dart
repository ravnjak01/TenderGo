import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tendergo/admin/app.dart';
import 'package:tendergo/mobile/widgets/tender_widget.dart';
import 'package:tendergo/shared/controllers/tender_list_controller.dart';
import 'package:tendergo/shared/models/dto/tender_dto.dart';
import 'package:tendergo/shared/models/enums/tenderstatus.dart';
import 'package:tendergo/shared/providers/auth_provider.dart';
import 'package:tendergo/shared/providers/tender_provider.dart';
import 'package:tendergo/shared/routes/nav_observer.dart';
import 'package:tendergo/shared/services/tender_service.dart';
import 'package:tendergo/shared/widgets/common/app_dialogs.dart';
import 'package:tendergo/shared/widgets/feedback/screen_state_widget.dart';
import 'package:tendergo/shared/widgets/feedback/snackbar_helper.dart';
import 'package:tendergo/shared/widgets/tender/filter_bar_widget.dart';
import 'package:tendergo/shared/widgets/tender/search_bar_widget.dart';

class MobileTenderListScreen extends StatefulWidget {
  final TenderService tenderService;
  final bool embedded;
  final ValueChanged<int>? onTenderSelected;

  const MobileTenderListScreen({
    super.key,
    required this.tenderService,
    this.embedded = false,
    this.onTenderSelected,
  });

  @override
  State<MobileTenderListScreen> createState() => _MobileTenderListScreenState();
}

class _MobileTenderListScreenState extends State<MobileTenderListScreen>   with RouteAware {
  final TenderListController _controller = TenderListController();
  bool _initialLoadDone = false;


  @override
 void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }


//zadnje dodao dispose i didpopnext i route observer u app.dart
//ne ažurira bookmark znak kad uklonim bookmark u mobile_bookmarked ekranu
  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    debugPrint("--- DID POP NEXT FIRED SUCCESSFULLY ---");
    _refreshBookmarks();
  }


Future<void> _refreshBookmarks() async {
  if (!mounted) return;
  await context.read<TenderProvider>().loadBookmarks(widget.tenderService);
  if(mounted)
  {
    setState(() {
      
    });
  }
}
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initialLoad());
  }

Future<void> _initialLoad() async {
  if (!mounted) return;
  context.read<AuthProvider>().loadUser();
  final p = Provider.of<TenderProvider>(context, listen: false);
  
  await Future.wait([
    p.fetchActiveTenders(),
    p.fetchCategories(),
    p.loadBookmarks(widget.tenderService), // <-- Poziv providera
  ]);

  if (mounted) {
    setState(() => _initialLoadDone = true);
  }
}


 Future<void> _loadTenders() async {
  await context.read<TenderProvider>().fetchActiveTenders();
  
}

  void _onSearchChanged(String query) {
    final provider = context.read<TenderProvider>();
    if (query.isEmpty) {
      provider.clearSearch();
    } else {
      _controller.onSearchChanged(
        query,
        onClear: () => provider.clearSearch(),
        onSearch: (q) => provider.searchTenders(q),
      );
    }
  }


  void _openTender(TenderDto tender) {
    if (widget.onTenderSelected != null) {
      widget.onTenderSelected!(tender.id);
    }
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

 Future<void> _toggleSave(TenderDto dto) async {
    try {
      // Iskoristi widget.tenderService da pristupiš servisu iz gornje klase
      final isBookmarked = await widget.tenderService.toggleBookmark(dto.id);

     setState(() {
      if (isBookmarked) {
        context.read<TenderProvider>().updateBookmarkLocal(dto.id, true);
      } else {
        context.read<TenderProvider>().updateBookmarkLocal(dto.id, false);
      }
    });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isBookmarked ? 'Tender sačuvan!' : 'Tender uklonjen iz sačuvanih.'),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Greška prilikom spašavanja: $e')),
        );
      }
    }
  }



  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<AuthProvider>().isAdmin;

    return Consumer<TenderProvider>(
      builder: (context, provider, child) {
        if (!_initialLoadDone && provider.isLoading) {
          return const ScreenLoadingState(message: 'Loading tenders...');
        }

        if (provider.error != null && provider.tenders.isEmpty) {
          return ScreenErrorState(
            message: provider.error!,
            onRetry: _loadTenders,
          );
        }

        final filtered = provider.filteredTenders;
        final isSearching = _controller.searchController.text.isNotEmpty;

        return Container(
          color: const Color(0xFFF4F2EB),
          child: RefreshIndicator(
            onRefresh: _loadTenders,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TenderSearchBar(
                          controller: _controller.searchController,
                          onChanged: _onSearchChanged,
                          onClear: () => _controller.clearSearch(
                            () => provider.clearSearch(),
                          ),
                          isLoading: provider.isLoading,
                        ),
                        const SizedBox(height: 10),
                        // ↓ TenderFilterBar replaces category chips + count text
                        TenderFilterBar(
                          tenderCount: filtered.length,
                          useDropdown: true,
                        ),
                      ],
                    ),
                  ),
                ),
                if (filtered.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: isSearching
                        ? ScreenEmptyState(
                            icon: Icons.search_off_rounded,
                            title: 'No results found',
                            description: 'Try different keywords.',
                            actionLabel: 'Clear search',
                            onAction: () => _controller.clearSearch(
                              () => provider.clearSearch(),
                            ),
                          )
                        : ScreenEmptyState(
                            icon: Icons.filter_alt_off_rounded,
                            title: 'No matches found',
                            description:
                                'Try a different category or location filter.',
                            actionLabel: 'Clear filters',
                            onAction: () {
                              provider.toggleCategory('All');
                              provider.clearLocationFilter();
                            },
                          ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    sliver: SliverList.separated(
                      itemBuilder: (context, index) {
                        final dto = filtered[index];
                        final model = dto.toCardModel();

                        return MobileTenderCardWidget(
                          tender: model,
                          isSaved: provider.savedIds.contains(dto.id),
                          onTap: () => _openTender(dto),
                          onSave: () => _toggleSave(dto),
                          onCancelTender: isAdmin &&
                                  dto.status == TenderStatus.open
                              ? () => _cancelTender(dto)
                              : null,
                        );
                      },
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemCount: filtered.length,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}