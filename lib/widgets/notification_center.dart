import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/notification_model.dart';
import '../services/firebase_service.dart';
import '../services/auth_service.dart';
import '../core/date_formatter.dart';

class NotificationCenter extends StatelessWidget {
  const NotificationCenter({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const NotificationCenter(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fbService = context.read<FirebaseService>();
    final authService = context.read<AuthService>();
    final userId = authService.currentUser?.uid;
    final theme = Theme.of(context);

    return Dialog(
      alignment: Alignment.topRight,
      insetPadding: const EdgeInsets.fromLTRB(16, 64, 16, 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 400,
        height: 600,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: theme.scaffoldBackgroundColor,
        ),
        child: Column(
          children: [
            _buildHeader(context, fbService, userId),
            Expanded(
              child: StreamBuilder<List<SystemNotification>>(
                stream: fbService.streamNotifications(userId: userId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  final notifications = snapshot.data ?? [];
                  
                  if (notifications.isEmpty) {
                    return _buildEmptyState(theme);
                  }

                  return ListView.separated(
                    itemCount: notifications.length,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final notification = notifications[index];
                      return _NotificationItem(
                        notification: notification,
                        onTap: () {
                          fbService.markNotificationAsRead(notification.id);
                          if (notification.relatedId != null) {
                            Navigator.pop(context);
                            // We could navigate to the specific activity here
                            // For now, let's at least mark it read.
                          }
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, FirebaseService fbService, String? userId) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              Icon(Icons.notifications, color: Colors.white),
              SizedBox(width: 12),
              Text(
                'Notifications',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          TextButton(
            onPressed: () => fbService.markAllNotificationsAsRead(userId),
            child: const Text(
              'Mark all as read',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none_outlined,
            size: 64,
            color: theme.dividerColor,
          ),
          const SizedBox(height: 16),
          Text(
            'No notifications yet',
            style: TextStyle(color: theme.disabledColor),
          ),
        ],
      ),
    );
  }
}

class _NotificationItem extends StatelessWidget {
  final SystemNotification notification;
  final VoidCallback onTap;

  const _NotificationItem({
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        color: notification.isRead ? null : theme.colorScheme.primary.withValues(alpha: 0.05),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildIcon(theme),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        notification.title,
                        style: TextStyle(
                          fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      if (!notification.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.message,
                    style: TextStyle(
                      color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    DateFormatter.formatTimestamp(notification.timestamp),
                    style: TextStyle(
                      color: theme.disabledColor,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon(ThemeData theme) {
    IconData iconData;
    Color color;

    switch (notification.type) {
      case NotificationType.success:
        iconData = Icons.check_circle_outline;
        color = Colors.green;
        break;
      case NotificationType.warning:
        iconData = Icons.warning_amber_outlined;
        color = Colors.orange;
        break;
      case NotificationType.error:
        iconData = Icons.error_outline;
        color = Colors.red;
        break;
      case NotificationType.activity:
        iconData = Icons.event_note_outlined;
        color = Colors.blue;
        break;
      case NotificationType.budget:
        iconData = Icons.account_balance_wallet_outlined;
        color = Colors.purple;
        break;
      default:
        iconData = Icons.info_outline;
        color = theme.colorScheme.primary;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(iconData, color: color, size: 20),
    );
  }
}
