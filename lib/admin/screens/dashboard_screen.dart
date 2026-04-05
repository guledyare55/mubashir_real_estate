import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/services/supabase_service.dart';
import '../../core/models/property.dart';
import '../../core/models/profile.dart';
import '../../core/models/inquiry.dart';
import 'property_form_dialog.dart';
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
  final SupabaseService _supabaseService = SupabaseService();
  
  late Future<List<Property>> _propertiesFuture;
  late Future<List<Profile>> _profilesFuture;
  late Future<List<Inquiry>> _inquiriesFuture;

  @override
  void initState() {
    super.initState();
    _refreshAll();
  }

  void _refreshAll() {
    setState(() {
      _propertiesFuture = _supabaseService.fetchProperties();
      _profilesFuture = _supabaseService.fetchProfiles();
      _inquiriesFuture = _supabaseService.fetchInquiries();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 260,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(right: BorderSide(color: theme.dividerColor.withOpacity(0.1), width: 1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.real_estate_agent, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Text('Admin Portal', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                _buildNavItem(0, Icons.dashboard_rounded, 'Overview'),
                _buildNavItem(1, Icons.maps_home_work_rounded, 'Properties'),
                _buildNavItem(2, Icons.forum_rounded, 'Inquiries'),
                _buildNavItem(3, Icons.people_alt_rounded, 'Customers'),
                _buildNavItem(4, Icons.analytics_rounded, 'Analytics'),
                const Spacer(),
                const Divider(height: 1),
                _buildNavItem(5, Icons.settings_rounded, 'Settings'),
                _buildNavItem(6, Icons.logout_rounded, 'Sign Out', isDestructive: true),
                const SizedBox(height: 24),
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
                  child: SingleChildScrollView(
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

  Widget _buildCurrentView(ThemeData theme) {
    switch (_selectedIndex) {
      case 0: // Overview Dashboard
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildStatCard('Total Properties', '124', Icons.home_work_rounded, Colors.blue),
                const SizedBox(width: 24),
                _buildStatCard('Active Users', '89', Icons.people_rounded, Colors.green),
                const SizedBox(width: 24),
                _buildStatCard('New Inquiries', '12', Icons.message_rounded, Colors.orange),
              ],
            ),
            const SizedBox(height: 48),
            _buildPropertiesTable(theme),
          ],
        );
      case 1: // Properties
        return _buildPropertiesTable(theme);
      case 2: // Inquiries
        return _buildInquiriesTable(theme);
      case 3: // Customers
        return _buildCustomersTable(theme);
      case 4: // Analytics
        return _buildAnalyticsView(theme);
      case 5: // Settings
        return _buildSettingsView(theme);
      default:
        return const Center(child: Text('Under Construction...', style: TextStyle(fontSize: 18, color: Colors.grey)));
    }
  }

  Widget _buildHeader(ThemeData theme) {
    String title = 'Dashboard Overview';
    if (_selectedIndex == 1) title = 'Property Management';
    if (_selectedIndex == 2) title = 'Customer Inquiries';
    if (_selectedIndex == 3) title = 'User Accounts';
    if (_selectedIndex == 4) title = 'Platform Analytics';
    if (_selectedIndex == 5) title = 'Platform Settings';

    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 40),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(bottom: BorderSide(color: theme.dividerColor.withOpacity(0.05), width: 1)),
      ),
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
                  children: [
                    const Icon(Icons.notifications_none_rounded),
                    Positioned(
                      right: 2, top: 4,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(6)),
                        constraints: const BoxConstraints(minWidth: 8, minHeight: 8),
                      ),
                    ),
                  ],
                ),
                itemBuilder: (context) => [
                  const PopupMenuItem(child: Text('🎉 New User Registered', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                  const PopupMenuItem(child: Text('💬 New Inquiry on "Modern Villa"', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                  const PopupMenuItem(child: Text('✅ System Health Normal', style: TextStyle(color: Colors.grey, fontSize: 13))),
                ],
              ),
              const SizedBox(width: 8),
              IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _refreshAll),
              const SizedBox(width: 16),
              CircleAvatar(
                backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                child: Text('A', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
              )
            ],
          )
        ],
      ),
    );
  }

  // --- INQUIRIES PANEL ---
  
  Widget _buildInquiriesTable(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text('Lead Inquiries', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
                    Expanded(flex: 2, child: Text('Customer Info', style: _headerStyle(theme))),
                    Expanded(flex: 3, child: Text('Message', style: _headerStyle(theme))),
                    Expanded(flex: 2, child: Text('Property Link', style: _headerStyle(theme))),
                    Expanded(flex: 1, child: Text('Status', style: _headerStyle(theme))),
                    Expanded(flex: 1, child: Text('Date', style: _headerStyle(theme), textAlign: TextAlign.right)),
                  ],
                ),
              ),
              const Divider(height: 1),
              FutureBuilder<List<Inquiry>>(
                future: _inquiriesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) return const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()));
                  if (snapshot.hasError) return Padding(padding: const EdgeInsets.all(40), child: Center(child: Text('Error: ${snapshot.error}')));
                  if (!snapshot.hasData || snapshot.data!.isEmpty) return const Padding(padding: EdgeInsets.all(40), child: Center(child: Text('No inquiries found.', style: TextStyle(color: Colors.grey))));

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: snapshot.data!.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final inquiry = snapshot.data![index];
                      final isNew = inquiry.status == 'New';
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Customer Info
                            Expanded(
                              flex: 2, 
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(inquiry.customerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  const SizedBox(height: 4),
                                  Text(inquiry.customerEmail, style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6), fontSize: 12)),
                                  if (inquiry.customerPhone != null && inquiry.customerPhone!.isNotEmpty)
                                    Text(inquiry.customerPhone!, style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6), fontSize: 12)),
                                ],
                              )
                            ),
                            // Message Preview
                            Expanded(
                              flex: 3, 
                              child: Padding(
                                padding: const EdgeInsets.only(right: 16),
                                child: Text(inquiry.message, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(height: 1.4, fontSize: 13)),
                              )
                            ),
                            // Property ID Link
                            Expanded(
                              flex: 2, 
                              child: SelectableText(inquiry.propertyId.substring(0, 8), style: const TextStyle(color: Colors.blue, fontFamily: 'monospace', fontWeight: FontWeight.bold))
                            ),
                            // Status Badge
                            Expanded(
                              flex: 1,
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: PopupMenuButton<String>(
                                  icon: Icon(Icons.more_vert_rounded, size: 20, color: theme.iconTheme.color?.withOpacity(0.5)),
                                  onSelected: (value) async {
                                    if (value == 'Contacted' || value == 'Archived') {
                                      await _supabaseService.updateInquiryStatus(inquiry.id, value);
                                      _refreshAll();
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Inquiry marked as $value')));
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(value: 'Contacted', child: Text('Mark as Contacted')),
                                    const PopupMenuItem(value: 'Archived', child: Text('Archive Lead')),
                                  ],
                                ),
                              ),
                            ),
                            // Date Column
                            Expanded(flex: 1, child: Text(DateFormat('MMM dd').format(inquiry.createdAt), textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
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

  // --- CUSTOMERS PANEL ---

  Widget _buildCustomersTable(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Registered Users', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
                  if (!snapshot.hasData || snapshot.data!.isEmpty) return const Padding(padding: EdgeInsets.all(40), child: Center(child: Text('No users found.', style: TextStyle(color: Colors.grey))));

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: snapshot.data!.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final profile = snapshot.data![index];
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
                                      showDialog(
                                        context: context,
                                        builder: (_) => CustomerDossierDialog(customer: profile),
                                      );
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

  Widget _buildPropertiesTable(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Property Directory', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ElevatedButton.icon(
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text('Add Property'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary, foregroundColor: theme.colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 0,
              ),
              onPressed: () { showDialog(context: context, builder: (_) => const PropertyFormDialog()); },
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
                    Expanded(flex: 1, child: Text('ID', style: _headerStyle(theme))),
                    Expanded(flex: 4, child: Text('Title', style: _headerStyle(theme))),
                    Expanded(flex: 2, child: Text('Type', style: _headerStyle(theme))),
                    Expanded(flex: 2, child: Text('Price', style: _headerStyle(theme))),
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
                  if (!snapshot.hasData || snapshot.data!.isEmpty) return const Padding(padding: EdgeInsets.all(40), child: Center(child: Text('No properties found.', style: TextStyle(color: Colors.grey))));

                  return ListView.separated(
                    shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: snapshot.data!.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final property = snapshot.data![index];
                      final isAvailable = property.status == 'Available';
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                        child: Row(
                          children: [
                            Expanded(flex: 1, child: Text(property.id.substring(0, 8), style: const TextStyle(fontWeight: FontWeight.w500))),
                            Expanded(flex: 4, child: Text(property.title, style: const TextStyle(fontWeight: FontWeight.bold))),
                            Expanded(flex: 2, child: Text(property.type)),
                            Expanded(flex: 2, child: Text('\$${property.price.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w600))),
                            Expanded(
                              flex: 2,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(color: isAvailable ? Colors.green.withOpacity(0.15) : Colors.orange.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
                                  child: Text(property.status, style: TextStyle(color: isAvailable ? Colors.green : Colors.orange, fontSize: 12, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Align(
                                alignment: Alignment.centerRight, 
                                child: PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert_rounded, size: 20),
                                  onSelected: (value) async {
                                    if (value == 'delete') {
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
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Property deleted.')));
                                      }
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(value: 'edit', child: Text('Edit Property')),
                                    const PopupMenuItem(value: 'delete', child: Text('Delete Property', style: TextStyle(color: Colors.red))),
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

  // --- SETTINGS PANEL ---

  Widget _buildSettingsView(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Administrative Tools', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Admin Profile Details
            Expanded(
              flex: 1,
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.02), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Column(
                  children: [
                    CircleAvatar(radius: 48, backgroundColor: theme.colorScheme.primary.withOpacity(0.1), child: Text('A', style: TextStyle(fontSize: 32, color: theme.colorScheme.primary, fontWeight: FontWeight.bold))),
                    const SizedBox(height: 24),
                    const Text('Admin Account', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const Text('Master Privileges', style: TextStyle(color: Colors.purple, fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 32),
                    _buildSettingsRow(Icons.email_outlined, _supabaseService.currentUserEmail ?? 'Unknown'),
                    const Divider(height: 32),
                    _buildSettingsRow(Icons.security, 'Role-Level Security Active'),
                    const Divider(height: 32),
                    _buildSettingsRow(Icons.verified_user_outlined, 'Account Fully Verified'),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 32),
            // Global Toggles
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.02), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('System Configuration', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 32),
                    SwitchListTile(
                      title: const Text('Maintenance Mode', style: TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: const Text('Disable public access to the customer app.', style: TextStyle(fontSize: 12)),
                      value: false,
                      onChanged: (val) {},
                      activeColor: Colors.red,
                    ),
                    const Divider(height: 32),
                    SwitchListTile(
                      title: const Text('Email Notifications', style: TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: const Text('Receive an email whenever a new lead inquiry is submitted.'),
                      value: true,
                      onChanged: (val) {},
                    ),
                    const Divider(height: 32),
                    SwitchListTile(
                      title: const Text('Auto-Archive Resolved Leads', style: TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: const Text('Automatically hide leads marked as Contacted after 30 days.'),
                      value: true,
                      onChanged: (val) {},
                    ),
                  ],
                ),
              ),
            ),
          ],
        )
      ],
    );
  }

  Widget _buildSettingsRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(width: 16),
        Text(text, style: const TextStyle(fontWeight: FontWeight.w500)),
      ],
    );
  }

  // --- ANALYTICS AND AGENTS (STUBS) ---
  
  Widget _buildAnalyticsView(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Analytics & Reporting', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),
        Container(
          width: double.infinity, height: 400,
          decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: theme.dividerColor.withOpacity(0.1)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.02), blurRadius: 10, offset: const Offset(0, 4))]),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.bar_chart_rounded, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('Traffic & Conversion Metrics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('Charts will aggregate end-of-month data.', style: TextStyle(color: Colors.grey)),
              ],
            )
          ),
        )
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
    final color = isDestructive ? Colors.red : isSelected ? theme.colorScheme.primary : theme.textTheme.bodyMedium?.color?.withOpacity(0.7);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: () {
          if (isDestructive) {
            _supabaseService.signOut();
            return;
          }
          setState(() => _selectedIndex = index);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(color: isSelected ? theme.colorScheme.primary.withOpacity(0.1) : Colors.transparent, borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 16),
              Text(label, style: TextStyle(color: color, fontWeight: isSelected ? FontWeight.bold : FontWeight.w600, fontSize: 15)),
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
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.02), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6), fontSize: 16, fontWeight: FontWeight.w600)),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: isDark ? baseColor.shade900.withOpacity(0.5) : baseColor.shade50, borderRadius: BorderRadius.circular(8)),
                  child: Icon(icon, color: isDark ? baseColor.shade300 : baseColor.shade700, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(value, style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, letterSpacing: -1)),
          ],
        ),
      ),
    );
  }
}
