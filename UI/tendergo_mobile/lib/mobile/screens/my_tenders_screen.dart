import 'package:flutter/material.dart';
import 'package:tendergo/mobile/screens/tender_bids_screen.dart';
// CHANGE THIS: Point to your mobile version of the bids screen
import 'package:tendergo/shared/controllers/my_tenders_controller.dart';
import 'package:tendergo/shared/core/actions/back_button.dart';
import 'package:tendergo/shared/core/utils/extensions/string_extensions.dart';
import 'package:tendergo/shared/models/dto/tender_dto.dart';
import 'package:tendergo/shared/models/enums/tenderstatus.dart';
import 'package:tendergo/shared/services/tender_service.dart';
import 'package:tendergo/mobile/widgets/common/action_button.dart';
import 'package:tendergo/mobile/widgets/common/app_badge.dart';
import 'package:tendergo/mobile/widgets/common/app_card.dart';
import 'package:tendergo/mobile/widgets/common/app_dialogs.dart';
import 'package:tendergo/mobile/widgets/common/app_icon.dart';
import 'package:tendergo/mobile/widgets/feedback/screen_state_widget.dart';
import 'package:tendergo/mobile/widgets/feedback/snackbar_helper.dart';
import 'package:tendergo/mobile/widgets/tender/tender_meta_item.dart';

class MobileMyTendersScreen extends StatefulWidget {
  final TenderService tenderService;

  const MobileMyTendersScreen({super.key, required this.tenderService});

  @override
  State<MobileMyTendersScreen> createState() => _MobileMyTendersScreenState();
}

class _MobileMyTendersScreenState extends State<MobileMyTendersScreen> {
  late final MyTendersController _controller;

  @override
  void initState() {
    super.initState();
    _controller = MyTendersController(widget.tenderService);
    _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _cancelTender(TenderDto tender) async {
    final confirmed = await AppDialogs.showConfirm(
      context: context,
      title: 'Cancel Tender',
      content: 'Are you sure you want to cancel this tender?',
      cancelLabel: 'No',
      confirmLabel: 'Yes, Cancel',
      isDestructive: true,
    );
    if (!confirmed || !mounted) return;

    try {
      await _controller.cancelTender(tender);
      if (!mounted) return;
      SnackbarHelper.show(context, 'Tender canceled successfully.');
    } catch (e) {
      if (!mounted) return;
      SnackbarHelper.show(
        context,
        e.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    }
  }

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
          'My Tenders',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
        ),
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
    if (_controller.hasError && _controller.items.isEmpty) {
      return ScreenErrorState(
        message: _controller.errorMessage,
        onRetry: _controller.refresh,
      );
    }

    if (_controller.isLoading && _controller.items.isEmpty) {
      return const ScreenLoadingState();
    }

    if (_controller.items.isEmpty) {
      return ScreenEmptyState(
        icon: Icons.inbox_rounded,
        title: 'No tenders yet',
        description: 'Your published tenders will appear here.',
        onAction: _controller.refresh,
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

          final tender = _controller.items[index];
          return _MobileTenderCard(
            tender: tender,
            tenderService: widget.tenderService,
            onCancel: () => _cancelTender(tender),
          );
        },
      ),
    );
  }
}

class _MobileTenderCard extends StatelessWidget {
  const _MobileTenderCard({
    required this.tender,
    required this.tenderService,
    required this.onCancel,
  });

  final TenderDto tender;
  final TenderService tenderService;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final model = tender.toCardModel();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final status = model.status;
    final isOpen = status == TenderStatus.open;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 360;

        return AppCard(
          title: model.category,
          icon: Icons.assignment_outlined,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                            if (isCompact) ...[
                              const SizedBox(height: 8),
                              _TenderStatusBadge(status: status),
                            ],
                          ],
                        ),
                      ),
                      if (!isCompact) ...[
                        const SizedBox(width: 8),
                        _TenderStatusBadge(status: status),
                      ],
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
                        icon: Icons.location_on_rounded,
                        label: model.locationName,
                      ),
                      TenderMetaItem(
                        icon: Icons.calendar_today_rounded,
                        label: model.deadline.formatDate(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  crossAxisAlignment: CrossAxisAlignment.end,
  children: [
    Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis, // Safe fallback for massive numbers
          ),
        ],
      ),
    ),
    const SizedBox(width: 8), // Small safety gap
    Text(
      'Posted ${model.postedAt.toTimeAgo()}',
      style: theme.textTheme.bodySmall?.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    ),
  ],
),
                  const SizedBox(height: 8),
                  Wrap(
                    alignment: WrapAlignment.end,
                    runSpacing: 8,
                    spacing: 6,
                    children: [
                      if (isOpen)
                        ActionButton(
                          label: 'Cancel',
                          icon: Icons.cancel_outlined,
                          isPrimary: false,
                          isDestructive: true,
                          width: 115,
                          showLabel: true,
                          onTap: onCancel,
                        ),
                      ActionButton(
                        label: 'See bids',
                        icon: Icons.gavel_rounded,
                        isPrimary: true,
                        width: 115,
                        showLabel: true,
                        onTap: () {
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
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TenderStatusBadge extends StatelessWidget {
  const _TenderStatusBadge({required this.status});

  final TenderStatus status;

  @override
  Widget build(BuildContext context) {
    return AppBadge(
      label: status.label,
      backgroundColor: status.badgeBg,
      foregroundColor: status.badgeFg,
      borderColor: status.badgeBg,
    );
  }
}