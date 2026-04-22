import 'package:flutter/material.dart';
import '../../core/services/supabase_service.dart';
import '../../core/models/profile.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  final _supabaseService = SupabaseService();
  Profile? _profile;
  bool _isLoading = true;
  final Map<String, bool> _tempPrefs = {};

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final profile = await _supabaseService.getCurrentUserProfile();
    if (mounted) {
      setState(() {
        _profile = profile;
        _tempPrefs.addAll(profile?.notificationPreferences ?? {
          'price_drops': true,
          'new_listings': true,
          'inquiry_updates': true,
          'marketing': false,
        });
        _isLoading = false;
      });
    }
  }

  Future<void> _updatePref(String key, bool value) async {
    setState(() {
      _tempPrefs[key] = value;
    });
    await _supabaseService.updateNotificationPreferences(_tempPrefs);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('Notification Center', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF0F172A), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFF59E0B)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Customize your elite alerts to stay ahead of the luxury market.', 
                    style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.5)),
                  const SizedBox(height: 32),
                  
                  _buildSectionHeader('PROPERTY ALERTS'),
                  _buildSettingTile(
                    'Price Drops', 
                    'Get notified when sanctuaries you follow have a price revision.', 
                    Icons.trending_down_rounded, 
                    'price_drops',
                  ),
                  _buildSettingTile(
                    'New Hand-Picked Listings', 
                    'Immediate alerts for new properties matching your profile.', 
                    Icons.auto_awesome_rounded, 
                    'new_listings',
                  ),
                  
                  const SizedBox(height: 32),
                  _buildSectionHeader('INTERACTION'),
                  _buildSettingTile(
                    'Inquiry Status', 
                    'Real-time updates on your current property inquiries.', 
                    Icons.chat_bubble_outline_rounded, 
                    'inquiry_updates',
                  ),
                  
                  const SizedBox(height: 32),
                  _buildSectionHeader('EXCLUSIVE CONTENT'),
                  _buildSettingTile(
                    'Elite Market Insights', 
                    'Weekly reports on global luxury real estate trends.', 
                    Icons.insights_rounded, 
                    'marketing',
                  ),
                  
                  const SizedBox(height: 48),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A).withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF0F172A).withOpacity(0.05)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded, color: Color(0xFF0F172A)),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'Preferences are updated instantly and synced across your devices.',
                            style: TextStyle(fontSize: 12, color: const Color(0xFF0F172A).withOpacity(0.7)),
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

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Color(0xFFF59E0B),
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildSettingTile(String title, String subtitle, IconData icon, String prefKey) {
    bool value = _tempPrefs[prefKey] ?? false;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.04)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A).withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFF0F172A), size: 22),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A))),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ),
        trailing: Switch.adaptive(
          value: value,
          activeColor: const Color(0xFFF59E0B),
          onChanged: (bool newValue) => _updatePref(prefKey, newValue),
        ),
      ),
    );
  }
}
