import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/models/property.dart';
import '../../core/models/agency_settings.dart';
import '../../core/services/supabase_service.dart';
import 'inquiry_form_sheet.dart';

class PropertyDetails extends StatefulWidget {
  final Property property;
  const PropertyDetails({super.key, required this.property});

  @override
  State<PropertyDetails> createState() => _PropertyDetailsState();
}

class _PropertyDetailsState extends State<PropertyDetails> {
  final _supabaseService = SupabaseService();
  AgencySettings? _settings;

  int _currentImageIndex = 0;
  bool _isFavorite = false;
  late PageController _pageController;
  late List<String> _allImages;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _allImages = [
      widget.property.mainImageUrl,
      ...widget.property.galleryUrls,
    ].where((url) => url.isNotEmpty).toSet().toList(); // Ensure uniqueness
    
    _loadSettings();
    _checkFavoriteStatus();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final settings = await _supabaseService.fetchAgencySettings();
    if (mounted) setState(() => _settings = settings);
  }

  Future<void> _checkFavoriteStatus() async {
    final fav = await _supabaseService.isFavorite(widget.property.id);
    if (mounted) setState(() => _isFavorite = fav);
  }

  Future<void> _toggleFavorite() async {
    await _supabaseService.toggleFavorite(widget.property.id);
    _checkFavoriteStatus();
  }

  void _shareProperty() {
    final prop = widget.property;
    final shareText = '''
🏡 *${prop.title}*
💰 Price: ${prop.currency}${prop.price.toStringAsFixed(0)}
📍 Type: ${prop.type}
📏 Size: ${prop.size.toStringAsFixed(0)} m²
🛏️ ${prop.beds} Beds | 🚿 ${prop.baths} Baths

Interested? Contact *${_settings?.name ?? 'Mubashir Real Estate'}*
📞 Support: ${_settings?.supportPhone ?? 'Contact us via app'}

*Powered by Mubashir Real Estate*
''';

    Share.share(shareText, subject: 'Luxury Property: ${prop.title}');
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Property?>(
      stream: _supabaseService.propertyStream(widget.property.id),
      builder: (context, snapshot) {
        // If snapshot has data and it's null, or if it's done and no data, it means deleted
        final bool isDeleted = snapshot.hasData && snapshot.data == null;
        final property = snapshot.data ?? widget.property;

        return Scaffold(
          backgroundColor: Colors.white,
          body: Stack(
            children: [
              if (isDeleted)
                _buildDeletedOverlay()
              else
                CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // 1. Stable Interactive Gallery (Top of the list, not in the AppBar)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
                        child: SizedBox(
                          height: 400, // Fixed height for absolute layout stability
                          child: Stack(
                            children: [
                              if (_allImages.isNotEmpty)
                                PageView.builder(
                                  controller: _pageController,
                                  itemCount: _allImages.length,
                                  onPageChanged: (index) => setState(() => _currentImageIndex = index),
                                  itemBuilder: (context, index) {
                                    return CachedNetworkImage(
                                      imageUrl: _allImages[index],
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => Container(color: const Color(0xFF0F172A)),
                                    );
                                  },
                                )
                              else
                                Container(color: const Color(0xFF0F172A), child: const Icon(Icons.image_not_supported, color: Colors.white, size: 48)),
                              
                              // Status Badge (Safe Area Aware)
                              Positioned(
                                top: 12, // Reduced since parent Padding already handles safe area
                                left: 20,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: property.status == 'Available' ? const Color(0xFF10B981) : Colors.orange,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    property.status.toUpperCase(),
                                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                                  ),
                                ),
                              ),
        
                              // Image Counter
                              if (_allImages.length > 1)
                                Positioned(
                                  bottom: 20,
                                  right: 20,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.6),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      '${_currentImageIndex + 1} / ${_allImages.length}',
                                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // 2. Compact Info Section
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${property.currency}${property.price.toStringAsFixed(0)}', 
                              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                            const SizedBox(height: 8),
                            Text(property.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 24),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  _buildFeatureBlock(Icons.bed_rounded, '${property.beds} Beds'),
                                  _buildFeatureBlock(Icons.shower_rounded, '${property.baths} Baths'),
                                  _buildFeatureBlock(Icons.square_foot_rounded, '${property.size.toStringAsFixed(0)} m²'),
                                ],
                              ),
                            ),
                            const SizedBox(height: 32),
                            const Text('The Space', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            Text(property.description, style: TextStyle(color: Colors.grey[700], height: 1.6, fontSize: 15)),
                            const SizedBox(height: 32),
                            // Map Placeholder (Refined)
                            const Text('Location', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            Container(
                              height: 200,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                image: const DecorationImage(
                                  image: NetworkImage('https://images.unsplash.com/photo-1524661135-423995f22d0b?q=80&w=2074&auto=format&fit=crop'), // Premium placeholder map
                                  fit: BoxFit.cover,
                                  opacity: 0.6,
                                ),
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Center(
                                child: Icon(Icons.location_on, color: Color(0xFF1E3A8A), size: 48),
                              ),
                            ),
                            const SizedBox(height: 120), // Padding for bottom bar
                          ],
                        ),
                      ),
                    )
                  ],
                ),

              // 3. Floating Top Actions (Always Pinned, but no layout conflict)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 12, left: 8, right: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back_ios_new, color: isDeleted ? Colors.black87 : Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      if (!isDeleted)
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                _isFavorite ? Icons.favorite : Icons.favorite_border,
                                color: _isFavorite ? Colors.red : Colors.white,
                              ),
                              onPressed: _toggleFavorite,
                            ),
                            IconButton(
                              icon: const Icon(Icons.share, color: Colors.white), 
                              onPressed: _shareProperty,
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          bottomSheet: isDeleted ? null : Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -10))],
            ),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => InquiryFormSheet(property: property),
                      );
                    },
                    icon: const Icon(Icons.mail_rounded),
                    label: const Text('Inquire Now', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A8A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                InkWell(
                  onTap: () {
                    final phone = _settings?.supportPhone;
                    if (phone != null && phone.isNotEmpty) {
                      launchUrl(Uri.parse('tel:$phone'));
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Support phone number not configured.'))
                      );
                    }
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.phone_in_talk_rounded, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    );
  }

  Widget _buildDeletedOverlay() {
    return Container(
      width: double.infinity,
      color: const Color(0xFFF8FAFC),
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.inventory_2_outlined, color: Color(0xFFF59E0B), size: 64),
          ),
          const SizedBox(height: 32),
          const Text(
            'Property No Longer Available',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 16),
          const Text(
            'This property may have been leased, sold, or recently removed from our elite portfolio.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey, height: 1.5),
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F172A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Return to Listings', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () {
              final phone = _settings?.supportPhone;
              if (phone != null) launchUrl(Uri.parse('tel:$phone'));
            },
            icon: const Icon(Icons.support_agent_rounded, size: 20),
            label: const Text('Contact Customer Care'),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFF1E3A8A)),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureBlock(IconData icon, String text) {
    return Column(
      children: [
        Icon(icon, color: Colors.grey[600]),
        const SizedBox(height: 4),
        Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}
