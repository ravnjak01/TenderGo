import 'package:flutter/material.dart';
import 'package:tendergo/shared/models/dto/tender_dto.dart';
import 'package:tendergo/shared/models/enums/tenderstatus.dart';
import 'package:tendergo/admin/screens/tender_bids_screen.dart';
import 'package:tendergo/shared/services/auth_service.dart';
import 'package:tendergo/shared/services/tender_service.dart';
import 'package:tendergo/shared/widgets/feedback/screen_state_widget.dart';

class MyTendersScreen extends StatefulWidget {
  final TenderService _tenderService;
  const MyTendersScreen({super.key, required TenderService tenderService})
    : _tenderService = tenderService;

  @override
  State<MyTendersScreen> createState() => _MyTendersScreenState();
}

class _MyTendersScreenState extends State<MyTendersScreen> {
  // ── state ──────────────────────────────────────────────────────────────────
  final List<TenderDto> _tenders = [];
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
    _fetchTenders();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // ── data fetching ──────────────────────────────────────────────────────────
  Future<void> _fetchTenders({bool refresh = false}) async {
    if (_isLoading) return;
    if (refresh) {
      setState(() {
        _currentPage = 1;
        _tenders.clear();
        _hasMore = true;
        _hasError = false;
      });
    }

    setState(() => _isLoading = true);

    try {
      final currentUserId = await AuthService.getCurrentUserId();
      if (currentUserId == null || currentUserId.isEmpty) {
        throw Exception('Could not resolve the current user from the session.');
      }

      final fetchedRaw = await widget._tenderService.getByUser(currentUserId);
      final fetchedDtos = fetchedRaw
          .whereType<Map<String, dynamic>>()
          .map(TenderDto.fromJson)
          .toList();

      if (!mounted) return;

      setState(() {
        if (refresh) {
          _tenders
            ..clear()
            ..addAll(fetchedDtos);
        } else {
          _tenders.addAll(fetchedDtos);
        }
        _hasMore = false;
        _currentPage = 2;
        _hasError = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        _hasMore) {
      _fetchTenders();
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
          'My Tenders',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () => _fetchTenders(refresh: true),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _buildBody(colorScheme),
    );
  }

  Widget _buildBody(ColorScheme colorScheme) {
    // ── initial load error ──────────────────────────────────────────────────
    if (_hasError && _tenders.isEmpty) {
      return ScreenErrorState(
        message: _errorMessage,
        onRetry: () => _fetchTenders(refresh: true),
      );
    }

    // ── initial loading ─────────────────────────────────────────────────────
    if (_isLoading && _tenders.isEmpty) {
      return const ScreenLoadingState();
    }

    // ── empty state ─────────────────────────────────────────────────────────
    if (_tenders.isEmpty) {
      return ScreenEmptyState(
        icon: Icons.inbox_rounded,
        title: 'No tenders yet',
        description: 'Your published tenders will appear here.',
        onAction: () => _fetchTenders(refresh: true),
      );
    }

    // ── list ────────────────────────────────────────────────────────────────
    return RefreshIndicator(
      onRefresh: () => _fetchTenders(refresh: true),
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: _tenders.length + (_hasMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index >= _tenders.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return _TenderCard(
            tender: _tenders[index],
            tenderService: widget._tenderService,
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tender Card
// ─────────────────────────────────────────────────────────────────────────────

class _TenderCard extends StatelessWidget {
  const _TenderCard({required this.tender, required this.tenderService});

  final TenderDto tender;
  final TenderService tenderService;

  @override
  Widget build(BuildContext context) {
    final model = tender.toCardModel(tender);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isOpen = model.status == TenderStatus.open;

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
          // Navigate to tender detail page
          // Navigator.of(context).push(...)
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── header row ────────────────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          model.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          model.category,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _StatusChip(isOpen: isOpen),
                ],
              ),

              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 14),

              // ── meta row ──────────────────────────────────────────────────
              Row(
                children: [
                  _MetaItem(
                    icon: Icons.location_on_rounded,
                    label: model.locationName,
                  ),
                  const SizedBox(width: 16),
                  _MetaItem(
                    icon: Icons.calendar_today_rounded,
                    label: _formatDate(model.deadline),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // ── budget + posted ───────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Max Budget',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        '${model.valueKM.toStringAsFixed(0)} KM',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Posted ${_timeAgo(model.postedAt)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => TenderBidsScreen(
                          tenderId: model.id,
                          tenderTitle: model.title,
                          tenderDto: tender,
                          tenderService: tenderService,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.gavel_rounded, size: 16),
                  label: const Text('See bids'),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
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

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.isOpen});

  final bool isOpen;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final bg = isOpen
        ? colorScheme.primaryContainer
        : colorScheme.errorContainer;
    final fg = isOpen
        ? colorScheme.onPrimaryContainer
        : colorScheme.onErrorContainer;
    final label = isOpen ? 'Open' : 'Closed';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
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
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
