import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tendergo/admin/routes/routes.dart';
import 'package:tendergo/shared/core/theme/app_theme.dart';
import 'package:tendergo/shared/models/dto/notification_dto.dart';
import 'package:tendergo/shared/providers/notification_provider.dart';

const double _kMaxContentWidth = 800;

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  // Smanjen rizik od grešaka tokom dispose faze (koristimo referencu iz konteksta bez oslanjanja na kasni read)
  NotificationProvider? _notificationProvider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Sigurno hvatamo instancu providera za kasniji dispose
    _notificationProvider = Provider.of<NotificationProvider>(
      context,
      listen: false,
    );
  }

  @override
  void dispose() {
    _notificationProvider?.stopPolling();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(height: 0.5, color: AppColors.outline),
        ),
        actions: [
          Consumer<NotificationProvider>(
            builder: (_, provider, _) => TextButton.icon(
              onPressed: () => _showTestNotificationDialog(context, provider),
              icon: const Icon(Icons.science_outlined, size: 18),
              label: const Text('Test'),
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
          ),
          const SizedBox(width: 8),
          // Na desktopu dodajemo fiksno dugme za osvježavanje jer smo uklonili pull-to-refresh
          Consumer<NotificationProvider>(
            builder: (_, provider, _) => IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Refresh notifications',
              onPressed: () => provider.loadNotifications(),
            ),
          ),
          const SizedBox(width: 8),
          Consumer<NotificationProvider>(
            builder: (_, provider, _) => TextButton(
              onPressed: provider.unreadCount == 0
                  ? null
                  : () => provider.markAllAsRead(),
              child: Text(
                'Mark all read',
                style: TextStyle(
                  color: provider.unreadCount == 0
                      ? AppColors.textDisabled
                      : AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.state == NotificationLoadState.error) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 12),
                  Text(provider.error ?? 'Something went wrong'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.loadNotifications(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (provider.notifications.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No notifications',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'You\'re all caught up!',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          // ISPRAVLJENO: Potpuno uklonjen RefreshIndicator jer desktop koristi dugme u AppBar-u
          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _kMaxContentWidth),
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 16,
                ),
                itemCount: provider.notifications.length,
                separatorBuilder: (_, _) =>
                    const Divider(height: 1, color: AppColors.outline),
                itemBuilder: (context, index) {
                  final notification = provider.notifications[index];
                  return _NotificationTile(
                    notification: notification,
                    onTap: () => _handleTap(context, provider, notification),
                    onDismiss: () =>
                        provider.deleteNotification(notification.id),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  void _handleTap(
    BuildContext context,
    NotificationProvider provider,
    NotificationDto notification,
  ) {
    if (!notification.isRead) {
      provider.markAsRead(notification.id);
    }
    if (notification.tenderId != null) {
      Navigator.of(
        context,
      ).pushNamed(AppRoutes.tenderDetails, arguments: notification.tenderId);
    }
  }

  Future<void> _showTestNotificationDialog(
    BuildContext context,
    NotificationProvider provider,
  ) async {
    const expiredTender = 'expiredTender';
    const assignedTender = 'assignedTender';

    final idController = TextEditingController();
    var selectedType = expiredTender;
    var isSubmitting = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (_, setDialogState) {
            final label = selectedType == expiredTender
                ? 'Tender ID'
                : 'Bid ID';

            return AlertDialog(
              title: const Text('Send test notification'),
              content: SizedBox(
                width: 360,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: selectedType,
                      decoration: const InputDecoration(
                        labelText: 'Notification type',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: expiredTender,
                          child: Text('Expired tender'),
                        ),
                        DropdownMenuItem(
                          value: assignedTender,
                          child: Text('Assigned tender'),
                        ),
                      ],
                      onChanged: isSubmitting
                          ? null
                          : (value) {
                              if (value == null) return;
                              setDialogState(() {
                                selectedType = value;
                                idController.clear();
                              });
                            },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: idController,
                      enabled: !isSubmitting,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: label),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final id = int.tryParse(idController.text.trim());
                          if (id == null || id <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Enter a valid $label.')),
                            );
                            return;
                          }

                          setDialogState(() => isSubmitting = true);

                          try {
                            if (selectedType == expiredTender) {
                              await provider.testExpiredTender(id);
                            } else {
                              await provider.testAssignedTender(id);
                            }

                            if (!context.mounted || !dialogContext.mounted) {
                              return;
                            }
                            Navigator.of(dialogContext).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Test notification sent.'),
                              ),
                            );
                          } catch (error) {
                            if (!context.mounted) return;
                            setDialogState(() => isSubmitting = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Failed to send test notification: $error',
                                ),
                              ),
                            );
                          }
                        },
                  child: isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Send'),
                ),
              ],
            );
          },
        );
      },
    );

    idController.dispose();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Notification Tile
// ─────────────────────────────────────────────────────────────────────────────

class _NotificationTile extends StatelessWidget {
  final NotificationDto notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _NotificationTile({
    required this.notification,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      // Desktop prilagođen kursor (ruka) pri prelasku mišem preko notifikacije
      mouseCursor: SystemMouseCursors.click,
      tileColor: notification.isRead
          ? null
          : AppColors.primary.withValues(alpha: 0.05),
      leading: _NotificationIcon(
        type: notification.type,
        isRead: notification.isRead,
      ),
      title: Text(
        notification.title,
        style: TextStyle(
          fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
          fontSize: 14,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 2),
          Text(
            notification.message,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            _formatTime(notification.createdAt),
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
      trailing: IconButton(
        icon: const Icon(Icons.close, size: 16),
        color: AppColors.textSecondary,
        onPressed: onDismiss,
        tooltip: 'Dismiss',
      ),
      onTap: onTap,
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Icon by notification type
// ─────────────────────────────────────────────────────────────────────────────

class _NotificationIcon extends StatelessWidget {
  final String type;
  final bool isRead;

  const _NotificationIcon({required this.type, required this.isRead});

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _resolve(type);
    return CircleAvatar(
      radius: 20,
      backgroundColor: color.withValues(alpha: isRead ? 0.1 : 0.18),
      child: Icon(icon, size: 18, color: color),
    );
  }

  (IconData, Color) _resolve(String type) {
    return switch (type) {
      'bid_received' => (Icons.gavel_rounded, Colors.blue),
      'bid_accepted' => (Icons.check_circle_outline, Colors.green),
      'bid_rejected' => (Icons.cancel_outlined, Colors.red),
      'bid_withdrawn' => (Icons.undo_rounded, Colors.orange),
      'tender_closed' => (Icons.lock_outline, Colors.grey),
      'tender_cancelled' => (Icons.block_outlined, Colors.red),
      'tender_awarded' => (Icons.emoji_events_outlined, Colors.amber),
      _ => (Icons.notifications_outlined, AppColors.primary),
    };
  }
}
