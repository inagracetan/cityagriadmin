import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/firebase_service.dart';
import '../../core/design_system.dart';

class SystemLogsScreen extends StatelessWidget {
  const SystemLogsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fbService = context.watch<FirebaseService>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Container(
        padding: const EdgeInsets.all(AppDesignSystem.spacing24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'System Logs',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppDesignSystem.spacing8),
            Text(
              'Audit trail of all critical system activities and events.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: AppDesignSystem.spacing32),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: fbService.streamSystemLogs(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final logs = snapshot.data?.docs ?? [];

                  if (logs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.history,
                            size: 64,
                            color: theme.colorScheme.primary.withValues(alpha: 0.2),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No logs found yet',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: logs.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final log = logs[index].data();
                      final timestamp = log['timestamp'] as Timestamp?;
                      final dateStr = timestamp != null
                          ? DateFormat('MMM dd, yyyy HH:mm').format(timestamp.toDate())
                          : 'Pending...';

                      return ListTile(
                        leading: _getIconForType(log['type']),
                        title: Text(log['message'] ?? 'No message'),
                        subtitle: Row(
                          children: [
                            Text(
                              log['action']?.toString().toUpperCase() ?? 'ACTION',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: _getColorForAction(log['action']),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(dateStr),
                          ],
                        ),
                        trailing: log['user_name'] != null
                            ? Chip(
                                label: Text(
                                  log['user_name'],
                                  style: const TextStyle(fontSize: 10),
                                ),
                                avatar: const Icon(Icons.person, size: 12),
                                padding: EdgeInsets.zero,
                                visualDensity: VisualDensity.compact,
                              )
                            : null,
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

  Widget _getIconForType(String? type) {
    switch (type) {
      case 'activity':
        return const Icon(Icons.assignment, color: Colors.blue);
      case 'financial':
        return const Icon(Icons.account_balance_wallet, color: Colors.green);
      case 'auth':
        return const Icon(Icons.lock, color: Colors.orange);
      default:
        return const Icon(Icons.info, color: Colors.grey);
    }
  }

  Color _getColorForAction(String? action) {
    switch (action) {
      case 'create':
        return Colors.green;
      case 'update':
        return Colors.blue;
      case 'delete':
        return Colors.red;
      case 'status_change':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
