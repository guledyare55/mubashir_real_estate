import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/models/notification.dart';
import '../../core/services/supabase_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final SupabaseService _supabase = SupabaseService();
  late Future<List<AppNotification>> _notificationsFuture;

  @override
  void initState() {
    super.initState();
    _refreshNotifications();
  }

  void _refreshNotifications() {
    setState(() {
      _notificationsFuture = _supabase.fetchNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFB),
      appBar: AppBar(
        title: const Text('Notifications', 
          style: TextStyle(color: Color(0xFF0F172A), fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF0F172A), size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<List<AppNotification>>(
        future: _notificationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFF59E0B)));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          
          final notifications = snapshot.data ?? [];
          
          if (notifications.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: () async => _refreshNotifications(),
            color: const Color(0xFFF59E0B),
            child: ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: notifications.length,
              separatorBuilder: (context, index) => const SizedBox(height: 15),
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return _buildNotificationCard(notification);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A).withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.notifications_off_outlined, color: const Color(0xFF0F172A).withOpacity(0.2), size: 40),
          ),
          const SizedBox(height: 20),
          const Text('No Notifications Yet', 
            style: TextStyle(color: Color(0xFF0F172A), fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('We\'ll notify you when something important happens.', 
            style: TextStyle(color: Colors.grey, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(AppNotification notification) {
    Color typeColor;
    IconData typeIcon;
    
    switch (notification.type) {
      case 'Promotion':
        typeColor = const Color(0xFFF59E0B);
        typeIcon = Icons.local_offer_outlined;
        break;
      case 'Listing':
        typeColor = Colors.blue;
        typeIcon = Icons.home_outlined;
        break;
      case 'System':
        typeColor = Colors.redAccent;
        typeIcon = Icons.settings_outlined;
        break;
      default:
        typeColor = const Color(0xFF0F172A);
        typeIcon = Icons.info_outline;
    }

    return GestureDetector(
      onTap: () {
        if (!notification.isRead) {
          _supabase.markNotificationAsRead(notification.id).then((_) {
            _refreshNotifications();
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: notification.isRead ? null : Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3), width: 1),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: typeColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(typeIcon, color: typeColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(notification.title, 
                        style: TextStyle(
                          color: const Color(0xFF0F172A), 
                          fontSize: 14, 
                          fontWeight: notification.isRead ? FontWeight.w600 : FontWeight.bold
                        )),
                      Text(DateFormat('MMM dd').format(notification.createdAt), 
                        style: const TextStyle(color: Colors.grey, fontSize: 11)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(notification.message, 
                    style: TextStyle(
                      color: Colors.grey[600], 
                      fontSize: 13, 
                      height: 1.4,
                      fontWeight: notification.isRead ? FontWeight.normal : FontWeight.w500
                    )),
                  if (!notification.isRead)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('New', style: TextStyle(color: Color(0xFFF59E0B), fontSize: 10, fontWeight: FontWeight.bold)),
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
}
