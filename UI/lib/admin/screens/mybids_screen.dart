import 'package:flutter/material.dart';
import 'package:tendergo/shared/models/dto/bid_dto.dart';
import 'package:tendergo/shared/services/bid_service.dart';
import 'package:tendergo/shared/widgets/feedback/screen_state_widget.dart';

class MyBidsScreen extends StatefulWidget {
  final BidService _bidService; 
  const MyBidsScreen({super.key, required BidService bidService}) : _bidService = bidService;

  @override
  State<MyBidsScreen> createState() => _MyBidsScreenState();
}

class _MyBidsScreenState extends State<MyBidsScreen> {
  // ── state ──────────────────────────────────────────────────────────────────
  final List<BidDto> _bids = [];
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';
  bool _hasMore = true;

  int _currentPage = 1;
  static const int _pageSize = 10;

  final ScrollController _scrollController = ScrollController();

  
  // ── lifecycle ──────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _fetchBids();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // ── data fetching ──────────────────────────────────────────────────────────
  Future<void> _fetchBids({bool refresh = false}) async {
    if (_isLoading) return;
    if (refresh) {
      setState(() {
        _currentPage = 1;
        _bids.clear();
        _hasMore = true;
        _hasError = false;
      });
    }

    setState(() => _isLoading = true);

    try {
      final fetched = await widget._bidService.getAll(
        page: _currentPage,
        pageSize: _pageSize,
      );


      setState(() {
        _bids.addAll(fetched);
        _hasMore = fetched.length == _pageSize;
        _currentPage++;
        _hasError = false;
      });
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        _hasMore) {
      _fetchBids();
    }
  }

  // ── build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'My Bids',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () => _fetchBids(refresh: true),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _buildBody(colorScheme),
    );
  }

  Widget _buildBody(ColorScheme colorScheme) {
    if (_hasError && _bids.isEmpty) {
      return ScreenErrorState(
        message: _errorMessage,
        onRetry: () => _fetchBids(refresh: true),
      );
    }

    if (_isLoading && _bids.isEmpty) {
      return const ScreenLoadingState();
    }

    if (_bids.isEmpty) {
      return ScreenEmptyState(
        icon: Icons.gavel_rounded,
        title: 'No bids yet',
        description: 'Bids you submit will appear here.',
        onAction: () => _fetchBids(refresh: true),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _fetchBids(refresh: true),
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: _bids.length + (_hasMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index >= _bids.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return _BidCard(bid: _bids[index]);
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bid Card
// ─────────────────────────────────────────────────────────────────────────────

class _BidCard extends StatelessWidget {
  const _BidCard({required this.bid});

  final BidDto bid;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 360;

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: colorScheme.outlineVariant, width: 1),
          ),
          color: colorScheme.surfaceContainerLowest,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              // Navigate to bid detail page
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── header ───────────────────────────────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _BidAvatar(bidId: bid.id),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              bid.tenderDisplayTitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (isCompact) ...[
                              const SizedBox(height: 8),
                              _StatusChip(status: bid.status),
                            ],
                          ],
                        ),
                      ),
                      if (!isCompact) ...[
                        const SizedBox(width: 8),
                        _StatusChip(status: bid.status),
                      ],
                    ],
                  ),

                  const SizedBox(height: 14),
                  Divider(
                    height: 1,
                    thickness: 5,
                    color: colorScheme.outlineVariant,
                  ),
                  const SizedBox(height: 14),

                  // ── proposal preview ────────────────────────────────────
                  if (bid.proposal != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        bid.proposal!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // ── meta row ────────────────────────────────────────────
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      _MetaItem(
                        icon: Icons.schedule_rounded,
                        label: _timeAgo(bid.submittedAt),
                      ),
                      if (bid.deliveryDays != null)
                        _MetaItem(
                          icon: Icons.local_shipping_rounded,
                          label: '${bid.deliveryDays} days delivery',
                        ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // ── price ───────────────────────────────────────────────
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Offered Price',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        '${bid.offeredPrice.toStringAsFixed(0)} KM',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    return '${diff.inMinutes}m ago';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _BidAvatar extends StatelessWidget {
  const _BidAvatar({required this.bidId});

  final int bidId;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Icon(
          Icons.gavel_rounded,
          color: colorScheme.onTertiaryContainer,
          size: 24,
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final lower = status.toLowerCase();

    Color bg;
    Color fg;

    if (lower == 'accepted') {
      bg = Colors.green.shade100;
      fg = Colors.green.shade800;
    } else if (lower == 'rejected') {
      bg = colorScheme.errorContainer;
      fg = colorScheme.onErrorContainer;
    } else if (lower == 'withdrawn') {
      bg = colorScheme.surfaceContainerHigh;
      fg = colorScheme.onSurfaceVariant;
    } else {
      // pending or unknown
      bg = Colors.amber.shade100;
      fg = Colors.amber.shade900;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  const _MetaItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}
