import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tendergo/mobile/widgets/tender/tender_widget.dart';
import 'package:tendergo/shared/controllers/tender_list_controller.dart';
import 'package:tendergo/shared/models/dto/tender_dto.dart';
import 'package:tendergo/shared/models/enums/tenderstatus.dart';
import 'package:tendergo/shared/providers/auth_provider.dart';
import 'package:tendergo/shared/providers/tender_provider.dart';
import 'package:tendergo/mobile/routes/nav_observer.dart';
import 'package:tendergo/shared/services/tender_service.dart';
import 'package:tendergo/mobile/widgets/common/app_dialogs.dart';
import 'package:tendergo/mobile/widgets/feedback/screen_state_widget.dart';
import 'package:tendergo/mobile/widgets/feedback/snackbar_helper.dart';
import 'package:tendergo/mobile/widgets/tender/filter_bar_widget.dart';
import 'package:tendergo/mobile/widgets/tender/search_bar_widget.dart';

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

class _MobileTenderListScreenState extends State<MobileTenderListScreen> with RouteAware {
  final TenderListController _controller = TenderListController();
  final ScrollController _scrollController = ScrollController();
  bool _initialLoadDone = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _initialLoad());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.extentAfter > 300) return;

    final provider = context.read<TenderProvider>();
    if (provider.isSearchActive || provider.isLoadingMore || provider.isLoading || !provider.hasMore) {
      return;
    }

    provider.fetchNextPage();
  }

  @override
  void didPopNext() {
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
Future<void> _initialLoad() async {
  if (!mounted) return;
  final p = Provider.of<TenderProvider>(context, listen: false);
  
  await Future.wait([
    p.fetchActiveTenders(),
    p.fetchCategories(),
    p.loadBookmarks(widget.tenderService), 
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
      _controller.cancelDebounce();
      provider.clearSearch();
    } else {
      _controller.onSearchChanged(
        query,
        onClear: () => provider.clearSearch(),
        onSearch: (q) => provider.searchTenders(q),
      );
    }
  }

  void _onSearchSubmitted(String query) {
    final trimmed = query.trim();
    final provider = context.read<TenderProvider>();
    if (trimmed.isEmpty) {
      provider.clearSearch();
      return;
    }

    provider.searchTenders(trimmed);
    provider.logSearchActivity(trimmed);
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
            content: Text(isBookmarked ? 'Tender saved!' : 'Tender removed from saved.'),
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

        final hasMoreItems = !isSearching && provider.hasMore;

        return Container(
          color: const Color(0xFFF4F2EB),
          child: RefreshIndicator(
            onRefresh: _loadTenders,
            child: CustomScrollView(
              controller: _scrollController,
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
                          onSubmitted: _onSearchSubmitted,
                          onClear: () => _controller.clearSearch(
                            () => provider.clearSearch(),
                          ),
                          isLoading: provider.isLoading,
                        ),
                        const SizedBox(height: 10),
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
                              provider.toggleCategory('All ');
                              provider.clearLocationFilter();
                            },
                          ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    sliver: SliverList.separated(
                      itemBuilder: (context, index) {
                        if (index >= filtered.length) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: Center(
                              child: provider.isLoadingMore
                                  ? const CircularProgressIndicator()
                                  : FilledButton.tonalIcon(
                                      onPressed: provider.fetchNextPage,
                                      icon: const Icon(Icons.expand_more_rounded),
                                      label: const Text('Load more'),
                                    ),
                            ),
                          );
                        }

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
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemCount: filtered.length + (hasMoreItems ? 1 : 0),
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
