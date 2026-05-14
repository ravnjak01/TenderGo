import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tendergo/shared/models/dto/bid_dto.dart';
import 'package:tendergo/shared/models/dto/tender_dto.dart';
import 'package:tendergo/shared/models/enums/tenderstatus.dart';
import 'package:tendergo/shared/services/bid_service.dart';
import 'package:tendergo/shared/services/dio_client.dart';
import 'package:tendergo/shared/services/tender_service.dart';
import 'package:tendergo/admin/widgets/common/app_dialogs.dart';
import 'package:tendergo/shared/widgets/feedback/screen_state_widget.dart';

class TenderBidsScreen extends StatefulWidget {
  final int tenderId;
  final String? tenderTitle;
    final TenderDto tenderDto;           
  final TenderService tenderService;

  const TenderBidsScreen({
    super.key,
    required this.tenderId,
    this.tenderTitle,
    required this.tenderDto,
    required this.tenderService,
  });

  @override
  State<TenderBidsScreen> createState() => _TenderBidsScreenState();
}

class _TenderBidsScreenState extends State<TenderBidsScreen> {
  late final BidService _bidService;
  late Future<List<BidDto>> _bidsFuture;

  @override
  void initState() {
    super.initState();
    final dio = DioClient.getDio();
    // If you use GetIt or Provider, replace this with your DI approach
    _bidService = BidService(dio);
    _bidsFuture = _bidService.getByTender(widget.tenderId);
  }

  void _refresh() {
    setState(() {
      _bidsFuture = _bidService.getByTender(widget.tenderId);
    });
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'withdrawn':
        return Colors.grey;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.tenderTitle != null
            ? 'Bids — ${widget.tenderTitle}'
            : 'Bids for Tender #${widget.tenderId}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _refresh,
          ),
        ],
      ),
      body: FutureBuilder<List<BidDto>>(
        future: _bidsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const ScreenLoadingState();
          }

          if (snapshot.hasError) {
            return ScreenErrorState(
              message: snapshot.error.toString(),
              onRetry: _refresh,
            );
          }

          final bids = snapshot.data ?? [];

          if (bids.isEmpty) {
            return ScreenEmptyState(
              icon: Icons.inbox_outlined,
              title: 'No bids found',
              description: 'No bids found for this tender.',
              onAction: _refresh,
            );
          }

          return Column(
            children: [
              // Summary bar
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                color: theme.colorScheme.surfaceContainerHighest,
                child: Text(
                  '${bids.length} bid${bids.length == 1 ? '' : 's'} submitted',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),

              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: bids.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final bid = bids[index];
                    return _BidCard(
                      bid: bid,
                      statusColor: _statusColor(bid.status.name),
                      tenderDto: widget.tenderDto,
                      tenderService: widget.tenderService,
                      bidService: _bidService,
                      allBids: bids,
                      onAwarded: _refresh,
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BidCard extends StatelessWidget {
  final BidDto bid;
  final Color statusColor;
  final TenderDto tenderDto;
  final TenderService tenderService;
  final BidService bidService;
  final List<BidDto> allBids;
  final VoidCallback onAwarded;

  const _BidCard({
    required this.bid,
    required this.statusColor,
    required this.tenderDto,
    required this.tenderService,
    required this.bidService,
    required this.allBids,
    required this.onAwarded,
  });

 Future<void> _award(BuildContext context) async {
    final confirmed = await AppDialogs.showConfirm(
      context: context,
      title: 'Award tender',
      content:
          'Award this tender to ${bid.submittedByUserName}?\n\nThis action cannot be undone.',
      confirmLabel: 'Award',
      isDestructive: true,
    );

    if (!confirmed || !context.mounted) return;

    try {
      await tenderService.award(tenderDto, bid.id);

      // Reject all other pending bids for this tender
      final rejectFutures = allBids
          .where((b) => b.id != bid.id && b.status == ApplicationStatus.pending)
          .map((b) => bidService.update(b.id, {'status': 'rejected'}));
      await Future.wait(rejectFutures);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tender awarded to ${bid.submittedByUserName}'),
          backgroundColor: Colors.green,
        ),
      );
      onAwarded(); // refresh the list
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to award: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormatted =
        DateFormat('dd MMM yyyy, HH:mm').format(bid.submittedAt);
    final priceFormatted =
        '${bid.offeredPrice.toStringAsFixed(0)} KM';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row: bidder name + status badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(
                    bid.submittedByUserName.isNotEmpty
                        ? bid.submittedByUserName[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    bid.submittedByUserName,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    bid.status.name,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 14),

            // Price + delivery
            Row(
              children: [
                Expanded(
                  child: _InfoTile(
                    icon: Icons.attach_money,
                    label: 'Offered price',
                    value: priceFormatted,
                    valueStyle: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (bid.deliveryDays != null)
                  Expanded(
                    child: _InfoTile(
                      icon: Icons.schedule,
                      label: 'Delivery',
                      value: '${bid.deliveryDays} day${bid.deliveryDays! > 1 ? 's' : ''}',
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 10),

            // Submitted at
            _InfoTile(
              icon: Icons.calendar_today_outlined,
              label: 'Submitted',
              value: dateFormatted,
            ),

            // Proposal
            if (bid.proposal != null && bid.proposal!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Proposal',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      bid.proposal!,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],

                if (tenderDto.status == TenderStatus.closed &&
                  bid.status == ApplicationStatus.pending) ...[
      const SizedBox(height: 14),
      const Divider(height: 1),
      const SizedBox(height: 10),
      Align(
        alignment: Alignment.centerRight,
        child: FilledButton.icon(
          onPressed: () => _award(context),
          icon: const Icon(Icons.emoji_events_rounded, size: 16),
          label: const Text('Award'),
          style: FilledButton.styleFrom(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ),
    ],
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final TextStyle? valueStyle;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.valueStyle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              value,
              style: valueStyle ?? theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ],
    );
  }
}