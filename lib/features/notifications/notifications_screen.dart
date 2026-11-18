import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/widgets/app_animations.dart';
import '../../../data/models/notification_model.dart';
import '../../../data/repositories/notification_repository.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchAlerts();
  }

  Future<void> _fetchAlerts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = context.read<NotificationRepository>();
      final list = await repo.getNotifications();
      if (mounted) {
        setState(() {
          _notifications = List.from(list);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _markRead(String id) {
    setState(() {
      final i = _notifications.indexWhere((n) => n.id == id);
      if (i != -1) _notifications[i] = _notifications[i].copyWith(isRead: true);
    });
    context.read<NotificationRepository>().markAsRead(id);
  }

  void _markAllRead() {
    setState(() {
      _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
    });
    context.read<NotificationRepository>().markAllAsRead();
  }

  int get _unreadCount => _notifications.where((n) => !n.isRead).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Operational Alerts'),
            Text('Nashik Kumbh Emergency Hub', style: GoogleFonts.inter(fontSize: 10, color: Colors.white70)),
          ],
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: _markAllRead,
              child: Text(
                'Mark All Read',
                style: GoogleFonts.inter(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: _fetchAlerts,
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 800;

          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: isWide ? 800 : double.infinity),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.secondary))
                  : _errorMessage != null
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
                              const SizedBox(height: 8),
                              Text(_errorMessage!, style: GoogleFonts.inter(color: AppColors.textMedium)),
                              const SizedBox(height: 12),
                              ElevatedButton(onPressed: _fetchAlerts, child: const Text('Retry')),
                            ],
                          ),
                        )
                      : _notifications.isEmpty
                          ? const EmptyStateWidget(
                              icon: Icons.notifications_off_rounded,
                              title: 'No Operational Alerts',
                              subtitle: 'All civic systems normal across Nashik',
                            )
                          : RefreshIndicator(
                              onRefresh: _fetchAlerts,
                              color: AppColors.secondary,
                              child: ListView.builder(
                                itemCount: _notifications.length,
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                itemBuilder: (context, i) {
                                  return _NotificationTile(
                                    notification: _notifications[i],
                                    onTap: () => _markRead(_notifications[i].id),
                                  ).slideEntrance(index: i);
                                },
                              ),
                            ),
            ),
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const _NotificationTile({required this.notification, required this.onTap});

  Color get _typeColor {
    switch (notification.type) {
      case NotificationType.emergency:
        return AppColors.error;
      case NotificationType.traffic:
        return AppColors.warning;
      case NotificationType.announcement:
        return AppColors.primary;
      case NotificationType.complaintUpdate:
        return AppColors.secondary;
      case NotificationType.health:
        return AppColors.success;
    }
  }

  IconData get _typeIcon {
    switch (notification.type) {
      case NotificationType.emergency:
        return Icons.warning_rounded;
      case NotificationType.traffic:
        return Icons.traffic_rounded;
      case NotificationType.announcement:
        return Icons.campaign_rounded;
      case NotificationType.complaintUpdate:
        return Icons.assignment_turned_in_rounded;
      case NotificationType.health:
        return Icons.local_hospital_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.isRead;

    return AnimatedTap(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: isUnread ? _typeColor.withValues(alpha: 0.04) : Colors.white,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          border: Border.all(
            color: isUnread ? _typeColor.withValues(alpha: 0.3) : AppColors.border,
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _typeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                ),
                child: Icon(_typeIcon, color: _typeColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: isUnread ? FontWeight.w600 : FontWeight.w500,
                              color: AppColors.textDark,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isUnread)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(color: _typeColor, shape: BoxShape.circle),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.message,
                      style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMedium, height: 1.5),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: _typeColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(
                            notification.typeLabel,
                            style: GoogleFonts.inter(fontSize: 10, color: _typeColor, fontWeight: FontWeight.w600),
                          ),
                        ),
                        if (notification.area != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            notification.area!,
                            style: GoogleFonts.inter(fontSize: 10, color: AppColors.textMedium, fontWeight: FontWeight.w500),
                          ),
                        ],
                        const Spacer(),
                        Text(
                          _formatTime(notification.receivedAt),
                          style: GoogleFonts.inter(fontSize: 10, color: AppColors.textLight),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return DateFormat('d MMM').format(time);
  }
}
