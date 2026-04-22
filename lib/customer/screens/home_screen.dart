import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/models/property.dart';
import '../../core/models/agency_settings.dart';
import '../../core/services/supabase_service.dart';
import 'property_details.dart';
import 'notifications_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onSearchTap;
  const HomeScreen({super.key, required this.onSearchTap});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  late Future<List<Property>> _propertiesFuture;
  late Future<AgencySettings> _settingsFuture;
  bool _isGridMode = true;

  @override
  void initState() {
    super.initState();
    _propertiesFuture = _supabaseService.fetchProperties();
    _settingsFuture = _supabaseService.fetchAgencySettings();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 1. Sleek Minimalist Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 30, 28, 0), 
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('MUBASHIR', style: TextStyle(color: theme.colorScheme.secondary, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 3)),
                          const Text('REAL ESTATE', style: TextStyle(color: Color(0xFFF59E0B), fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 5)),
                        ],
                      ),
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const NotificationsScreen()),
                          );
                        },
                        borderRadius: BorderRadius.circular(30),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isDark ? theme.cardColor : Colors.white, 
                            shape: BoxShape.circle, 
                            border: Border.all(color: theme.colorScheme.secondary.withOpacity(0.1)),
                          ),
                          child: Icon(Icons.notifications_outlined, color: theme.colorScheme.secondary, size: 22),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10), 
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: 'Discover ', style: TextStyle(color: theme.colorScheme.secondary.withOpacity(0.5), fontSize: 13, letterSpacing: 0.5)),
                        TextSpan(text: 'Elite Sanctuary', style: TextStyle(color: theme.colorScheme.secondary, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: -0.5)), 
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. Navigation Bridge (Search Trigger)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: InkWell(
                onTap: widget.onSearchTap,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  height: 60,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: isDark ? theme.cardColor : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(isDark ? 0.3 : 0.05), blurRadius: 30, offset: const Offset(0, 10)),
                    ],
                    border: Border.all(color: theme.colorScheme.secondary.withOpacity(0.05)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search_rounded, color: Color(0xFFF59E0B), size: 24),
                      const SizedBox(width: 12),
                      Text(
                        'Location, neighborhood, or city',
                        style: TextStyle(color: theme.colorScheme.secondary.withOpacity(0.3), fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 8)),

          // 3. Section Header with Layout Toggle
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 0, 24, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Featured Listings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.secondary)),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.grid_view_rounded, color: _isGridMode ? const Color(0xFFF59E0B) : theme.colorScheme.secondary.withOpacity(0.3)),
                        onPressed: () => setState(() => _isGridMode = true),
                      ),
                      IconButton(
                        icon: Icon(Icons.view_agenda_rounded, color: !_isGridMode ? const Color(0xFFF59E0B) : theme.colorScheme.secondary.withOpacity(0.3)),
                        onPressed: () => setState(() => _isGridMode = false),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // 4. Dynamic Property View (Grid/List)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: FutureBuilder<AgencySettings>(
              future: _settingsFuture,
              builder: (context, settingsSnap) {
                final settings = settingsSnap.data;
                
                return StreamBuilder<List<Property>>(
                  stream: _supabaseService.propertiesStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                      return const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()));
                    }
                    final properties = snapshot.data ?? [];
                    
                    if (properties.isEmpty) {
                      return SliverToBoxAdapter(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(40),
                            child: Text('No properties available right now.', style: TextStyle(color: theme.colorScheme.secondary.withOpacity(0.5))),
                          ),
                        ),
                      );
                    }

                    final screenHeight = MediaQuery.of(context).size.height;
                    final safePadding = MediaQuery.of(context).padding.top + MediaQuery.of(context).padding.bottom;
                    final fixedHeaderHeight = 250.0; 
                    final availableHeight = screenHeight - safePadding - fixedHeaderHeight;
                    final targetItemHeight = availableHeight / 3;
                    
                    if (_isGridMode) {
                      final cardWidth = (MediaQuery.of(context).size.width - 48 - 16) / 2;
                      final dynamicAspectRatio = cardWidth / targetItemHeight;

                      return SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: dynamicAspectRatio.clamp(0.6, 1.2),
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _buildGridCard(properties[index], settings, theme, isDark),
                          childCount: properties.length,
                        ),
                      );
                    } else {
                      return SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: SizedBox(
                              height: targetItemHeight,
                              child: _buildListCard(properties[index], settings, theme, isDark),
                            ),
                          ),
                          childCount: properties.length,
                        ),
                      );
                    }
                  },
                );
              },
            ),
          ),

        ],
      ),
    );
  }

  Widget _buildGridCard(Property prop, AgencySettings? settings, ThemeData theme, bool isDark) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => PropertyDetails(property: prop)),
        );
      },
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? theme.cardColor : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: theme.colorScheme.secondary.withOpacity(0.05)),
          boxShadow: [
             if (isDark) BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                child: CachedNetworkImage(
                  imageUrl: prop.mainImageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorWidget: (_, __, ___) => Container(color: theme.cardColor, child: const Icon(Icons.image_outlined)),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(prop.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: theme.colorScheme.secondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text('${prop.currency}${prop.price.toStringAsFixed(0)}', 
                        style: const TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.bold, fontSize: 14)),
                      if (settings?.showTypeOnCard ?? true) ...[
                        const SizedBox(width: 8),
                        Text('• ${prop.type}', style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 10, fontWeight: FontWeight.w600)),
                      ],
                    ],
                  ),
                  if ((settings?.showBedsOnCard ?? true) || (settings?.showBathsOnCard ?? true) || (settings?.showSizeOnCard ?? false)) ...[
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          if (settings?.showBedsOnCard ?? true) 
                            _buildMicroFeature(Icons.bed_rounded, '${prop.beds}', theme),
                          if (settings?.showBathsOnCard ?? true) ...[
                            if (settings?.showBedsOnCard ?? true) const SizedBox(width: 8),
                            _buildMicroFeature(Icons.bathtub_rounded, '${prop.baths}', theme),
                          ],
                          if (settings?.showSizeOnCard ?? false) ...[
                            if ((settings?.showBedsOnCard ?? true) || (settings?.showBathsOnCard ?? true)) const SizedBox(width: 8),
                            _buildMicroFeature(Icons.square_foot_rounded, '${prop.size.toStringAsFixed(0)}m²', theme),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMicroFeature(IconData icon, String label, ThemeData theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: theme.colorScheme.secondary.withOpacity(0.3)),
        const SizedBox(width: 3),
        Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: theme.colorScheme.secondary.withOpacity(0.5))),
      ],
    );
  }

  Widget _buildListCard(Property prop, AgencySettings? settings, ThemeData theme, bool isDark) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => PropertyDetails(property: prop)),
        );
      },
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? theme.cardColor : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: theme.colorScheme.secondary.withOpacity(0.05)),
          boxShadow: [
             if (isDark) BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            SizedBox(
              width: 120,
              height: double.infinity,
              child: ClipRRect(
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(24)),
                child: CachedNetworkImage(
                  imageUrl: prop.mainImageUrl,
                  height: double.infinity,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Container(width: 120, color: theme.cardColor),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(prop.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: theme.colorScheme.secondary), maxLines: 1),
                    const SizedBox(height: 4),
                    if ((settings?.showBedsOnCard ?? true) || (settings?.showBathsOnCard ?? true) || (settings?.showSizeOnCard ?? false))
                      Row(
                        children: [
                          if (settings?.showBedsOnCard ?? true) _buildMicroFeature(Icons.bed_rounded, '${prop.beds} Beds', theme),
                          if (settings?.showBathsOnCard ?? true) ...[
                            if (settings?.showBedsOnCard ?? true) const SizedBox(width: 8),
                            _buildMicroFeature(Icons.bathtub_rounded, '${prop.baths} Baths', theme),
                          ],
                          if (settings?.showSizeOnCard ?? false) ...[
                            if ((settings?.showBedsOnCard ?? true) || (settings?.showBathsOnCard ?? true)) const SizedBox(width: 8),
                            _buildMicroFeature(Icons.square_foot_rounded, '${prop.size.toStringAsFixed(0)} m²', theme),
                          ],
                        ],
                      )
                    else
                      Text('Premium Estate', style: TextStyle(color: theme.colorScheme.secondary.withOpacity(0.5), fontSize: 12)),
                    const Spacer(),
                    Row(
                      children: [
                        Text('${prop.currency}${prop.price.toStringAsFixed(0)}', 
                          style: const TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.bold, fontSize: 16)),
                        if (settings?.showTypeOnCard ?? true) ...[
                          const SizedBox(width: 8),
                          Text('• ${prop.type}', style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
