import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tendergo/shared/controllers/bids_list_controller.dart';
import 'package:tendergo/shared/core/actions/back_button.dart';
import 'package:tendergo/shared/core/utils/extensions/string_extensions.dart';
import 'package:tendergo/shared/models/dto/bid_dto.dart';
import 'package:tendergo/shared/providers/tender_provider.dart';
import 'package:tendergo/shared/routes/routes.dart';
import 'package:tendergo/shared/services/bid_service.dart';
import 'package:tendergo/shared/services/offer_report_screen.dart';
import 'package:tendergo/shared/services/pdf_service.dart';
import 'package:tendergo/shared/widgets/feedback/snackbar_helper.dart';
import 'package:tendergo/shared/widgets/feedback/screen_state_widget.dart';
import 'package:tendergo/shared/widgets/common/app_dialogs.dart';
import 'package:tendergo/shared/widgets/common/app_icon.dart';
import 'package:tendergo/shared/widgets/tender/tender_meta_item.dart';

class MyBidsScreen extends StatefulWidget {
  final BidService _bidService;
  const MyBidsScreen({
    super.key,
    required BidService bidService,
  }) : _bidService = bidService;

  @override
  State<MyBidsScreen> createState() => _MyBidsScreenState();
}

class _MyBidsScreenState extends State<MyBidsScreen> {
  // ── state ──────────────────────────────────────────────────────────────────
  late BidsListController _controller;

  
  // ── lifecycle ──────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _controller = BidsListController(widget._bidService);
    _controller.initialize();
    _controller.fetchInitial();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ── data fetching ──────────────────────────────────────────────────────────
  void _refresh() {
    _controller.refresh().then((_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _cancelBid(BidDto bid) async {
    final confirmed = await AppDialogs.showConfirm(
      context: context,
      title: 'Cancel Bid',
      content: 'Are you sure you want to cancel this bid?',
      cancelLabel: 'No',
      confirmLabel: 'Yes, Cancel',
      isDestructive: true,
    );
    if (!confirmed || !mounted) return;

    try {
      final updated = await widget._bidService.cancel(bid.id);
      if (!mounted) return;

      setState(() {
        final index = _controller.items.indexWhere((b) => b.id == bid.id);
        if (index != -1) {
          _controller.items[index] = updated;
        }
      });

      SnackbarHelper.show(context, 'Bid canceled successfully.');
    } catch (e) {
      if (!mounted) return;
      SnackbarHelper.show(
        context,
        e.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    }
  }

  Future<void> _openRateUser(BidDto bid) async {
  final tenderProvider = context.read<TenderProvider>();
  
  final args = await tenderProvider.prepareRatingArguments(bid);

  if (!mounted) return;

  if (args == null) {
    SnackbarHelper.show(
      context,
      'Unable to resolve tender owner for rating.',
      isError: true,
    );
    return;
  }

  Navigator.of(context).pushNamed(AppRoutes.rateUser, arguments: args);
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
        leading: const CustomBackButton(),
        title: Text(
          'My Bids',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
        ),
        actions: [
          AppIconButton(
            icon: Icons.refresh_rounded,
            onTap: _refresh,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) => _buildBody(colorScheme),
      ),
    );
  }

  Widget _buildBody(ColorScheme colorScheme) {
    if (_controller.hasError && _controller.items.isEmpty) {
      return ScreenErrorState(
        message: _controller.errorMessage,
        onRetry: _refresh,
      );
    }

    if (_controller.isLoading && _controller.items.isEmpty) {
      return const ScreenLoadingState();
    }

    if (_controller.items.isEmpty) {
      return ScreenEmptyState(
        icon: Icons.gavel_rounded,
        title: 'No bids yet',
        description: 'Bids you submit will appear here.',
        onAction: _refresh,
      );
    }

    return RefreshIndicator(
      onRefresh: _controller.refresh,
      child: ListView.separated(
        controller: _controller.scrollController,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: _controller.items.length + (_controller.hasMore ? 1 : 0),
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index >= _controller.items.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return _BidCard(
            bid: _controller.items[index],
            onRateUser: () => _openRateUser(_controller.items[index]),
            onCancel: () => _cancelBid(_controller.items[index]),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bid Card
// ─────────────────────────────────────────────────────────────────────────────

class _BidCard extends StatelessWidget {
  const _BidCard({
    required this.bid,
    required this.onRateUser,
    required this.onCancel,
  });

  final BidDto bid;
  final VoidCallback onRateUser;
  final VoidCallback onCancel;

  bool _isAwardedStatus(String? status) {
    final normalized = (status ?? '').trim().toLowerCase();
    return normalized == 'accepted';
  }

  bool _isCancelableStatus(String? status) {
    final normalized = (status ?? '').trim().toLowerCase();
    if (normalized.isEmpty) return true;

    return normalized != 'accepted' &&
        normalized != 'rejected' &&
        normalized != 'withdrawn' &&
        normalized != 'cancelled' &&
        normalized != 'canceled';
  }

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
                              bid.tenderTitle ?? 'Unknown tender',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (isCompact) ...[
                              const SizedBox(height: 8),
                              _StatusChip(status: bid.status.name),
                            ],
                          ],
                        ),
                      ),
                      if (!isCompact) ...[
                        const SizedBox(width: 8),
                        _StatusChip(status: bid.status.name),
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
                      TenderMetaItem(
                        icon: Icons.schedule_rounded,
                        label: bid.submittedAt.toTimeAgo(),
                      ),
                      if (bid.deliveryDays != null)
                        TenderMetaItem(
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

                  if (_isAwardedStatus(bid.status.name)) ...[
  const SizedBox(height: 12),
  Align(
    alignment: Alignment.centerRight,
    child: Row(
      mainAxisSize: MainAxisSize.min, // Skuplja Row samo oko dugmadi
      children: [
        // 🌟 NOVO: Dugme za izvještaj
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: Colors.green[700], // Zelena boja za izvještaje/print
          ),
          onPressed: ()async {
            /*
            Navigator.push(
              context,
              MaterialPageRoute(
                // Prosjeđujemo ID ponude u ekran koji smo ranije kreirali
                builder: (context) => OfferReportScreen(offerId: bid.id),
              ),
            );
            */
           final pdfService = PdfService();
        final bytes = await pdfService.fetchOfferPdf(bid.id);
        
        if (bytes != null) {
          print("🎉 USPJEH! Dobijeni bajtovi iz baze, veličina: ${bytes.length} bajta.");
          
          // Tek kada smo sigurni da imamo bajtove, idemo na ekran
          if (context.mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => OfferReportScreen(offerId: bid.id),
              ),
            );
          }
        } else {
          print("❌ Servis je vratio NULL. Provjeri API endpoint i .NET backend!");
        }
          },
          icon: const Icon(Icons.picture_as_pdf_rounded),
          label: const Text('Izvještaj'),
        ),
        
        const SizedBox(width: 8), // Razmak između dva dugmeta
        
        // Postojeće dugme za ocjenjivanje
        FilledButton.tonalIcon(
          onPressed: onRateUser,
          icon: const Icon(Icons.star_rate_rounded),
          label: const Text('Rate User'),
        ),
      ],
    ),
  ),
],

                  if (_isCancelableStatus(bid.status.name)) ...[
  const SizedBox(height: 8), // Smanjio sam malo i razmak iznad
  Align(
    alignment: Alignment.centerRight,
    child: SizedBox(
      height: 32, // Fiksna visina dugmeta (standardna je oko 40-48)
      // width: 100, // Možeš dodati i fiksnu širinu ako želiš
      child: OutlinedButton.icon(
        onPressed: onCancel,
        style: OutlinedButton.styleFrom(
          // Moramo ukloniti defaultni padding da bi tekst stao u 32px visine
          padding: const EdgeInsets.symmetric(horizontal: 12),
          side: const BorderSide(color: Colors.red), // Opcionalno: crvena ivica
          foregroundColor: Colors.red, // Tekst i ikona postaju crveni
        ),
        icon: const Icon(Icons.cancel_outlined, size: 16), // Smanjena ikona
        label: const Text(
          'Cancel',
          style: TextStyle(fontSize: 12), // Smanjen font
        ),
      ),
    ),
  ),
],
                ],
              ),
            ),
          ),
        );
      },
    );
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

