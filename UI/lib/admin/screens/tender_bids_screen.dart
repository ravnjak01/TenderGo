import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tendergo/shared/controllers/tender_bids_controller.dart';
import 'package:tendergo/shared/core/actions/back_button.dart';
import 'package:tendergo/shared/models/dto/bid_dto.dart';
import 'package:tendergo/shared/models/dto/tender_dto.dart';
import 'package:tendergo/shared/models/enums/application_status.dart';
import 'package:tendergo/shared/models/enums/tenderstatus.dart';
import 'package:tendergo/shared/services/bid_service.dart';
import 'package:tendergo/shared/services/dio_client.dart';
import 'package:tendergo/admin/screens/offer_report_screen.dart';
import 'package:tendergo/shared/services/tender_service.dart';
import 'package:tendergo/shared/widgets/common/action_button.dart';
import 'package:tendergo/shared/widgets/common/app_badge.dart';
import 'package:tendergo/shared/widgets/common/app_card.dart';
import 'package:tendergo/shared/widgets/common/app_dialogs.dart';
import 'package:tendergo/shared/widgets/common/app_icon.dart';
import 'package:tendergo/shared/widgets/feedback/screen_state_widget.dart';
import 'package:tendergo/shared/widgets/feedback/snackbar_helper.dart';
import 'package:tendergo/shared/widgets/tender/tender_meta_item.dart';

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
  late final TenderBidsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TenderBidsController(
      tenderId: widget.tenderId,
      tender: widget.tenderDto,
      tenderService: widget.tenderService,
      bidService: BidService(DioClient.getDio()),
    );
    _controller.load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _award(BidDto bid) async {
    final confirmed = await AppDialogs.showConfirm(
      context: context,
      title: 'Award tender',
      content:
          'Award this tender to ${bid.submittedByUserName}?\n\nThis action cannot be undone.',
      confirmLabel: 'Award',
      isDestructive: true,
    );
    if (!confirmed || !mounted) return;

    try {
      await _controller.award(bid);
      if (!mounted) return;
      SnackbarHelper.show(
        context,
        'Tender awarded to ${bid.submittedByUserName}',
      );
    } catch (e) {
      if (!mounted) return;
      SnackbarHelper.show(
        context,
        'Failed to award: ${e.toString().replaceFirst('Exception: ', '')}',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.tenderTitle != null
        ? 'Bids - ${widget.tenderTitle}'
        : 'Bids for Tender #${widget.tenderId}';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: const CustomBackButton(),
        actions: [
          AppIconButton(
            icon: Icons.refresh_rounded,
            tooltip: 'Refresh',
            onTap: _controller.refresh,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) => _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_controller.isLoading && _controller.bids.isEmpty) {
      return const ScreenLoadingState();
    }

    if (_controller.hasError && _controller.bids.isEmpty) {
      return ScreenErrorState(
        message: _controller.errorMessage,
        onRetry: _controller.refresh,
      );
    }

    if (_controller.bids.isEmpty) {
      return ScreenEmptyState(
        icon: Icons.inbox_outlined,
        title: 'No bids found',
        description: 'No bids found for this tender.',
        onAction: _controller.refresh,
      );
    }

    return Column(
      children: [
        _BidsSummary(count: _controller.bids.length),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _controller.refresh,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _controller.bids.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final bid = _controller.bids[index];
                return _BidCard(
                  bid: bid,
                  canAward: widget.tenderDto.status == TenderStatus.closed &&
                      bid.status == ApplicationStatus.pending,
                  onAward: () => _award(bid),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _BidsSummary extends StatelessWidget {
  const _BidsSummary({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: theme.colorScheme.surfaceContainerHighest,
      child: Text(
        '$count bid${count == 1 ? '' : 's'} submitted',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _BidCard extends StatelessWidget {
  const _BidCard({
    required this.bid,
    required this.canAward,
    required this.onAward,
  });

  final BidDto bid;
  final bool canAward;
  final VoidCallback onAward;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final priceFormatted = '${bid.offeredPrice.toStringAsFixed(0)} KM';
    final dateFormatted = DateFormat('dd MMM yyyy, HH:mm').format(bid.submittedAt);

    final isAccepted=bid.status==ApplicationStatus.accepted;

    return AppCard(
      title: 'Bidder',
      icon: Icons.person_outline_rounded,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _BidAvatar(name: bid.submittedByUserName),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      bid.submittedByUserName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  _BidStatusBadge(status: bid.status),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 14),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  TenderMetaItem(
                    icon: Icons.payments_outlined,
                    label: priceFormatted,
                  ),
                  if (bid.deliveryDays != null)
                    TenderMetaItem(
                      icon: Icons.schedule_rounded,
                      label:
                          '${bid.deliveryDays} day${bid.deliveryDays! > 1 ? 's' : ''}',
                    ),
                  TenderMetaItem(
                    icon: Icons.calendar_today_outlined,
                    label: dateFormatted,
                  ),
                ],
              ),
              if (bid.proposal != null && bid.proposal!.isNotEmpty) ...[
                const SizedBox(height: 12),
                _ProposalPreview(proposal: bid.proposal!),
              ],
              if (canAward || isAccepted)   ...[
                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: canAward
                      ? ActionButton(
                          label: 'Award',
                          icon: Icons.emoji_events_rounded,
                          isPrimary: true,
                          onTap: onAward,
                        )
                      : OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.green[700],
                            side: BorderSide(color: Colors.green.shade700),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => OfferReportScreen(offerId: bid.id),
                              ),
                            );
                          },
                          icon: const Icon(Icons.picture_as_pdf_rounded),
                          label: const Text('Izvještaj'),
                        ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _BidAvatar extends StatelessWidget {
  const _BidAvatar({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';

    return CircleAvatar(
      radius: 20,
      backgroundColor: theme.colorScheme.primaryContainer,
      child: Text(
        initial,
        style: TextStyle(
          color: theme.colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _BidStatusBadge extends StatelessWidget {
  const _BidStatusBadge({required this.status});

  final ApplicationStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = _colorsForStatus(context, status);

    return AppBadge(
      label: status.name,
      backgroundColor: colors.background,
      foregroundColor: colors.foreground,
      borderColor: colors.background,
    );
  }

  _BadgeColors _colorsForStatus(BuildContext context, ApplicationStatus status) {
    final colorScheme = Theme.of(context).colorScheme;

    switch (status) {
      case ApplicationStatus.accepted:
        return _BadgeColors(
          background: Colors.green.withOpacity(0.12),
          foreground: Colors.green.shade700,
        );
      case ApplicationStatus.rejected:
        return _BadgeColors(
          background: colorScheme.errorContainer,
          foreground: colorScheme.onErrorContainer,
        );
      case ApplicationStatus.withdrawn:
        return _BadgeColors(
          background: colorScheme.surfaceContainerHighest,
          foreground: colorScheme.onSurfaceVariant,
        );
      case ApplicationStatus.pending:
        return _BadgeColors(
          background: Colors.orange.withOpacity(0.12),
          foreground: Colors.orange.shade800,
        );
    }
  }
}

class _BadgeColors {
  const _BadgeColors({
    required this.background,
    required this.foreground,
  });

  final Color background;
  final Color foreground;
}

class _ProposalPreview extends StatelessWidget {
  const _ProposalPreview({required this.proposal});

  final String proposal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
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
          Text(proposal, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}
