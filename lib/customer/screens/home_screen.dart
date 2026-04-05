import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/models/property.dart';
import '../../core/services/supabase_service.dart';
import 'property_details.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  late Future<List<Property>> _propertiesFuture;

  @override
  void initState() {
    super.initState();
    // Simulate fetching live public data
    _propertiesFuture = _supabaseService.fetchProperties();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Discover Properties', style: TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.w700)),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search Bar
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Location, neighborhood, or city',
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF1E3A8A)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text('Featured', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
              const SizedBox(height: 16),
              
              // Live Properties Feed
              SizedBox(
                height: 320,
                child: FutureBuilder<List<Property>>(
                  future: _propertiesFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error loading properties: ${snapshot.error}', style: TextStyle(color: Colors.red)));
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text('No properties listed yet.'));
                    }

                    final properties = snapshot.data!;
                    return ListView.builder(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: properties.length,
                      itemBuilder: (context, index) {
                        final prop = properties[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => PropertyDetails(property: prop)));
                          },
                          child: Container(
                            width: 280,
                            margin: const EdgeInsets.only(right: 16, bottom: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 5)),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                                  child: prop.mainImageUrl.isNotEmpty
                                      ? CachedNetworkImage(
                                          imageUrl: prop.mainImageUrl,
                                          height: 200,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) => Container(color: Colors.grey[200]),
                                          errorWidget: (context, url, error) => Container(color: Colors.grey[300], child: const Icon(Icons.broken_image)),
                                        )
                                      : Container(height: 200, color: Colors.grey[300], child: const Icon(Icons.maps_home_work_outlined, size: 48, color: Colors.grey)),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('\$${prop.price.toStringAsFixed(0)}${prop.type == 'Rent' ? '/mo' : ''}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1E3A8A))),
                                      const SizedBox(height: 4),
                                      Text(prop.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                                      const SizedBox(height: 4),
                                      Text('${prop.beds} Beds • ${prop.baths} Baths • ${prop.size.toStringAsFixed(0)} sqft', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              const Text('Explore Categories', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
              const SizedBox(height: 16),
              // Category Pills
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildCategoryPill('For Rent', Icons.key),
                  _buildCategoryPill('For Sale', Icons.sell),
                  _buildCategoryPill('Apartments', Icons.apartment),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryPill(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFD0E4FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF1E3A8A)),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
        ],
      ),
    );
  }
}
