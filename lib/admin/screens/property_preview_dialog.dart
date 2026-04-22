import 'package:flutter/material.dart';
import '../../core/models/property.dart';

class PropertyPreviewDialog extends StatefulWidget {
  final Property property;

  const PropertyPreviewDialog({super.key, required this.property});

  @override
  State<PropertyPreviewDialog> createState() => _PropertyPreviewDialogState();
}

class _PropertyPreviewDialogState extends State<PropertyPreviewDialog> {
  final PageController _pageController = PageController();
  final ScrollController _scrollController = ScrollController();
  int _currentPage = 0;
  late final List<String> _allImages;

  @override
  void initState() {
    super.initState();
    
    // Combine main image and gallery, removing duplicates
    _allImages = [
      if (widget.property.mainImageUrl.isNotEmpty) widget.property.mainImageUrl,
      ...widget.property.galleryUrls.where((url) => url != widget.property.mainImageUrl),
    ];
    
    // If absolutely empty, add a placeholder logic later, but for now assume we have at least one
    if (_allImages.isEmpty) {
      _allImages.add(''); // Handle empty case gracefully
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 1100, maxHeight: 750),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A), // Deep navy background
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 40,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left Side: Interactive High-Impact Image Gallery
              Expanded(
                flex: 12,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Image Carousel
                    PageView.builder(
                      controller: _pageController,
                      onPageChanged: (index) => setState(() => _currentPage = index),
                      itemCount: _allImages.length,
                      itemBuilder: (context, index) {
                        final url = _allImages[index];
                        return url.isEmpty 
                          ? Container(color: colorScheme.surfaceVariant, child: const Icon(Icons.home_rounded, size: 64))
                          : Image.network(
                              url,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: colorScheme.surfaceVariant,
                                child: const Icon(Icons.broken_image_rounded, size: 64, color: Colors.grey),
                              ),
                            );
                      },
                    ),
                    
                    // Gradient Overlays
                    Positioned.fill(
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withOpacity(0.4),
                                Colors.transparent,
                                Colors.black.withOpacity(0.7),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Navigation Arrows (Only if multiple images)
                    if (_allImages.length > 1) ...[
                      Positioned(
                        left: 20,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
                              borderRadius: BorderRadius.circular(30),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.5),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                                ),
                                child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 20,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
                              borderRadius: BorderRadius.circular(30),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.5),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                                ),
                                child: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 20),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],

                    // Minimalist 'Pro' Image Counter
                    Positioned(
                      top: 24,
                      right: 24,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.white.withOpacity(0.2)),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10),
                          ],
                        ),
                        child: Text(
                          '${_currentPage + 1} / ${_allImages.length}',
                          style: const TextStyle(
                            color: Colors.white, 
                            fontSize: 14, 
                            fontWeight: FontWeight.w900, 
                            letterSpacing: 1.5
                          ),
                        ),
                      ),
                    ),

                    // Header Actions (Back Button)
                    Positioned(
                      top: 24,
                      left: 24,
                      child: CircleAvatar(
                        backgroundColor: Colors.black.withOpacity(0.5),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ),
                    
                    // Badges & Title Overlay
                    Positioned(
                      bottom: 32,
                      left: 24,
                      right: 24,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              (widget.property.categoryName ?? 'Listing').toUpperCase(),
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            widget.property.title,
                            style: const TextStyle(
                              color: Colors.white, 
                              fontSize: 32, 
                              fontWeight: FontWeight.bold,
                              shadows: [Shadow(color: Colors.black, blurRadius: 8)],
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (widget.property.location != null)
                            Row(
                              children: [
                                const Icon(Icons.location_on_rounded, color: Colors.amber, size: 24),
                                const SizedBox(width: 8),
                                Text(
                                  widget.property.location!.toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.amber, 
                                    fontSize: 18, 
                                    fontWeight: FontWeight.w900, 
                                    letterSpacing: 2,
                                    shadows: [Shadow(color: Colors.black, blurRadius: 4, offset: Offset(0, 2))],
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Right Side: Premium Details
              Expanded(
                flex: 8,
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'LISTING PRICE',
                                style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${widget.property.currency}${widget.property.price.toStringAsFixed(0)}',
                                style: TextStyle(color: colorScheme.primary, fontSize: 32, fontWeight: FontWeight.w900),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Icon(Icons.map_rounded, color: Colors.white.withOpacity(0.4), size: 16),
                                  const SizedBox(width: 8),
                                  Text(
                                    widget.property.location ?? 'Neighborhood not specified',
                                    style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14, fontStyle: widget.property.location == null ? FontStyle.italic : FontStyle.normal),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: widget.property.status == 'Available' ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: (widget.property.status == 'Available' ? Colors.green : Colors.orange).withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              widget.property.status.toUpperCase(),
                              style: TextStyle(
                                color: widget.property.status == 'Available' ? Colors.green : Colors.orange,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      const Divider(color: Colors.white10),
                      const SizedBox(height: 32),
                      Text(
                        'DESCRIPTION',
                        style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: Scrollbar(
                          controller: _scrollController,
                          thumbVisibility: true,
                          child: SingleChildScrollView(
                            controller: _scrollController,
                            physics: const BouncingScrollPhysics(),
                            child: Text(
                              widget.property.description,
                              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 16, height: 1.6),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      const Divider(color: Colors.white10),
                      const SizedBox(height: 32),
                      Text(
                        'SPECIFICATIONS',
                        style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildSpecItem(Icons.king_bed_outlined, '${widget.property.beds} Bedrooms', colorScheme.primary),
                          _buildSpecItem(Icons.bathtub_outlined, '${widget.property.baths} Bathrooms', colorScheme.primary),
                          _buildSpecItem(Icons.square_foot_outlined, '${widget.property.size.toInt()} sqft', colorScheme.primary),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpecItem(IconData icon, String label, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 12),
        Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
