import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/models/property.dart';
import 'inquiry_form_sheet.dart';

class PropertyDetails extends StatelessWidget {
  final Property property;
  const PropertyDetails({super.key, required this.property});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: CachedNetworkImage(
                imageUrl: property.mainImageUrl,
                fit: BoxFit.cover,
              ),
            ),
            actions: [
              IconButton(icon: const Icon(Icons.favorite_border, color: Colors.white), onPressed: () {}),
              IconButton(icon: const Icon(Icons.share, color: Colors.white), onPressed: () {}),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('\$${property.price.toStringAsFixed(0)}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                  const SizedBox(height: 8),
                  Text(property.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildFeatureBlock(Icons.bed, '${property.beds} Beds'),
                      _buildFeatureBlock(Icons.bathtub, '${property.baths} Baths'),
                      _buildFeatureBlock(Icons.square_foot, '${property.size.toStringAsFixed(0)} sqft'),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text('Description', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(property.description, style: TextStyle(color: Colors.grey[800], height: 1.5)),
                  const SizedBox(height: 32),
                  // Map Placeholder
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(child: Text('Map View Placeholder')),
                  ),
                  const SizedBox(height: 100), // padding for bottom bar
                ],
              ),
            ),
          )
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
        ),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true, // allows it to expand with keyboard
                    backgroundColor: Colors.transparent,
                    builder: (context) => InquiryFormSheet(property: property),
                  );
                },
                icon: const Icon(Icons.message),
                label: const Text('Inquire', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF59E0B), // Gold
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Icon(Icons.phone),
            ),
          ],
        ),
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
