import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:async';
import '../../core/services/supabase_service.dart';
import '../../core/models/category.dart';
import '../../core/models/property.dart';
import '../../core/models/profile.dart';
import '../../core/models/inquiry.dart';
import '../../core/models/agency_settings.dart';
import '../../core/models/owner.dart';
import '../../core/models/rental.dart';
import '../../core/models/payout.dart';
import '../../core/models/employee.dart';
import '../../core/models/office_expense.dart';
import '../../core/models/notification.dart';
import 'property_form_dialog.dart';
import 'property_preview_dialog.dart';
import 'rent_property_dialog.dart';
import 'customer_dossier_dialog.dart';
import 'walk_in_registration_dialog.dart';
import '../../main_admin.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  bool _isSidebarCollapsed = false;
  final double _collapsedWidth = 90;
  final double _expandedWidth = 260;
  final SupabaseService _supabaseService = SupabaseService();
  
  late Future<List<Property>> _propertiesFuture;
  late Future<List<Inquiry>> _inquiriesFuture;
  late Future<List<Profile>> _profilesFuture;
  late Future<List<Owner>> _ownersFuture;
  late Future<List<Rental>> _rentalsFuture;
  late Future<List<Payout>> _payoutsFuture;
  late Future<List<Employee>> _employeesFuture;
  late Future<List<OfficeExpense>> _expensesFuture;
  late Future<AgencySettings> _agencySettingsFuture;

  // Settings Controllers
  final _agencyNameCtrl = TextEditingController();
  final _agencyEmailCtrl = TextEditingController();
  final _agencyPhoneCtrl = TextEditingController();
  final _agencyAddressCtrl = TextEditingController();
  final _agencyLogoCtrl = TextEditingController();
  final _supportPhoneCtrl = TextEditingController();
  String? _currencySymbol = r'$';
  bool _isMaintenanceMode = false;
  bool _showBedsOnCard = true;
  bool _showBathsOnCard = true;
  bool _showTypeOnCard = true;
  bool _showSizeOnCard = false;
  bool _isSavingSettings = false;
  bool _isUploadingLogo = false;
  Uint8List? _logoBytes;

  // Search State
  String _searchQuery = '';
  final _searchController = TextEditingController();

  // Real-time Notifications
  StreamSubscription<List<Inquiry>>? _inquirySub;
  List<Inquiry> _realtimeInquiries = [];
  int _newInquiryCount = 0;
  bool _enableInquiryPopups = true;
  
  // Table Scroll Controllers
  final ScrollController _inquiryScrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _refreshSettings();
    _refreshAll();
    _startInquirySubscription();
  }

  @override
  void dispose() {
    _inquirySub?.cancel();
    _searchController.dispose();
    _agencyNameCtrl.dispose();
    _agencyEmailCtrl.dispose();
    _agencyPhoneCtrl.dispose();
    _agencyAddressCtrl.dispose();
    _agencyLogoCtrl.dispose();
    _supportPhoneCtrl.dispose();
    _inquiryScrollCtrl.dispose();
    super.dispose();
  }

  void _startInquirySubscription() {
    _inquirySub?.cancel();
    _inquirySub = _supabaseService.adminInquiryStream().listen((inquiries) {
      if (mounted) {
        final newInquiries = inquiries.where((inq) => inq.status == 'New').toList();
        final newCount = newInquiries.length;
        
        // Show popup if count increased
        if (newCount > _newInquiryCount && _enableInquiryPopups && inquiries.isNotEmpty) {
          try {
            final latestInq = inquiries.firstWhere((inq) => inq.status == 'New');
            _showInquiryPopup(latestInq);
          } catch (_) {}
        }

        setState(() {
          _realtimeInquiries = inquiries;
          _newInquiryCount = newCount;
        });
      }
    });
  }

  void _showInquiryPopup(Inquiry inq) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 8),
        backgroundColor: Colors.transparent,
        elevation: 0,
        content: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3)),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8)),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFFF59E0B).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.forum_rounded, color: Color(0xFFF59E0B), size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('New Lead Received!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text('${inq.customerName} is inquiring about ${inq.property?.title ?? "a property"}', 
                      style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  setState(() => _selectedIndex = 3);
                },
                child: const Text('VIEW', style: TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _refreshSettings() {
    _agencySettingsFuture = _supabaseService.fetchAgencySettings().then((settings) {
      if (mounted) {
        setState(() {
          _agencyNameCtrl.text = settings.name;
          _agencyEmailCtrl.text = settings.email ?? '';
          _agencyPhoneCtrl.text = settings.phone ?? '';
          _agencyAddressCtrl.text = settings.address ?? '';
          _agencyLogoCtrl.text = settings.logoUrl ?? '';
          _supportPhoneCtrl.text = settings.supportPhone ?? '';
          _currencySymbol = settings.currencySymbol;
          _isMaintenanceMode = settings.isMaintenanceMode;
          _showBedsOnCard = settings.showBedsOnCard;
          _showBathsOnCard = settings.showBathsOnCard;
          _showTypeOnCard = settings.showTypeOnCard;
          _showSizeOnCard = settings.showSizeOnCard;
          _enableInquiryPopups = settings.enableInquiryPopups;
        });
      }
      return settings;
    });
  }

  void _refreshAll() {
    setState(() {
      _propertiesFuture = _supabaseService.fetchProperties();
      _profilesFuture = _supabaseService.fetchProfiles();
      _inquiriesFuture = _supabaseService.fetchInquiries();
      _ownersFuture = _supabaseService.fetchOwners();
      _payoutsFuture = _supabaseService.fetchPayouts();
      _employeesFuture = _supabaseService.fetchEmployees();
      _expensesFuture = _supabaseService.fetchOfficeExpenses();
    });
    
    // Manually sync realtime list as fallback if stream is delayed or disabled
    _supabaseService.fetchInquiries().then((inquiries) {
      if (mounted) {
        setState(() {
          _realtimeInquiries = inquiries;
          _newInquiryCount = inquiries.where((inq) => inq.status == 'New').length;
        });
      }
    });
  }

  Future<Map<String, int>> _fetchDashboardStats() async {
    final props = await _propertiesFuture;
    final users = await _profilesFuture;
    final owners = await _ownersFuture;
    
    final active = props.where((p) => p.status == 'Available').length;
    final rented = props.where((p) => p.status == 'Rented' || p.status == 'Sold').length;

    return {
      'properties': props.length,
      'active_listings': active,
      'deals_closed': rented,
      'users': users.length,
      'inquiries': _realtimeInquiries.length,
      'owners': owners.length,
    };
  }

  Future<void> _broadcastAnnouncement(String title, String body, String type) async {
    try {
      await _supabaseService.broadcastAnnouncement(title, body, type);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Announcement broadcasted successfully!')));
      _refreshAll();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Broadcast failed: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _pickAndUploadLogo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    setState(() => _isUploadingLogo = true);
    
    // REAL Supabase Storage Upload
    try {
      final bytes = result.files.first.bytes;
      if (bytes == null) throw Exception('Could not read file data');
      
      final fileName = result.files.first.name;
      final oldUrl = _agencyLogoCtrl.text;
      final realUrl = await _supabaseService.uploadAgencyLogo(bytes, fileName);
      
      if (mounted) {
        setState(() {
          _agencyLogoCtrl.text = realUrl;
          _logoBytes = bytes;
          _isUploadingLogo = false;
        });

        // Purge old logo from branding bucket
        if (oldUrl.isNotEmpty && oldUrl.contains('branding')) {
          try {
            await _supabaseService.deleteImages([oldUrl], bucket: 'branding');
          } catch (e) {
            print('Branding cleanup failed: $e');
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Logo updated and old version purged from storage.')));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingLogo = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _saveAgencySettings() async {
    setState(() => _isSavingSettings = true);
    try {
      final currentSettings = await _agencySettingsFuture;
      final updatedSettings = currentSettings.copyWith(
        name: _agencyNameCtrl.text,
        email: _agencyEmailCtrl.text,
        phone: _agencyPhoneCtrl.text,
        address: _agencyAddressCtrl.text,
        logoUrl: _agencyLogoCtrl.text,
        supportPhone: _supportPhoneCtrl.text,
        currencySymbol: _currencySymbol ?? r'$',
        isMaintenanceMode: _isMaintenanceMode,
        showBedsOnCard: _showBedsOnCard,
        showBathsOnCard: _showBathsOnCard,
        showTypeOnCard: _showTypeOnCard,
        showSizeOnCard: _showSizeOnCard,
        enableInquiryPopups: _enableInquiryPopups,
      );
      
      await _supabaseService.updateAgencySettings(updatedSettings);
      
      _refreshSettings();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Agency settings updated successfully!')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving settings: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSavingSettings = false);
    }
  }

  Future<void> _updateUIFlag(String field, bool value) async {
    try {
      final currentSettings = await _agencySettingsFuture;
      final settingsMap = currentSettings.toJson();
      settingsMap[field] = value;
      
      final updatedSettings = AgencySettings.fromJson(settingsMap);
      await _supabaseService.updateAgencySettings(updatedSettings);
      
      // Update local state without full refresh if possible, but full refresh is safer
      _refreshSettings();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error updating $field: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Row(
        children: [
          // Adaptive Sidebar
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOutQuart,
            width: _isSidebarCollapsed ? _collapsedWidth : _expandedWidth,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(right: BorderSide(color: theme.dividerColor.withOpacity(0.1), width: 1)),
              boxShadow: [
                if (!_isSidebarCollapsed)
                  BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(4, 0)),
              ],
            ),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLogoSection(theme),
                        const SizedBox(height: 16),
                        _buildNavItem(0, Icons.dashboard_rounded, 'Overview'),
                        _buildNavItem(1, Icons.maps_home_work_rounded, 'Properties'),
                        _buildNavItem(2, Icons.person_search_rounded, 'Owners'),
                        _buildNavItem(3, Icons.forum_rounded, 'Inquiries'),
                        _buildNavItem(4, Icons.people_alt_rounded, 'Customers'),
                        _buildNavItem(5, Icons.account_balance_wallet_rounded, 'Financials'),
                        _buildNavItem(10, Icons.analytics_rounded, 'Business Reports'),
                        _buildNavItem(9, Icons.podcasts_rounded, 'Broadcasting'),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 200),
                            opacity: _isSidebarCollapsed ? 0.0 : 1.0,
                            child: const Divider(color: Colors.white10),
                          ),
                        ),
                        _buildNavItem(6, Icons.business_center_rounded, 'Office HQ'),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 1),
                _buildNavItem(7, Icons.settings_rounded, 'Settings'),
                _buildNavItem(7, Icons.logout_rounded, 'Sign Out', isDestructive: true),
                const SizedBox(height: 16),
              ],
            ),
          ),
          
          // Main Content Dynamic Routing
          Expanded(
            child: Column(
              children: [
                // Global Header
                _buildHeader(theme),
                // Dynamic View
                Expanded(
                  child: _selectedIndex == 9 
                    ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 20.0),
                        child: _buildCurrentView(theme),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(40.0),
                        physics: const BouncingScrollPhysics(),
                        child: _buildCurrentView(theme),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoSection(ThemeData theme) {
    if (_isSidebarCollapsed) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: _agencyLogoCtrl.text.isNotEmpty 
                ? Image.network(_agencyLogoCtrl.text, width: 24, height: 24, fit: BoxFit.contain)
                : const Icon(Icons.real_estate_agent, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 12),
            IconButton(
              icon: const Icon(Icons.chevron_right_rounded),
              color: Colors.grey[400],
              onPressed: () => setState(() => _isSidebarCollapsed = false),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 32, 12, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _agencyLogoCtrl.text.isNotEmpty 
                  ? Image.network(_agencyLogoCtrl.text, width: 24, height: 24, fit: BoxFit.contain)
                  : const Icon(Icons.real_estate_agent, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              const Text('Admin Portal', 
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            color: Colors.grey[400],
            onPressed: () => setState(() => _isSidebarCollapsed = true),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentView(ThemeData theme) {
    switch (_selectedIndex) {
      case 0: // Overview
        return FutureBuilder<List<Payout>>(
          future: _payoutsFuture,
          builder: (context, snapshot) {
            final payouts = snapshot.data ?? [];
            double commissionTotal = 0;
            for (var p in payouts) {
              commissionTotal += p.agencyCut;
            }

            return _buildOverview(commissionTotal);
          },
        );
      case 1: // Properties
        return _buildPropertiesTable(theme);
      case 2: // Owners
        return _buildOwnersView(theme);
      case 3: // Inquiries
        return _buildInquiriesTable(theme);
      case 4: // Customers
        return _buildCustomersTable(theme);
      case 5: // Financials
        return FutureBuilder<List<dynamic>>(
          future: Future.wait([_payoutsFuture, _employeesFuture, _expensesFuture]),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            final payouts = snapshot.data?[0] as List<Payout>? ?? [];
            final employees = snapshot.data?[1] as List<Employee>? ?? [];
            final expenses = snapshot.data?[2] as List<OfficeExpense>? ?? [];
            
            double totalCommissions = 0;
            for (var p in payouts) totalCommissions += p.agencyCut;
            
            double totalSalaries = 0;
            for (var e in employees) totalSalaries += e.salary;
            
            double totalExpenses = 0;
            for (var ex in expenses) totalExpenses += ex.amount;

            return _buildFinancialsView(theme, totalCommissions, totalSalaries, totalExpenses, payouts);
          },
        );
      case 6: // Office HQ
        return _buildOfficeHQView(theme);
      case 7: // Settings
        return _buildSettingsView(theme);
      case 8: // Categories
        return _buildCategoryManager(theme);
      case 9: // Broadcasting
        return _buildBroadcastingView(theme);
      case 10: // Reports
        return _buildReportsView(theme);
      default:
        return const Center(child: Text('Under Construction...', style: TextStyle(fontSize: 18, color: Colors.grey)));
    }
  }

  Widget _buildCategoryManagerInDialog(ThemeData theme, StateSetter setDialogState) {
    final nameCtrl = TextEditingController();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Define and manage classifications for your elite inventory',
            style: TextStyle(color: Colors.grey, fontSize: 14)),
        const SizedBox(height: 24),
        
        // Modern Input Bar
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Row(
            children: [
              const SizedBox(width: 16),
              const Icon(Icons.add_circle_outline_rounded, color: Color(0xFFF59E0B)),
              Expanded(
                child: TextField(
                  controller: nameCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'e.g. Luxury Beachfront',
                    hintStyle: TextStyle(color: Colors.grey[500]),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (nameCtrl.text.trim().isNotEmpty) {
                    await _supabaseService.addCategory(nameCtrl.text.trim());
                    nameCtrl.clear();
                    setDialogState(() {});
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF59E0B),
                  foregroundColor: const Color(0xFF0F172A),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text('Add Category', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        
        // Category List
        FutureBuilder<List<PropertyCategory>>(
          future: _supabaseService.fetchCategories(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            final cats = snapshot.data ?? [];
            if (cats.isEmpty) return const Center(child: Text('No categories yet.', style: TextStyle(color: Colors.grey)));

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: cats.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final cat = cats[index];
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: theme.colorScheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                        child: Icon(Icons.category_rounded, color: theme.colorScheme.primary, size: 18),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(cat.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                        onPressed: () async {
                          await _supabaseService.deleteCategory(cat.id);
                          setDialogState(() {});
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildCategoryManager(ThemeData theme) {
    final nameCtrl = TextEditingController();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Property Classification',
                    style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -1.0,
                        color: Colors.white)),
                const SizedBox(height: 4),
                Text('Define and manage classifications for your elite inventory',
                    style: TextStyle(color: Colors.grey[400], fontSize: 14)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 40),
        
        // Modern Input Bar
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10)),
            ],
          ),
          child: Row(
            children: [
              const SizedBox(width: 16),
              const Icon(Icons.add_circle_outline_rounded, color: Color(0xFFF59E0B)),
              Expanded(
                child: TextField(
                  controller: nameCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'New Category Name (e.g. Luxury Beachfront)',
                    hintStyle: TextStyle(color: Colors.grey[500]),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (nameCtrl.text.trim().isNotEmpty) {
                    await _supabaseService.addCategory(nameCtrl.text.trim());
                    setState(() {});
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF59E0B),
                  foregroundColor: const Color(0xFF0F172A),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                child: const Text('Add Category', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 48),

        FutureBuilder<List<dynamic>>(
          future: Future.wait([
            _supabaseService.fetchCategories(),
            _supabaseService.fetchCategoryStats(),
          ]),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFFF59E0B)));
            }
            final categories = (snapshot.data?[0] as List<PropertyCategory>?) ?? [];
            final stats = (snapshot.data?[1] as Map<String, int>?) ?? {};

            if (categories.isEmpty) {
              return Center(
                child: Column(
                  children: [
                    const SizedBox(height: 60),
                    Icon(Icons.category_outlined, size: 64, color: Colors.grey[800]),
                    const SizedBox(height: 16),
                    Text('No categories defined yet', style: TextStyle(color: Colors.grey[600])),
                  ],
                ),
              );
            }

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 1.3,
                crossAxisSpacing: 24,
                mainAxisSpacing: 24,
              ),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final cat = categories[index];
                final count = stats[cat.name] ?? 0;
                
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF1E293B),
                        const Color(0xFF0F172A).withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF59E0B).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.layers_rounded, color: Color(0xFFF59E0B), size: 24),
                            ),
                            const Spacer(),
                            Text(cat.name, 
                              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
                            const SizedBox(height: 4),
                            Text('$count Properties', 
                              style: TextStyle(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                      Positioned(
                        top: 12,
                        right: 12,
                        child: IconButton(
                          icon: Icon(Icons.delete_outline_rounded, size: 20, color: Colors.red[400]?.withOpacity(0.5)),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                backgroundColor: const Color(0xFF0F172A),
                                title: const Text('Delete Category?', style: TextStyle(color: Colors.white)),
                                content: Text('This will remove the "${cat.name}" classification.', style: const TextStyle(color: Colors.grey)),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                  TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              await _supabaseService.deleteCategory(cat.id);
                              setState(() {});
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildOverview(double commissionTotal) {
    final theme = Theme.of(context);
    return FutureBuilder<Map<String, int>>(
      future: _fetchDashboardStats(),
      builder: (context, snapshot) {
        final stats = snapshot.data ?? {'properties': 0, 'users': 0, 'inquiries': 0};
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildStatCard('Total Listings', stats['properties']?.toString() ?? '0', Icons.inventory_2_rounded, Colors.blue),
                const SizedBox(width: 16),
                _buildStatCard('Active Now', stats['active_listings']?.toString() ?? '0', Icons.online_prediction_rounded, Colors.teal),
                const SizedBox(width: 16),
                _buildStatCard('Deals Closed', stats['deals_closed']?.toString() ?? '0', Icons.handshake_rounded, Colors.purple),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildStatCard('Total Revenue', '\$${commissionTotal.toStringAsFixed(0)}', Icons.payments_rounded, Colors.green),
                const SizedBox(width: 16),
                _buildStatCard('Active Leads', stats['inquiries']?.toString() ?? '0', Icons.forum_rounded, Colors.orange),
                const SizedBox(width: 16),
                _buildStatCard('Total Clients', stats['users']?.toString() ?? '0', Icons.people_alt_rounded, Colors.indigo),
              ],
            ),
            const SizedBox(height: 32),
            _buildPropertiesTable(theme, hideSearch: false),
          ],
        );
      },
    );
  }

  Widget _buildHeader(ThemeData theme) {
    String title = 'Agency Overview';
    switch (_selectedIndex) {
      case 0: title = 'Dashboard Overview'; break;
      case 1: title = 'Property Inventory'; break;
      case 2: title = 'Landlord Network'; break;
      case 3: title = 'Customer Inquiries'; break;
      case 4: title = 'Registered Clients'; break;
      case 5: title = 'Revenue & Profit'; break;
      case 6: title = 'Office Management'; break;
      case 7: title = 'Platform Settings'; break;
      case 8: title = 'Property Classifications'; break;
      case 9: title = 'Announcement Broadcast'; break;
    }

    final isHighDensity = _selectedIndex == 9;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 32, vertical: isHighDensity ? 8 : 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
          Row(
            children: [
              IconButton(
                icon: Icon(theme.brightness == Brightness.dark ? Icons.light_mode : Icons.dark_mode),
                onPressed: () {
                  themeNotifier.value = theme.brightness == Brightness.dark ? ThemeMode.light : ThemeMode.dark;
                },
              ),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                offset: const Offset(0, 48),
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.notifications_none_rounded),
                    if (_newInquiryCount > 0)
                      Positioned(
                        right: -4, top: -4,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                          constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                          child: Text('$_newInquiryCount', style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                        ),
                      ),
                  ],
                ),
                onSelected: (val) {
                  if (val == 'inquiry') setState(() => _selectedIndex = 3);
                },
                itemBuilder: (context) => [
                  if (_newInquiryCount > 0)
                    PopupMenuItem(
                      value: 'inquiry',
                      child: Row(
                        children: [
                          const Icon(Icons.forum_rounded, size: 16, color: Colors.blue),
                          const SizedBox(width: 8),
                          Text('$_newInquiryCount New Inquiries', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                    ),
                  const PopupMenuItem(child: Text('✅ System Health Normal', style: TextStyle(color: Colors.grey, fontSize: 13))),
                ],
              ),
              const SizedBox(width: 8),
              IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _refreshAll),
            ],
          )
        ],
      ),
    );
  }

  // --- INQUIRIES PANEL ---

  Widget _buildInquiriesHeader(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Active Lead Inbox', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
              Text('Managing inquiries from property listings', style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5))),
            ],
          ),
        ),
        const SizedBox(width: 24),
        Expanded(child: _buildAdminSearchBar('Search leads by name or email...')),
        const SizedBox(width: 24),
        _buildMiniStat('Total Leads', _realtimeInquiries.length.toString(), Icons.analytics_rounded),
      ],
    );
  }

  Widget _buildInquiriesTable(ThemeData theme) {
    // Search filtering for realtime list
    final filteredInquiries = _realtimeInquiries.where((inq) {
      final query = _searchQuery.toLowerCase();
      return inq.customerName.toLowerCase().contains(query) || 
             inq.customerEmail.toLowerCase().contains(query);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInquiriesHeader(theme),
        const SizedBox(height: 32),
        if (filteredInquiries.isEmpty && _realtimeInquiries.isNotEmpty)
           const Padding(
             padding: EdgeInsets.all(60),
             child: Center(child: Text('No matching leads found.', style: TextStyle(color: Colors.grey, fontSize: 16))),
           )
        else if (_realtimeInquiries.isEmpty)
          Center(
            child: Column(
              children: [
                const SizedBox(height: 100),
                Icon(Icons.mail_outline_rounded, size: 80, color: Colors.grey.withOpacity(0.2)),
                const SizedBox(height: 24),
                const Text('Your lead inbox is empty.', style: TextStyle(color: Colors.grey, fontSize: 18, fontWeight: FontWeight.w500)),
              ],
            ),
          )
        else
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 24, offset: const Offset(0, 12))],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                      // Table Header
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        child: Row(
                          children: [
                            SizedBox(width: 40, child: Text('#', style: _headerStyle(theme))),
                            Expanded(flex: 3, child: Text('Lead Details', style: _headerStyle(theme))),
                            Expanded(flex: 2, child: Text('Phone', style: _headerStyle(theme))),
                            Expanded(flex: 3, child: Text('Property', style: _headerStyle(theme))),
                            Expanded(flex: 3, child: Text('Message', style: _headerStyle(theme))),
                            Expanded(flex: 3, child: Text('Status/Actions', style: _headerStyle(theme), textAlign: TextAlign.right)),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredInquiries.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final inq = filteredInquiries[index];
                          final isNew = inq.status == 'New';
                          
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                            child: Row(
                              children: [
                                SizedBox(width: 40, child: Text('${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                                Expanded(
                                  flex: 3, 
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(inq.customerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                      Text(inq.customerEmail, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                    ],
                                  )
                                ),
                                Expanded(
                                  flex: 2, 
                                  child: Text(inq.customerPhone ?? 'No Phone', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))
                                ),
                                Expanded(
                                  flex: 3, 
                                  child: InkWell(
                                    onTap: inq.property == null ? null : () async {
                                      await showDialog(
                                        context: context,
                                        builder: (_) => PropertyPreviewDialog(property: inq.property!),
                                      );
                                      _refreshAll();
                                    },
                                    borderRadius: BorderRadius.circular(8),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 32, height: 32,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(6),
                                            image: inq.property?.mainImageUrl != null 
                                              ? DecorationImage(image: NetworkImage(inq.property!.mainImageUrl), fit: BoxFit.cover)
                                              : null,
                                            color: theme.colorScheme.surfaceVariant,
                                          ),
                                          child: inq.property?.mainImageUrl == null ? const Icon(Icons.home_rounded, size: 16, color: Colors.grey) : null,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                inq.property?.title ?? 'Unknown', 
                                                style: TextStyle(
                                                  fontSize: 13, 
                                                  fontWeight: FontWeight.bold,
                                                  color: inq.property != null ? theme.colorScheme.primary : null,
                                                  overflow: TextOverflow.ellipsis
                                                )
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 3, 
                                  child: Text(
                                    inq.message, 
                                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  )
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      if (isNew) 
                                        IconButton(
                                          icon: const Icon(Icons.check_circle_outline, color: Colors.blue, size: 20),
                                          tooltip: 'Mark Contacted',
                                          onPressed: () async {
                                            await _supabaseService.updateInquiryStatus(inq.id, 'Contacted');
                                            _refreshAll();
                                          },
                                        ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                                        tooltip: 'Delete Permanently',
                                        onPressed: () async {
                                          final confirm = await showDialog<bool>(
                                            context: context,
                                            builder: (ctx) => AlertDialog(
                                              title: const Text('Delete Inquiry'),
                                              content: const Text('Are you sure you want to permanently delete this inquiry?'),
                                              actions: [
                                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                                TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: const TextStyle(color: Colors.red))),
                                              ],
                                            ),
                                          );
                                          if (confirm == true) {
                                            await _supabaseService.deleteInquiry(inq.id);
                                            _refreshAll();
                                          }
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.archive_outlined, color: Colors.redAccent, size: 20),
                                        tooltip: 'Archive',
                                        onPressed: () async {
                                          await _supabaseService.updateInquiryStatus(inq.id, 'Archived');
                                          _refreshAll();
                                        },
                                      ),
                                      if (!isNew)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                                          child: const Text('CONTACTED', style: TextStyle(color: Colors.green, fontSize: 9, fontWeight: FontWeight.bold)),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
       ],
    );
  }

  Widget _buildActionChip(IconData icon, String label, VoidCallback onTap, {bool isDestructive = false}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isDestructive ? Colors.red.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: isDestructive ? Colors.red : Colors.blue),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isDestructive ? Colors.red : Colors.blue)),
          ],
        ),
      ),
    );
  }

  // --- CUSTOMERS PANEL ---

  Widget _buildCustomersTable(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(child: Text('Registered Users', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
            const SizedBox(width: 24),
            Expanded(child: _buildAdminSearchBar('Search customers by name or email...')),
            const SizedBox(width: 24),
            ElevatedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => WalkInRegistrationDialog(
                    onSuccess: _refreshAll,
                  ),
                );
              },
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Register Walk-In Client'),
              style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.primary, foregroundColor: Colors.white),
            )
          ],
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.02), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  children: [
                    SizedBox(width: 40, child: Text('#', style: _headerStyle(theme))),
                    Expanded(flex: 3, child: Text('User Profile', style: _headerStyle(theme))),
                    Expanded(flex: 2, child: Text('Phone Number', style: _headerStyle(theme))),
                    Expanded(flex: 2, child: Text('Account ID', style: _headerStyle(theme))),
                    Expanded(flex: 2, child: Text('Role', style: _headerStyle(theme))),
                    Expanded(flex: 2, child: Text('Joined On', style: _headerStyle(theme))),
                    Expanded(flex: 1, child: Text('Actions', style: _headerStyle(theme), textAlign: TextAlign.right)),
                  ],
                ),
              ),
              const Divider(height: 1),
              FutureBuilder<List<Profile>>(
                future: _profilesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) return const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()));
                  if (snapshot.hasError) return Padding(padding: const EdgeInsets.all(40), child: Center(child: Text('Error: ${snapshot.error}')));
                  
                  final allProfiles = snapshot.data ?? [];
                  final filteredProfiles = allProfiles.where((p) {
                    final query = _searchQuery.toLowerCase();
                    return (p.fullName?.toLowerCase().contains(query) ?? false) || 
                           (p.phone?.toLowerCase().contains(query) ?? false);
                  }).toList();

                  if (filteredProfiles.isEmpty) return const Padding(padding: EdgeInsets.all(40), child: Center(child: Text('No matching customers found.', style: TextStyle(color: Colors.grey))));

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredProfiles.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final profile = filteredProfiles[index];
                      final isAdmin = profile.role == 'admin';
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                        child: Row(
                          children: [
                            SizedBox(width: 40, child: Text('${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                            // User Profile Column
                            Expanded(
                              flex: 3, 
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                                    backgroundImage: profile.avatarUrl != null ? NetworkImage(profile.avatarUrl!) : null,
                                    child: profile.avatarUrl == null ? Icon(Icons.person, color: theme.colorScheme.primary) : null,
                                  ),
                                  const SizedBox(width: 16),
                                  Text(profile.fullName ?? 'Unknown User', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                ],
                                )
                            ),
                            // Phone
                            Expanded(flex: 2, child: Text(profile.phone ?? 'No Phone', style: const TextStyle(fontWeight: FontWeight.w500))),
                            // ID
                            Expanded(flex: 2, child: Text(profile.id.substring(0, 8), style: const TextStyle(color: Colors.grey, fontFamily: 'monospace'))),
                            // Role Badge
                            Expanded(
                              flex: 2,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(color: isAdmin ? Colors.purple.withOpacity(0.1) : Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                                  child: Text(profile.role.toUpperCase(), style: TextStyle(color: isAdmin ? Colors.purple : Colors.blue, fontSize: 11, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ),
                            // Date Column
                            Expanded(flex: 2, child: Text(DateFormat('MMM dd, yyyy').format(profile.createdAt), style: const TextStyle(fontWeight: FontWeight.w500))),
                            // Action Menu
                            Expanded(
                              flex: 1,
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: PopupMenuButton<String>(
                                  icon: Icon(Icons.more_vert_rounded, size: 20, color: theme.iconTheme.color?.withOpacity(0.5)),
                                  onSelected: (val) {
                                    if (val == 'dossier') {
                                      showDialog<bool>(
                                        context: context,
                                        builder: (_) => CustomerDossierDialog(customer: profile),
                                      ).then((refresh) {
                                        if (refresh == true) _refreshAll();
                                      });
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(value: 'dossier', child: Text('View Full Dossier', style: TextStyle(fontWeight: FontWeight.bold))),
                                    const PopupMenuItem(value: 'ban', child: Text('Suspend Account', style: TextStyle(color: Colors.red))),
                                  ],
                                )
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              )
            ],
          ),
        ),
      ],
    );
  }

  // --- PROPERTIES PANEL ---

  Widget _buildPropertiesTable(ThemeData theme, {bool hideSearch = false}) {
    final isDark = theme.brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(child: Text('Property Directory', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
            if (!hideSearch) ...[
              const SizedBox(width: 24),
              Expanded(child: _buildAdminSearchBar('Search properties by title, type, or category...')),
            ],
            const SizedBox(width: 16),
            OutlinedButton.icon(
              icon: const Icon(Icons.category_outlined, size: 18),
              label: const Text('Manage Categories'),
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.primary,
                side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.5)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => Dialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    backgroundColor: const Color(0xFF0F172A),
                    child: Container(
                      width: 600,
                      height: 700,
                      padding: const EdgeInsets.all(40),
                      child: StatefulBuilder(
                        builder: (context, setDialogState) {
                          return SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Categories', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                                    IconButton(
                                      icon: const Icon(Icons.close, color: Colors.white),
                                      onPressed: () => Navigator.pop(context),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                _buildCategoryManagerInDialog(theme, setDialogState),
                              ],
                            ),
                          );
                        }
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text('Add Property'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary, foregroundColor: theme.colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 0,
              ),
              onPressed: () async { 
                final success = await showDialog<bool>(context: context, builder: (_) => const PropertyFormDialog());
                if (success == true) _refreshAll();
              },
            ),
          ],
        ),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.02), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  children: [
                    Expanded(flex: 1, child: Text('#', style: _headerStyle(theme))),
                    Expanded(flex: 1, child: Text('Preview', style: _headerStyle(theme))),
                    Expanded(flex: 4, child: Text('Property Details', style: _headerStyle(theme))),
                    Expanded(flex: 2, child: Text('Neighborhood', style: _headerStyle(theme))),
                    Expanded(flex: 2, child: Text('Status', style: _headerStyle(theme))),
                    Expanded(flex: 1, child: Text('Actions', style: _headerStyle(theme), textAlign: TextAlign.right)),
                  ],
                ),
              ),
              const Divider(height: 1),
              FutureBuilder<List<Property>>(
                future: _propertiesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) return const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()));
                  if (snapshot.hasError) return Padding(padding: const EdgeInsets.all(40), child: Center(child: Text('Error: ${snapshot.error}')));
                  
                  final allProps = snapshot.data ?? [];
                  final filteredProps = allProps.where((p) {
                    final query = _searchQuery.toLowerCase();
                    return p.title.toLowerCase().contains(query) || 
                           p.type.toLowerCase().contains(query) ||
                           (p.categoryName?.toLowerCase().contains(query) ?? false);
                  }).toList();

                  if (filteredProps.isEmpty) return const Padding(padding: EdgeInsets.all(40), child: Center(child: Text('No matching properties found.', style: TextStyle(color: Colors.grey))));

                  return ListView.separated(
                    shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: filteredProps.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final property = filteredProps[index];
                      final isAvailable = property.status == 'Available';

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        child: Row(
                          children: [
                            // 1. Numbering
                            Expanded(
                              flex: 1, 
                              child: Text('#${index + 1}', style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5), fontWeight: FontWeight.bold))
                            ),
                            
                            // 2. Thumbnail
                            Expanded(
                              flex: 1,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                  child: InkWell(
                                    onTap: () => _showPropertyPreview(property),
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.surfaceVariant,
                                        borderRadius: BorderRadius.circular(8),
                                        image: DecorationImage(
                                          image: NetworkImage(property.mainImageUrl),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  ),
                              ),
                            ),
                            
                            // 3. Title and Info
                            Expanded(
                              flex: 4, 
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(property.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(color: theme.colorScheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                                        child: Text(property.type.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                                      ),
                                      const SizedBox(width: 8),
                                      Text('${property.currency}${property.price.toStringAsFixed(0)}', style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6), fontSize: 13, fontWeight: FontWeight.w600)),
                                      const SizedBox(width: 12),
                                      Icon(Icons.king_bed_rounded, size: 14, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.4)),
                                      const SizedBox(width: 4),
                                      Text('${property.beds}', style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6))),
                                      const SizedBox(width: 12),
                                      Icon(Icons.bathtub_rounded, size: 14, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.4)),
                                      const SizedBox(width: 4),
                                      Text('${property.baths}', style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6))),
                                    ],
                                  ),
                                ],
                              )
                            ),

                            // 4. Neighborhood Column
                            Expanded(
                              flex: 2,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Row(
                                  children: [
                                    if (property.location != null) ...[
                                      Icon(Icons.location_on_rounded, size: 14, color: theme.colorScheme.primary.withOpacity(0.7)),
                                      const SizedBox(width: 8),
                                      Text(
                                        property.location!,
                                        style: TextStyle(
                                          color: theme.colorScheme.primary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                            
                            // 5. Status Badge
                            Expanded(
                              flex: 2,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isAvailable ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: isAvailable ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(width: 6, height: 6, decoration: BoxDecoration(color: isAvailable ? Colors.green : Colors.orange, shape: BoxShape.circle)),
                                      const SizedBox(width: 8),
                                      Text(property.status, style: TextStyle(color: isAvailable ? Colors.green : Colors.orange, fontSize: 11, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            
                            // 5. Actions
                            Expanded(
                              flex: 1,
                              child: Align(
                                alignment: Alignment.centerRight, 
                                child: PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert_rounded, size: 20),
                                  onSelected: (value) async {
                                    if (value == 'preview') {
                                      _showPropertyPreview(property);
                                    } else if (value == 'rent') {
                                      final success = await showDialog<bool>(context: context, builder: (_) => RentPropertyDialog(property: property));
                                      if (success == true) _refreshAll();
                                    } else if (value == 'edit') {
                                      final success = await showDialog<bool>(context: context, builder: (_) => PropertyFormDialog(property: property));
                                      if (success == true) _refreshAll();
                                    } else if (value == 'delete') {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (c) => AlertDialog(
                                          title: const Text('Delete Property'),
                                          content: const Text('Are you sure you want to delete this property? This action cannot be undone.'),
                                          actions: [
                                            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                                            TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                                          ],
                                        ),
                                      );
                                      if (confirm == true) {
                                        await _supabaseService.deleteProperty(property.id);
                                        _refreshAll();
                                      }
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(value: 'preview', child: Row(children: [Icon(Icons.visibility_outlined, size: 18), SizedBox(width: 8), Text('Preview Listing')])),
                                    const PopupMenuItem(value: 'rent', child: Row(children: [Icon(Icons.key_rounded, size: 18), SizedBox(width: 8), Text('Mark as Rented')])),
                                    const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined, size: 18), SizedBox(width: 8), Text('Edit Details')])),
                                    const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, size: 18, color: Colors.red), SizedBox(width: 8), Text('Delete Listing', style: TextStyle(color: Colors.red))])),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showPropertyPreview(Property property) {
    showDialog(
      context: context,
      builder: (context) => PropertyPreviewDialog(property: property),
    );
  }

  // --- SETTINGS PANEL ---

  Widget _buildSettingsView(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Administrative Tools', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            if (_isSavingSettings)
              const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
            else
              ElevatedButton.icon(
                onPressed: _saveAgencySettings,
                icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                label: const Text('Save Changes'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Column: Account & Security
            Expanded(
              flex: 1,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(radius: 32, backgroundColor: theme.colorScheme.primary.withOpacity(0.1), child: Text('A', style: TextStyle(fontSize: 24, color: theme.colorScheme.primary, fontWeight: FontWeight.bold))),
                        const SizedBox(height: 16),
                        const Text('Admin Account', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const Text('Master Privileges', style: TextStyle(color: Colors.purple, fontWeight: FontWeight.bold, fontSize: 11)),
                        const SizedBox(height: 20),
                        _buildSettingsRow(Icons.email_outlined, _supabaseService.currentUserEmail ?? 'Unknown'),
                        const Divider(height: 24),
                        _buildSettingsRow(Icons.security, 'Role-Level Security Active'),
                        const Divider(height: 24),
                        _buildSettingsRow(Icons.verified_user_outlined, 'Account Fully Verified'),
                        const Divider(height: 24),
                        _buildSettingsRow(
                          Icons.app_registration_rounded, 
                          'Storefront Management', 
                          color: const Color(0xFFF59E0B),
                          onTap: _showStorefrontManagementDialog,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 24),
            // Right Column: Agency Profile & Branding
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Logo Picker Section
                        GestureDetector(
                          onTap: _pickAndUploadLogo,
                          child: Container(
                            width: 80, height: 80,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: theme.colorScheme.primary.withOpacity(0.1)),
                              image: _logoBytes != null 
                                ? DecorationImage(image: MemoryImage(_logoBytes!), fit: BoxFit.cover)
                                : _agencyLogoCtrl.text.isNotEmpty 
                                  ? DecorationImage(image: NetworkImage(_agencyLogoCtrl.text), fit: BoxFit.cover) 
                                  : null,
                            ),
                            child: _isUploadingLogo 
                              ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                              : (_logoBytes == null && _agencyLogoCtrl.text.isEmpty) ? const Icon(Icons.add_a_photo_rounded, color: Colors.grey) : null,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Agency Branding', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              Text('Select your company logo (PNG/JPG)', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                              const SizedBox(height: 8),
                              OutlinedButton(onPressed: _pickAndUploadLogo, child: const Text('Change Logo')),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 32),
                    _buildConfigInput('Official Agency Name', _agencyNameCtrl, Icons.business_rounded),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _buildConfigInput('Support Email', _agencyEmailCtrl, Icons.alternate_email_rounded)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Global Currency', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey)),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(color: Colors.grey.withOpacity(0.05), borderRadius: BorderRadius.circular(10)),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _currencySymbol,
                                    isExpanded: true,
                                    items: [r'$', '€', '£', 'KES', 'UGX', 'ETB'].map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontWeight: FontWeight.bold)))).toList(),
                                    onChanged: (v) => setState(() => _currencySymbol = v),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildConfigInput('Headquarters Address', _agencyAddressCtrl, Icons.location_on_outlined),
                    const SizedBox(height: 12),
                    _buildConfigInput('Customer Support Phone', _supportPhoneCtrl, Icons.headset_mic_rounded),
                    const Divider(height: 32),
                    const Text('Global System Configuration', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Maintenance Mode', style: TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: const Text('Hide properties and show maintenance screen to customers.', style: TextStyle(fontSize: 11)),
                      value: _isMaintenanceMode,
                      activeColor: Colors.red,
                      onChanged: (v) => setState(() => _isMaintenanceMode = v),
                    ),
                    SwitchListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Real-Time Inquiry Popups', style: TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: const Text('Show a banner at the top of the screen when a new lead arrives.', style: TextStyle(fontSize: 11)),
                      value: _enableInquiryPopups,
                      activeColor: const Color(0xFFF59E0B),
                      onChanged: (v) => setState(() => _enableInquiryPopups = v),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showStorefrontManagementDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF0F172A),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28), side: BorderSide(color: Colors.white.withOpacity(0.05))),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: const Color(0xFFF59E0B).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.app_registration_rounded, color: Color(0xFFF59E0B)),
                ),
                const SizedBox(width: 16),
                const Text('Storefront Management', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
            content: SizedBox(
              width: 450,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Configure the information density for your elite listings in the customer mobile app.', style: TextStyle(color: Colors.grey, fontSize: 13)),
                    const SizedBox(height: 24),
                    _buildModalToggle(
                      'Show Bedrooms',
                      'Display bed count on property cards',
                      _showBedsOnCard,
                      (v) {
                        setModalState(() => _showBedsOnCard = v);
                        setState(() => _showBedsOnCard = v);
                        _updateUIFlag('show_beds_on_card', v);
                      },
                    ),
                    _buildModalToggle(
                      'Show Bathrooms',
                      'Display bath count on property cards',
                      _showBathsOnCard,
                      (v) {
                        setModalState(() => _showBathsOnCard = v);
                        setState(() => _showBathsOnCard = v);
                        _updateUIFlag('show_baths_on_card', v);
                      },
                    ),
                    _buildModalToggle(
                      'Show List Status',
                      'Display "For Sale / For Rent" next to price',
                      _showTypeOnCard,
                      (v) {
                        setModalState(() => _showTypeOnCard = v);
                        setState(() => _showTypeOnCard = v);
                        _updateUIFlag('show_type_on_card', v);
                      },
                    ),
                    _buildModalToggle(
                      'Show Property Size',
                      'Display m² on property cards',
                      _showSizeOnCard,
                      (v) {
                        setModalState(() => _showSizeOnCard = v);
                        setState(() => _showSizeOnCard = v);
                        _updateUIFlag('show_size_on_card', v);
                      },
                    ),
                    const Divider(color: Colors.white10, height: 32),
                    _buildModalToggle(
                      'Inquiry Alerts',
                      'Enable real-time popups for new leads',
                      _enableInquiryPopups,
                      (v) {
                        setModalState(() => _enableInquiryPopups = v);
                        setState(() => _enableInquiryPopups = v);
                        _updateUIFlag('enable_inquiry_popups', v);
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close', style: TextStyle(color: Colors.grey)),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildModalToggle(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 11)),
      value: value,
      activeColor: const Color(0xFFF59E0B),
      onChanged: onChanged,
    );
  }

  Widget _buildSettingsToggle(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 11)),
      value: value,
      activeColor: const Color(0xFFF59E0B),
      onChanged: onChanged,
    );
  }

  Widget _buildConfigInput(String label, TextEditingController ctrl, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 18, color: Colors.grey),
            filled: true,
            fillColor: Colors.grey.withOpacity(0.05),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            isDense: true,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsRow(IconData icon, String text, {Color? color, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color ?? Colors.grey),
            const SizedBox(width: 16),
            Expanded(child: Text(text, style: TextStyle(fontWeight: FontWeight.w500, color: color))),
            if (onTap != null) Icon(Icons.chevron_right_rounded, size: 16, color: color ?? Colors.grey),
          ],
        ),
      ),
    );
  }

  // --- ANALYTICS VIEW (STUB) ---
  
  Widget _buildAnalyticsView(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Business Intelligence', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),
        Container(
          width: double.infinity, height: 400,
          decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: theme.dividerColor.withOpacity(0.1)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.02), blurRadius: 10, offset: const Offset(0, 4))]),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.bar_chart_rounded, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('Traffic & Conversion Metrics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text('Charts will aggregate end-of-month data.', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      ],
    );
  }


  // --- COMPONENTS ---

  TextStyle _headerStyle(ThemeData theme) {
    return TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5), fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5);
  }

  Widget _buildNavItem(int index, IconData icon, String label, {bool isDestructive = false}) {
    final theme = Theme.of(context);
    final isSelected = _selectedIndex == index;
    final color = isDestructive 
        ? Colors.red 
        : isSelected 
            ? theme.colorScheme.primary 
            : theme.textTheme.bodyMedium?.color?.withOpacity(0.7);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: () {
          if (isDestructive) {
            _supabaseService.signOut();
            return;
          }
          setState(() {
            _selectedIndex = index;
            _refreshAll();
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isSelected ? theme.colorScheme.primary.withOpacity(0.1) : Colors.transparent, 
            borderRadius: BorderRadius.circular(12)
          ),
          padding: EdgeInsets.symmetric(
            horizontal: _isSidebarCollapsed ? 0 : 16, 
            vertical: 14
          ),
          child: Row(
            mainAxisAlignment: _isSidebarCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 22),
              if (!_isSidebarCollapsed) ...[
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label, 
                    style: TextStyle(
                      color: color, 
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600, 
                      fontSize: 15,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, MaterialColor baseColor) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.02), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: isDark ? baseColor.shade900.withOpacity(0.5) : baseColor.shade50, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: isDark ? baseColor.shade300 : baseColor.shade700, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5), fontSize: 13, fontWeight: FontWeight.bold)),
                  Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminSearchBar(String placeholder) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (val) {
          setState(() => _searchQuery = val.toLowerCase());
        },
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: placeholder,
          hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
          prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFFF59E0B), size: 20),
          suffixIcon: _searchQuery.isNotEmpty 
            ? IconButton(
                icon: const Icon(Icons.close_rounded, size: 18, color: Colors.grey),
                onPressed: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
              )
            : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey),
          const SizedBox(width: 6),
          Text(
            '$value $label',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // --- OWNERS MANAGEMENT ---

  Widget _buildOwnersView(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Owner Network', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
                  Text('Managing ${DateTime.now().year} Landlord Portfolio', style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5))),
                ],
              ),
            ),
            const SizedBox(width: 32),
            Expanded(child: _buildAdminSearchBar('Search landlords by name, email, or phone...')),
            const SizedBox(width: 32),
            ElevatedButton.icon(
              onPressed: () => _showAddOwnerDialog(theme),
              icon: const Icon(Icons.person_add_rounded, size: 20),
              label: const Text('Register Landlord'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        FutureBuilder<List<dynamic>>(
          future: Future.wait([_ownersFuture, _propertiesFuture]),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            final allOwners = snapshot.data?[0] as List<Owner>? ?? [];
            final properties = snapshot.data?[1] as List<Property>? ?? [];
            
            final filteredOwners = allOwners.where((o) {
              final query = _searchQuery.toLowerCase();
              return o.name.toLowerCase().contains(query) || 
                     (o.email?.toLowerCase().contains(query) ?? false) || 
                     (o.phone?.toLowerCase().contains(query) ?? false);
            }).toList();

            if (allOwners.isEmpty) {
              return Center(
                child: Column(
                  children: [
                    const SizedBox(height: 100),
                    Icon(Icons.person_off_rounded, size: 80, color: Colors.grey.withOpacity(0.2)),
                    const SizedBox(height: 24),
                    const Text('No property owners registered.', style: TextStyle(color: Colors.grey, fontSize: 18, fontWeight: FontWeight.w500)),
                  ],
                ),
              );
            }

            if (filteredOwners.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(60),
                child: Center(child: Text('No matching landlords found.', style: TextStyle(color: Colors.grey, fontSize: 16))),
              );
            }

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, 
                childAspectRatio: 1.4,
                crossAxisSpacing: 24,
                mainAxisSpacing: 24,
              ),
              itemCount: filteredOwners.length,
              itemBuilder: (context, index) {
                final owner = filteredOwners[index];
                final ownerPropertyCount = properties.where((p) => p.ownerId == owner.id).length;
                
                return Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10))
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    children: [
                      Positioned(
                        right: -20, top: -20,
                        child: Icon(Icons.business_rounded, size: 100, color: theme.colorScheme.primary.withOpacity(0.03)),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(owner.name[0].toUpperCase(), style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 20)),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(owner.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18), maxLines: 1, overflow: TextOverflow.ellipsis),
                                      Text(owner.email ?? 'No official email', style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5))),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (c) => AlertDialog(
                                        title: const Text('Delete Owner?'),
                                        content: Text('Are you sure you want to remove ${owner.name}? This will unlinked their properties.'),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                                          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      await _supabaseService.deleteOwner(owner.id);
                                      _refreshAll();
                                    }
                                  },
                                ),
                              ],
                            ),
                            const Spacer(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('PORTFOLIO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1, color: Colors.grey)),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                      child: Text('$ownerPropertyCount Properties', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 12)),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text('CONTACT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1, color: Colors.grey)),
                                    const SizedBox(height: 4),
                                    Text(owner.phone ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  void _showAddOwnerDialog(ThemeData theme) {
    bool isSaving = false;
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final bankCtrl = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Register New Landlord', style: TextStyle(fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Full Legal Name', prefixIcon: Icon(Icons.person_outline_rounded))),
                  const SizedBox(height: 16),
                  TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Mobile Phone', prefixIcon: Icon(Icons.phone_iphone_rounded))),
                  const SizedBox(height: 16),
                  TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Contact Email', prefixIcon: Icon(Icons.alternate_email_rounded))),
                  const SizedBox(height: 16),
                  TextField(controller: bankCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Payment Info (Bank/M-Pesa)', prefixIcon: Icon(Icons.account_balance_rounded))),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: isSaving ? null : () => Navigator.pop(context), child: const Text('Discard')),
              ElevatedButton(
                onPressed: isSaving ? null : () async {
                  if (nameCtrl.text.isEmpty) return;
                  setDialogState(() => isSaving = true);
                  
                  try {
                    final newOwner = Owner(
                      id: '',
                      name: nameCtrl.text,
                      phone: phoneCtrl.text,
                      email: emailCtrl.text,
                      bankDetails: bankCtrl.text,
                      createdAt: DateTime.now(),
                    );
                    await _supabaseService.addOwner(newOwner);
                    _refreshAll();
                    if (mounted) Navigator.pop(context);
                  } finally {
                    setDialogState(() => isSaving = false);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: isSaving 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Save Landlord Account'),
              ),
            ],
          );
        }
      ),
    );
  }

  // --- FINANCIALS VIEW ---

  Widget _buildFinancialsView(ThemeData theme, double revenue, double salaries, double expenses, List<Payout> payouts) {
    final netProfit = revenue - salaries - expenses;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Financial Analysis', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: netProfit >= 0 ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Net Profit: \$${netProfit.toStringAsFixed(2)}', 
                style: TextStyle(color: netProfit >= 0 ? Colors.green : Colors.red, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        Row(
          children: [
            _buildFinanceCard('Total Commissions', '\$${revenue.toStringAsFixed(2)}', Icons.payments_rounded, Colors.green),
            const SizedBox(width: 16),
            _buildFinanceCard('Operating Costs', '\$${(salaries + expenses).toStringAsFixed(2)}', Icons.receipt_long_rounded, Colors.red),
            const SizedBox(width: 16),
            _buildFinanceCard('Owner Payouts', '...', Icons.account_balance_wallet_rounded, Colors.orange),
          ],
        ),
        const SizedBox(height: 48),
        const Text('Recent Transactions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: payouts.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final p = payouts[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: p.isPaidToOwner ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                  child: Icon(p.isPaidToOwner ? Icons.check_circle_rounded : Icons.pending_rounded, size: 20, color: p.isPaidToOwner ? Colors.green : Colors.orange),
                ),
                title: const Text('Rental Commission', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(DateFormat.yMMMd().format(p.createdAt)),
                trailing: Text('+\$${p.agencyCut.toStringAsFixed(2)}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildOfficeHQView(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Premium Header Section with Actions
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [theme.colorScheme.primary.withOpacity(0.05), Colors.transparent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: theme.colorScheme.primary.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Office Command Center', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
                    const SizedBox(height: 8),
                    Text('Manage your agency staff and operational overhead.', style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6), fontSize: 16)),
                  ],
                ),
              ),
              Row(
                children: [
                   ElevatedButton.icon(
                    onPressed: () => _showAddExpenseDialog(theme),
                    icon: const Icon(Icons.add_shopping_cart_rounded, size: 20),
                    label: const Text('Record Expense'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.withOpacity(0.1),
                      foregroundColor: Colors.orange,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () => _showAddEmployeeDialog(theme),
                    icon: const Icon(Icons.person_add_rounded, size: 20),
                    label: const Text('Hire Staff'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                      elevation: 8,
                      shadowColor: theme.colorScheme.primary.withOpacity(0.4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 48),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: _buildStaffSection(theme),
            ),
            const SizedBox(width: 40),
            Expanded(
              flex: 1,
              child: _buildExpenseSection(theme),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStaffSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.badge_rounded, color: Colors.blue),
            const SizedBox(width: 12),
            const Text('Active Team Members', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 24),
        FutureBuilder<List<Employee>>(
          future: _employeesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            final employees = snapshot.data ?? [];
            if (employees.isEmpty) return const Center(child: Padding(padding: EdgeInsets.all(40), child: Text('No staff registered yet.', style: TextStyle(color: Colors.grey))));
            
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.05, // Reduced to 1.05 to give even more vertical space for payroll buttons
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
              ),
              itemCount: employees.length,
              itemBuilder: (context, index) {
                final e = employees[index];
                final isPaydayOverdue = DateTime.now().difference(e.lastPayDate).inDays >= 30;

                return Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: isPaydayOverdue ? Colors.orange.withOpacity(0.5) : theme.dividerColor.withOpacity(0.1), width: isPaydayOverdue ? 2 : 1),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10))],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [theme.colorScheme.primary, theme.colorScheme.primary.withOpacity(0.7)]),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(
                              child: Text(e.name[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24)),
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(e.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18), maxLines: 1, overflow: TextOverflow.ellipsis),
                                Text(e.role.toUpperCase(), style: TextStyle(color: theme.colorScheme.primary, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, color: Colors.grey, size: 20),
                            onPressed: () => _showEmployeeFormDialog(theme, employee: e),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                            onPressed: () => _confirmDeleteStaff(e),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Agent Performance Scorecard
                      FutureBuilder<Map<String, int>>(
                        future: fetchAgentPerformance(e.id),
                        builder: (context, statsSnap) {
                          final stats = statsSnap.data ?? {'properties': 0, 'rentals': 0};
                          return Row(
                            children: [
                              _buildMiniStat('Assets', stats['properties'].toString(), Icons.home_work_outlined),
                              const SizedBox(width: 12),
                              _buildMiniStat('Deals', stats['rentals'].toString(), Icons.verified_user_outlined),
                            ],
                          );
                        },
                      ),
                      const Spacer(),
                      const Divider(height: 24, thickness: 1),
                      if (isPaydayOverdue)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                await _supabaseService.processPayroll(e);
                                _refreshAll();
                                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Salary of \$${e.salary} processed for ${e.name}')));
                              },
                              icon: const Icon(Icons.payments_rounded, size: 16),
                              label: const Text('PAY MONTHLY SALARY'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('MONTHLY SALARY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                              const SizedBox(height: 4),
                              Text('\$${e.salary.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green)),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('LAST PAID ON', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                              const SizedBox(height: 4),
                              Text(DateFormat.yMMMd().format(e.lastPayDate), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Future<Map<String, int>> fetchAgentPerformance(String agentId) async {
    return await _supabaseService.fetchAgentPerformance(agentId);
  }

  void _confirmDeleteStaff(Employee employee) async {
     final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Remove Staff Member?'),
        content: Text('Are you sure you want to dismiss ${employee.name}? This will remove them from your payroll records.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(c, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('Confirm Deletion'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _supabaseService.deleteEmployee(employee.id);
      _refreshAll();
    }
  }

  Widget _buildExpenseSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.receipt_long_rounded, color: Colors.orange),
            const SizedBox(width: 12),
            const Text('Operating Overhead', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 24),
        FutureBuilder<List<OfficeExpense>>(
          future: _expensesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            final expenses = snapshot.data ?? [];
            if (expenses.isEmpty) return const Center(child: Text('No expenditures recorded.'));
            
            return Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10))],
              ),
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 12),
                physics: const NeverScrollableScrollPhysics(),
                itemCount: expenses.length,
                separatorBuilder: (_, __) => Divider(height: 1, color: theme.dividerColor.withOpacity(0.05)),
                itemBuilder: (context, index) {
                  final ex = expenses[index];
                  final color = _getExpenseColor(ex.category);
                  return ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                      child: Icon(_getExpenseIcon(ex.category), color: color, size: 20),
                    ),
                    title: Text(ex.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: Text(ex.category, style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5))),
                    trailing: Text('-\$${ex.amount.toStringAsFixed(0)}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 15)),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Color _getExpenseColor(String category) {
    final cat = category.toLowerCase();
    if (cat.contains('rent')) return Colors.blue;
    if (cat.contains('util')) return Colors.orange;
    if (cat.contains('mark')) return Colors.purple;
    if (cat.contains('tax')) return Colors.red;
    return Colors.teal;
  }

  IconData _getExpenseIcon(String category) {
    final cat = category.toLowerCase();
    if (cat.contains('rent')) return Icons.business_rounded;
    if (cat.contains('util')) return Icons.bolt_rounded;
    if (cat.contains('mark')) return Icons.ad_units_rounded;
    return Icons.payments_rounded;
  }

  void _showAddEmployeeDialog(ThemeData theme) {
    _showEmployeeFormDialog(theme);
  }

  void _showEmployeeFormDialog(ThemeData theme, {Employee? employee}) {
    final nameCtrl = TextEditingController(text: employee?.name);
    final salaryCtrl = TextEditingController(text: employee?.salary.toString());
    String selectedRole = employee?.role ?? 'Real Estate Agent';
    
    final List<String> agencyRoles = [
      'Real Estate Agent',
      'Accountant',
      'Manager',
      'Maintenance',
      'Cleaning Staff',
      'Security',
      'Marketing',
      'Administrator'
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(employee == null ? 'Hire New Staff' : 'Edit Staff Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                labelText: 'Full Name',
                prefixIcon: const Icon(Icons.person_outline_rounded),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: agencyRoles.contains(selectedRole) ? selectedRole : agencyRoles.first,
              decoration: InputDecoration(
                labelText: 'Professional Role',
                prefixIcon: const Icon(Icons.badge_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: agencyRoles.map((role) => DropdownMenuItem(value: role, child: Text(role))).toList(),
              onChanged: (val) => selectedRole = val ?? selectedRole,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: salaryCtrl,
              decoration: InputDecoration(
                labelText: 'Monthly Salary',
                prefixText: '\$',
                prefixIcon: const Icon(Icons.payments_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.isEmpty) return;
              
              final staffData = Employee(
                id: employee?.id ?? '',
                name: nameCtrl.text,
                role: selectedRole,
                salary: double.tryParse(salaryCtrl.text) ?? 2000,
                joinedAt: employee?.joinedAt ?? DateTime.now(),
                lastPayDate: employee?.lastPayDate ?? DateTime.now(),
              );
              
              if (employee == null) {
                await _supabaseService.addEmployee(staffData);
              } else {
                await _supabaseService.updateEmployee(staffData);
              }
              
              _refreshAll();
              if (context.mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(employee == null ? 'Complete Hiring' : 'Save Changes'),
          ),
        ],
      ),
    );
  }

  void _showAddExpenseDialog(ThemeData theme) {
    final titleCtrl = TextEditingController();
    final categoryCtrl = TextEditingController();
    final amountCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Record Office Expense'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Expense Title')),
            TextField(controller: categoryCtrl, decoration: const InputDecoration(labelText: 'Category (Rent/Utility)')),
            TextField(controller: amountCtrl, decoration: const InputDecoration(labelText: 'Amount Paid', prefixText: '\$'), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final newExpense = OfficeExpense(
                id: '',
                title: titleCtrl.text,
                category: categoryCtrl.text,
                amount: double.tryParse(amountCtrl.text) ?? 0,
                date: DateTime.now(),
              );
              await _supabaseService.addOfficeExpense(newExpense);
              _refreshAll();
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Record'),
          ),
        ],
      ),
    );
  }


  Widget _buildFinanceCard(String title, String value, IconData icon, MaterialColor color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: color.shade800, fontSize: 13, fontWeight: FontWeight.bold)),
                Text(value, style: TextStyle(color: color.shade900, fontSize: 24, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBroadcastingView(ThemeData theme) {
    final titleCtrl = TextEditingController();
    final messageCtrl = TextEditingController();
    String selectedType = 'Update';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Compact Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Global Announcement Center',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: -1.0, color: Colors.white)),
                const SizedBox(height: 1),
                Text('Broadcast updates to all device trays and in-app trays',
                    style: TextStyle(color: Colors.grey[400], fontSize: 11)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Column: Composer (Fixed Height)
              Expanded(
                flex: 3,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Compose Announcement', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        const Text('Announcement Title', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: titleCtrl,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFF0F172A),
                            hintText: 'e.g. Office Relocation Notice',
                            hintStyle: TextStyle(color: Colors.grey[600]),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text('Message Body', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: messageCtrl,
                          maxLines: 4,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFF0F172A),
                            hintText: 'Enter your announcement details here...',
                            hintStyle: TextStyle(color: Colors.grey[600]),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text('Announcement Category', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        StatefulBuilder(
                          builder: (context, setState) {
                            return Wrap(
                              spacing: 8,
                              children: ['Update', 'Promotion', 'Listing', 'System'].map((type) {
                                final isSelected = selectedType == type;
                                return ChoiceChip(
                                  label: Text(type, style: const TextStyle(fontSize: 12)),
                                  selected: isSelected,
                                  onSelected: (val) {
                                    if (val) setState(() => selectedType = type);
                                  },
                                  selectedColor: const Color(0xFFF59E0B),
                                  backgroundColor: const Color(0xFF0F172A),
                                  labelStyle: TextStyle(color: isSelected ? const Color(0xFF0F172A) : Colors.white, fontWeight: FontWeight.bold),
                                );
                              }).toList(),
                            );
                          }
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 48, // Slightly more compact height
                          child: ElevatedButton.icon(
                            onPressed: () {
                              if (titleCtrl.text.isEmpty || messageCtrl.text.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter title and message body')));
                                return;
                              }
                              _broadcastAnnouncement(titleCtrl.text, messageCtrl.text, selectedType);
                              titleCtrl.clear();
                              messageCtrl.clear();
                            },
                            icon: const Icon(Icons.send_rounded, size: 18),
                            label: const Text('Broadcast Announcement', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF59E0B),
                              foregroundColor: const Color(0xFF0F172A),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12), // Extra breathing room at bottom
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              // Right Column: Broadcast History (Scrollable)
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Broadcast History', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Expanded(
                      child: FutureBuilder<List<AppNotification>>(
                        future: _supabaseService.fetchNotifications(),
                        builder: (context, snapshot) {
                          final history = (snapshot.data ?? []).where((n) => n.userId == null).toList();
                          if (history.isEmpty) {
                            return Container(
                              padding: const EdgeInsets.all(40),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E293B).withOpacity(0.5),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: Colors.white.withOpacity(0.05)),
                              ),
                              child: const Center(child: Text('No previous broadcasts', style: TextStyle(color: Colors.grey))),
                            );
                          }
                          return ListView.separated(
                            itemCount: history.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final item = history[index];
                              return Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E293B),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(item.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                        Text(item.type, style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 9, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(DateFormat('MMM dd, yyyy HH:mm').format(item.createdAt), style: const TextStyle(color: Colors.grey, fontSize: 10)),
                                    const SizedBox(height: 6),
                                    Text(item.message, style: TextStyle(color: Colors.grey[400], fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReportsView(ThemeData theme) {
    return FutureBuilder<List<dynamic>>(
      future: Future.wait([_propertiesFuture, _payoutsFuture, _profilesFuture, _ownersFuture]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        
        final props = snapshot.data?[0] as List<Property>? ?? [];
        final payouts = snapshot.data?[1] as List<Payout>? ?? [];
        final users = snapshot.data?[2] as List<Profile>? ?? [];
        final owners = snapshot.data?[3] as List<Owner>? ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Business Intelligence Reports', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: -1)),
            Text('Comprehensive analysis of your real estate ecosystem', style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5))),
            const SizedBox(height: 32),
            
            // 1. Performance Summary Grid
            Row(
              children: [
                Expanded(child: _buildReportMetric('Conversion Rate', '${((payouts.length / (props.length > 0 ? props.length : 1)) * 100).toStringAsFixed(1)}%', 'Lead-to-Deal efficiency', Icons.trending_up_rounded, Colors.green)),
                const SizedBox(width: 20),
                Expanded(child: _buildReportMetric('Inventory Value', '\$${(props.fold(0.0, (sum, p) => sum + p.price) / 1000).toStringAsFixed(1)}K', 'Total asset valuation', Icons.monetization_on_rounded, Colors.blue)),
                const SizedBox(width: 20),
                Expanded(child: _buildReportMetric('Client Density', '${(users.length / (owners.length > 0 ? owners.length : 1)).toStringAsFixed(1)}x', 'Buyers per Owner ratio', Icons.groups_rounded, Colors.purple)),
              ],
            ),
            const SizedBox(height: 40),

            // 2. Category Analysis
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Inventory by Category', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 24),
                        ..._buildCategoryBreakdown(props, theme),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Deal Velocity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 24),
                        _buildVelocityItem('Avg. Time to Close', '14 Days', 0.7, theme),
                        const SizedBox(height: 20),
                        _buildVelocityItem('Owner Satisfaction', '4.8/5.0', 0.96, theme),
                        const SizedBox(height: 20),
                        _buildVelocityItem('Lead Response', '< 2 Hrs', 0.85, theme),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildReportMetric(String label, String value, String desc, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 16),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(desc, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
        ],
      ),
    );
  }

  List<Widget> _buildCategoryBreakdown(List<Property> props, ThemeData theme) {
    final Map<String, int> counts = {};
    for (var p in props) {
      final cat = p.categoryName ?? 'Other';
      counts[cat] = (counts[cat] ?? 0) + 1;
    }

    return counts.entries.map((e) {
      final percent = e.value / (props.length > 0 ? props.length : 1);
      return Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(e.key, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text('${e.value} units (${(percent * 100).toStringAsFixed(0)}%)', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percent,
                minHeight: 8,
                backgroundColor: theme.dividerColor.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildVelocityItem(String label, String value, double progress, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: theme.dividerColor.withOpacity(0.1),
          valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary.withOpacity(0.5)),
          minHeight: 4,
        ),
      ],
    );
  }
}
