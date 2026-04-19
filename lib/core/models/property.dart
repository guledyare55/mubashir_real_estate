class Property {
  final String id;
  final String title;
  final String description;
  final double price;
  final String type;
  final int beds;
  final int baths;
  final double size;
  final String status;
  final String mainImageUrl;
  final List<String> galleryUrls;
  final String? videoUrl;
  final double? lat;
  final double? lng;
  final String? ownerId;
  final String? agentId;

  Property({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.type,
    required this.beds,
    required this.baths,
    required this.size,
    required this.status,
    required this.mainImageUrl,
    required this.galleryUrls,
    this.videoUrl,
    this.lat,
    this.lng,
    this.ownerId,
    this.agentId,
  });

  // Convert from Supabase PostgreSQL JSON payload to Dart Object
  factory Property.fromJson(Map<String, dynamic> json) {
    return Property(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      price: (json['price'] as num).toDouble(),
      type: json['type'] as String,
      beds: json['beds'] as int? ?? 0,
      baths: json['baths'] as int? ?? 0,
      size: (json['size'] as num?)?.toDouble() ?? 0,
      status: json['status'] as String? ?? 'Available',
      mainImageUrl: json['main_image_url'] as String? ?? '',
      galleryUrls: List<String>.from(json['gallery_urls'] ?? []),
      videoUrl: json['video_url'] as String?,
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
      ownerId: json['owner_id'] as String?,
      agentId: json['agent_id'] as String?,
    );
  }

  // Convert from Dart Object to Supabase PostgreSQL Payload
  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'title': title,
      'description': description,
      'price': price,
      'type': type,
      'beds': beds,
      'baths': baths,
      'size': size,
      'status': status,
      'main_image_url': mainImageUrl,
      'gallery_urls': galleryUrls,
      if (videoUrl != null) 'video_url': videoUrl,
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
      if (ownerId != null) 'owner_id': ownerId,
      if (agentId != null) 'agent_id': agentId,
    };
  }
}
