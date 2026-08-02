import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tendergo/mobile/routes/routes.dart';
import 'package:tendergo/shared/core/theme/app_theme.dart';
import 'package:tendergo/shared/models/dto/notification_dto.dart';
import 'package:tendergo/shared/providers/notification_provider.dart';
import 'package:tendergo/mobile/widgets/common/app_dialogs.dart';


class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

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

          return RefreshIndicator(
            onRefresh: () => provider.loadNotifications(),
            child: ListView.separated(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: provider.notifications.length,
              separatorBuilder: (_, _) =>
                  const Divider(height: 1, color: AppColors.outline),
              itemBuilder: (context, index) {
                final notification = provider.notifications[index];
                return Dismissible(
                  key: ValueKey(notification.id),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (_) => _confirmDelete(context),
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    color: Colors.red,
                    child: const Icon(
                      Icons.delete_outline,
                      color: Colors.white,
                    ),
                  ),
                  onDismissed: (_) =>
                      provider.deleteNotification(notification.id),
                  child: _NotificationTile(
                    notification: notification,
                    onTap: () => _handleTap(context, provider, notification),
                    onDismiss: () async {
                      final confirmed = await _confirmDelete(context);
                      if (confirmed) {
                        provider.deleteNotification(notification.id);
                      }
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) {
    return AppDialogs.showConfirm(
      context: context,
      title: 'Delete Notification',
      content: 'Are you sure you want to delete this notification?',
      confirmLabel: 'Delete',
      isDestructive: true,
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
}

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