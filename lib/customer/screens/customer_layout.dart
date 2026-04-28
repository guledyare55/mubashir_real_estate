import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/supabase_service.dart';
import '../../core/models/profile.dart';
import '../../core/models/property.dart';
import '../../core/models/category.dart';
import '../../core/models/agency_settings.dart';
import 'home_screen.dart';
import 'modern_auth_screen.dart';
import 'property_details.dart';
import 'notification_settings_screen.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import '../../core/models/inquiry.dart';
import '../../core/theme/theme_manager.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/localization/language_provider.dart';

class CustomerLayout extends StatefulWidget {
  const CustomerLayout({super.key});

  @override
  State<CustomerLayout> createState() => _CustomerLayoutState();
}

class _CustomerLayoutState extends State<CustomerLayout> {
  int _currentIndex = 0;
  final _supabaseService = SupabaseService();
  bool _isLoggedIn = false;
  StreamSubscription? _inquirySubscription;
  final Map<String, String> _lastKnownStatuses = {};

  @override
  void initState() {
    super.initState();
    _isLoggedIn = _supabaseService.isUserLoggedIn;

    _supabaseService.onAuthStateChange.listen((data) {
      if (mounted) {
        setState(() {
          _isLoggedIn = data.session != null;
          if (!_isLoggedIn) {
            _currentIndex = 0; // Reset to Home tab on logout
          }
        });
        if (_isLoggedIn) {
          _setupInquiryListener();
        } else {
          _inquirySubscription?.cancel();
        }
      }
    });

    if (_isLoggedIn) {
      _setupInquiryListener();
    }
  }

  void _setupInquiryListener() {
    _inquirySubscription?.cancel();
    _inquirySubscription = _supabaseService.inquiryStatusStream().listen((
      inquiries,
    ) {
      for (var inquiry in inquiries) {
        final oldStatus = _lastKnownStatuses[inquiry.id];
        if (oldStatus != null && oldStatus != inquiry.status) {
          _showEliteAlert(inquiry);
        }
        _lastKnownStatuses[inquiry.id] = inquiry.status;
      }
    });
  }

  void _showEliteAlert(Inquiry inquiry) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        content: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFF59E0B), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.notifications_active_rounded,
                  color: Color(0xFFF59E0B),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Elite Status Update',
                      style: TextStyle(
                        color: Color(0xFFF59E0B),
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      'Your inquiry for ${inquiry.property?.title ?? "property"} is now ${inquiry.status}.',
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  @override
  void dispose() {
    _inquirySubscription?.cancel();
    super.dispose();
  }

  void _switchToSearch() {
    setState(() => _currentIndex = 1);
  }

  List<Widget> get _pages => [
    HomeScreen(onSearchTap: _switchToSearch),
    const SearchView(),
    const FavoritesView(),
    const ProfileView(),
  ];

  @override
  Widget build(BuildContext context) {
    if (!_isLoggedIn) {
      return ModernAuthScreen(onLoginSuccess: () {});
    }

    final theme = Theme.of(context);
    final themeManager = Provider.of<ThemeManager>(context);
    final lang = Provider.of<LanguageProvider>(context);
    final isDark = themeManager.isDarkMode;

    return Scaffold(
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _currentIndex,
          children: _pages,
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          height: 72,
          margin: const EdgeInsets.fromLTRB(24, 0, 24, 0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(40),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B).withOpacity(0.95) : Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.5 : 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildNavItem(0, Icons.home_rounded, lang.translate('home'), isDark),
                    _buildNavItem(1, Icons.search_rounded, lang.translate('search'), isDark),
                    _buildNavItem(2, Icons.favorite_rounded, lang.translate('saved'), isDark),
                    _buildNavItem(3, Icons.person_rounded, lang.translate('profile'), isDark),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, bool isDark) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFF59E0B).withOpacity(0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? const Color(0xFFF59E0B)
                  : (isDark ? Colors.white.withOpacity(0.4) : const Color(0xFF0F172A).withOpacity(0.4)),
              size: 24,
            ),
            if (isSelected) const SizedBox(height: 4),
            if (isSelected)
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFFF59E0B),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class SearchView extends StatefulWidget {
  const SearchView({super.key});

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  final _supabaseService = SupabaseService();
  String _selectedCategory = 'All';
  late Future<List<PropertyCategory>> _categoriesFuture;
  late Future<List<Property>> _propertiesFuture;

  // Advanced Filters
  double _minPrice = 0;
  double _maxPrice = 10000;
  int? _bedrooms;
  int? _bathrooms;
  String _propertyType = 'All';

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    _categoriesFuture = _supabaseService.fetchCategories();
    _propertiesFuture = _supabaseService.fetchProperties();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final lang = Provider.of<LanguageProvider>(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              floating: true,
              backgroundColor: theme.cardColor,
              elevation: 0,
              title: Text(
                lang.translate('search_properties'),
                style: TextStyle(
                  color: theme.colorScheme.secondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(140),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: TextField(
                                decoration: InputDecoration(
                                  hintText: lang.translate('search_hint'),
                                  prefixIcon: const Icon(Icons.search_rounded),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          InkWell(
                            onTap: () => _showFilterSheet(context, theme, isDark, lang),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDark ? theme.primaryColor : const Color(0xFF0F172A),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                Icons.tune_rounded,
                                color: isDark ? theme.colorScheme.secondary : Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 50,
                      child: FutureBuilder<List<PropertyCategory>>(
                        future: _categoriesFuture,
                        builder: (context, snapshot) {
                          final categories = snapshot.data ?? [];
                          return ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: categories.length + 1,
                            itemBuilder: (context, index) {
                              final label = index == 0
                                  ? 'All'
                                  : categories[index - 1].name;
                              final isSelected = _selectedCategory == label;
                              return GestureDetector(
                                onTap: () =>
                                    setState(() => _selectedCategory = label),
                                child: _buildCategoryChip(label, isSelected),
                              );
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              sliver: StreamBuilder<List<Property>>(
                stream: _supabaseService.propertiesStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                    return const SliverToBoxAdapter(
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final allProperties = snapshot.data ?? [];
                  final filteredProperties = allProperties.where((p) {
                    bool matchCat = _selectedCategory == 'All' || p.categoryName == _selectedCategory;
                    bool matchType = _propertyType == 'All' || p.type == _propertyType;
                    bool matchPrice = p.price >= _minPrice && p.price <= _maxPrice;
                    bool matchBeds = _bedrooms == null || p.beds == _bedrooms || (_bedrooms == 4 && p.beds >= 4);
                    bool matchBaths = _bathrooms == null || p.baths == _bathrooms || (_bathrooms == 4 && p.baths >= 4);
                    return matchCat && matchType && matchPrice && matchBeds && matchBaths;
                  }).toList();

                  if (filteredProperties.isEmpty) {
                    return SliverToBoxAdapter(
                      child: Center(
                        child: Column(
                          children: [
                            const SizedBox(height: 100),
                            Icon(
                              Icons.search_off_rounded,
                              size: 64,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              lang.translate('no_properties'),
                              style: TextStyle(color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.75,
                        ),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final prop = filteredProperties[index];
                      return InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  PropertyDetails(property: prop),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(24),
                        child: Container(
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: theme.colorScheme.secondary.withOpacity(0.05),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(24),
                                  ),
                                  child: Image.network(
                                    prop.mainImageUrl,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    errorBuilder: (_, __, ___) =>
                                        Container(color: Colors.grey[100]),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${prop.currency}${prop.price.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFF59E0B),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      prop.title,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: theme.colorScheme.secondary,
                                      ),
                                      maxLines: 1,
                                    ),
                                    Text(
                                      prop.categoryName ?? 'Luxury Estate',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }, childCount: filteredProperties.length),
                  );
                },
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String label, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(right: 8, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFF59E0B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected
              ? Colors.transparent
              : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF0F172A),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  void _showFilterSheet(BuildContext context, ThemeData theme, bool isDark, LanguageProvider lang) {
    double tempMinPrice = _minPrice;
    double tempMaxPrice = _maxPrice;
    int? tempBedrooms = _bedrooms;
    int? tempBathrooms = _bathrooms;
    String tempPropertyType = _propertyType;

    final minCtrl = TextEditingController(text: tempMinPrice > 0 ? tempMinPrice.toInt().toString() : '');
    final maxCtrl = TextEditingController(text: tempMaxPrice < 10000000 ? tempMaxPrice.toInt().toString() : '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : theme.scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(color: Colors.grey[600], borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('Filter Properties', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: theme.colorScheme.secondary)),
                  const SizedBox(height: 32),
                  
                  // Property Type
                  Text('Property Type', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[500])),
                  const SizedBox(height: 12),
                  Row(
                    children: ['All', 'Sale', 'Rent'].map((type) {
                      final isSelected = tempPropertyType == type;
                      return GestureDetector(
                        onTap: () => setSheetState(() => tempPropertyType = type),
                        child: _buildFilterChip(type, isSelected, theme, isDark),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  
                  // Price Range TextFields
                  Text('Price Range (USD)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[500])),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: minCtrl,
                          keyboardType: TextInputType.number,
                          style: TextStyle(color: theme.colorScheme.secondary),
                          decoration: InputDecoration(
                            hintText: 'Min \$',
                            filled: true,
                            fillColor: isDark ? const Color(0xFF1E293B) : Colors.grey[200],
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                          ),
                          onChanged: (val) => tempMinPrice = double.tryParse(val) ?? 0,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text('-', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                      ),
                      Expanded(
                        child: TextField(
                          controller: maxCtrl,
                          keyboardType: TextInputType.number,
                          style: TextStyle(color: theme.colorScheme.secondary),
                          decoration: InputDecoration(
                            hintText: 'Max \$',
                            filled: true,
                            fillColor: isDark ? const Color(0xFF1E293B) : Colors.grey[200],
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                          ),
                          onChanged: (val) => tempMaxPrice = double.tryParse(val) ?? 10000000,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Bedrooms
                  Text('Bedrooms', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[500])),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [null, 1, 2, 3, 4].map((beds) {
                        final isSelected = tempBedrooms == beds;
                        final label = beds == null ? 'Any' : (beds == 4 ? '4+' : beds.toString());
                        return GestureDetector(
                          onTap: () => setSheetState(() => tempBedrooms = beds),
                          child: _buildFilterChip(label, isSelected, theme, isDark),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Bathrooms
                  Text('Bathrooms', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[500])),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [null, 1, 2, 3, 4].map((baths) {
                        final isSelected = tempBathrooms == baths;
                        final label = baths == null ? 'Any' : (baths == 4 ? '4+' : baths.toString());
                        return GestureDetector(
                          onTap: () => setSheetState(() => tempBathrooms = baths),
                          child: _buildFilterChip(label, isSelected, theme, isDark),
                        );
                      }).toList(),
                    ),
                  ),
                  
                  const Spacer(),
                  // Apply Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _minPrice = tempMinPrice;
                          _maxPrice = tempMaxPrice;
                          _bedrooms = tempBedrooms;
                          _bathrooms = tempBathrooms;
                          _propertyType = tempPropertyType;
                        });
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF59E0B),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Apply Filters', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, ThemeData theme, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFF59E0B) : (isDark ? const Color(0xFF1E293B) : Colors.white),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isSelected ? Colors.transparent : (isDark ? Colors.white10 : Colors.black12)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? const Color(0xFF0F172A) : theme.colorScheme.secondary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
        ),
      ),
    );
  }
}

class FavoritesView extends StatelessWidget {
  const FavoritesView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = Provider.of<LanguageProvider>(context);
    final isDark = theme.brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          lang.translate('saved'),
          style: TextStyle(color: theme.colorScheme.secondary, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      body: SafeArea(
        child: FutureBuilder<List<Property>>(
          future: SupabaseService().fetchSavedProperties(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final properties = snapshot.data ?? [];
            if (properties.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.favorite_border_rounded,
                      size: 64,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      lang.translate('no_saved'),
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: properties.length,
              itemBuilder: (context, index) {
                final prop = properties[index];
                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PropertyDetails(property: prop),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.horizontal(
                            left: Radius.circular(20),
                          ),
                          child: Image.network(
                            prop.mainImageUrl,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                Container(width: 100, color: Colors.grey[100]),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  prop.title,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: theme.colorScheme.secondary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${prop.currency}${prop.price.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    color: Color(0xFFF59E0B),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.favorite, color: Colors.red),
                          onPressed: () async {
                            await SupabaseService().toggleFavorite(prop.id);
                          },
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
    );
  }
}

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final _supabaseService = SupabaseService();
  Profile? _profile;
  AgencySettings? _settings;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await _supabaseService.getCurrentUserProfile();
    final settings = await _supabaseService.fetchAgencySettings();
    if (mounted) {
      setState(() {
        _profile = profile;
        _settings = settings;
        _isLoading = false;
      });
    }
  }

  Future<void> _showEditProfileSheet(BuildContext context) async {
    final nameCtrl = TextEditingController(text: _profile?.fullName);
    final phoneCtrl = TextEditingController(text: _profile?.phone);
    final emailCtrl = TextEditingController(text: Supabase.instance.client.auth.currentUser?.email);
    final otpCtrl = TextEditingController();
    
    bool isSaving = false;
    bool isEmailEditable = false;
    bool showOtpInput = false;
    String? originalEmail = Supabase.instance.client.auth.currentUser?.email;

    final lang = Provider.of<LanguageProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        return Scaffold(
        backgroundColor: Colors.transparent,
        resizeToAvoidBottomInset: true,
        body: StatefulBuilder(
          builder: (context, setSheetState) => GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              color: Colors.transparent,
              alignment: Alignment.bottomCenter,
              child: GestureDetector(
                onTap: () {}, // Prevent closing when tapping content
                child: Container(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
                  decoration: BoxDecoration(
                    color: isDark ? theme.scaffoldBackgroundColor : Colors.white,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                  ),
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              showOtpInput ? lang.translate('verify_email') : lang.translate('edit_profile'),
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.secondary,
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: Icon(Icons.close_rounded, color: theme.colorScheme.secondary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        if (!showOtpInput) ...[
                          _buildModernInput(
                            nameCtrl,
                            lang.translate('full_name'),
                            Icons.person_outline,
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 16),
                          _buildModernInput(
                            emailCtrl,
                            lang.translate('email_address'),
                            Icons.alternate_email_rounded,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            readOnly: !isEmailEditable,
                            suffix: TextButton(
                              onPressed: () {
                                setSheetState(() => isEmailEditable = true);
                              },
                              child: Text(
                                isEmailEditable ? lang.translate('lock') : lang.translate('edit'),
                                style: const TextStyle(
                                  color: Color(0xFFF59E0B),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildModernInput(
                            phoneCtrl,
                            lang.translate('phone_number'),
                            Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.done,
                          ),
                        ] else ...[
                          Text(
                            lang.translate('verify_email_msg'),
                            style: const TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                          const SizedBox(height: 24),
                          _buildModernInput(
                            otpCtrl,
                            lang.translate('verify_code'),
                            Icons.lock_outline,
                            keyboardType: TextInputType.number,
                            autofocus: true,
                          ),
                        ],
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: isSaving
                                ? null
                                : () async {
                                    setSheetState(() => isSaving = true);
                                    try {
                                      if (showOtpInput) {
                                        await _supabaseService.verifyEmailChange(
                                          emailCtrl.text.trim(),
                                          otpCtrl.text.trim(),
                                        );
                                        await _loadProfile();
                                        if (context.mounted) {
                                          Navigator.pop(context);
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Email updated successfully!'),
                                              backgroundColor: Colors.green,
                                            ),
                                          );
                                        }
                                      } else {
                                        await _supabaseService.updateUserProfile(
                                          fullName: nameCtrl.text.trim(),
                                          phone: phoneCtrl.text.trim(),
                                          email: emailCtrl.text.trim(),
                                        );
                                        
                                        if (emailCtrl.text.trim() != originalEmail) {
                                          setSheetState(() => showOtpInput = true);
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Verification code sent to new email.')),
                                          );
                                        } else {
                                          await _loadProfile();
                                          if (context.mounted) Navigator.pop(context);
                                        }
                                      }
                                    } catch (e) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                                      );
                                    } finally {
                                      setSheetState(() => isSaving = false);
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF59E0B),
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: isSaving
                                ? const CircularProgressIndicator(
                                    color: Colors.black,
                                    strokeWidth: 2,
                                  )
                                : Text(
                                    showOtpInput ? lang.translate('verify_code') : lang.translate('save_changes'),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        );
      },
    );
  }

  Widget _buildModernInput(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    TextInputType? keyboardType,
    bool autofocus = false,
    TextInputAction? textInputAction,
    bool readOnly = false,
    Widget? suffix,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: TextField(
        controller: ctrl,
        keyboardType: keyboardType,
        autofocus: autofocus,
        readOnly: readOnly,
        textInputAction: textInputAction,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.grey, fontSize: 13),
          prefixIcon: Icon(icon, color: const Color(0xFFF59E0B), size: 20),
          suffixIcon: suffix,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  void _showLanguageSheet(BuildContext context, LanguageProvider lang) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              lang.translate('language'),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 24),
            _buildLanguageOption(context, lang, 'English', 'en', Icons.language),
            const SizedBox(height: 12),
            _buildLanguageOption(context, lang, 'Somali', 'so', Icons.translate),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(BuildContext context, LanguageProvider lang, String name, String code, IconData icon) {
    final isSelected = lang.currentLocale.languageCode == code;
    return InkWell(
      onTap: () {
        lang.setLanguage(code);
        Navigator.pop(context);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF59E0B).withOpacity(0.1) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFFF59E0B) : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? const Color(0xFFF59E0B) : const Color(0xFF64748B)),
            const SizedBox(width: 16),
            Text(
              name,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? const Color(0xFFF59E0B) : const Color(0xFF0F172A),
              ),
            ),
            const Spacer(),
            if (isSelected)
              const Icon(Icons.check_circle, color: Color(0xFFF59E0B)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeManager = Provider.of<ThemeManager>(context);
    final lang = Provider.of<LanguageProvider>(context);
    final isDark = themeManager.isDarkMode;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(
          lang.translate('profile'),
          style: TextStyle(color: theme.colorScheme.secondary, fontWeight: FontWeight.bold),
        ),
        iconTheme: IconThemeData(color: theme.colorScheme.secondary),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(themeManager.isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
            color: theme.colorScheme.secondary,
            onPressed: () => themeManager.toggleTheme(),
          ),
          IconButton(
            icon: Icon(Icons.logout, color: theme.colorScheme.secondary),
            onPressed: () => _supabaseService.signOut(),
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(48),
                      child: Container(
                        width: 96,
                        height: 96,
                        color: const Color(0xFF1E3A8A).withOpacity(0.1),
                        child: _profile?.avatarUrl != null
                            ? CachedNetworkImage(
                                imageUrl: _profile!.avatarUrl!,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => const Center(
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                                errorWidget: (context, url, error) => const Icon(Icons.person, size: 48),
                              )
                            : const Icon(
                                Icons.person,
                                size: 48,
                                color: Color(0xFF1E3A8A),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _profile?.fullName ?? 'Valued Customer',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : theme.colorScheme.secondary,
                      ),
                    ),
                    Text(
                      _profile?.role.toUpperCase() ?? 'CUSTOMER',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 48),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: isDark ? theme.cardColor : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildSettingsTile(
                            Icons.person_outline,
                            lang.translate('edit_profile'),
                            onTap: () => _showEditProfileSheet(context),
                          ),
                          const Divider(height: 1),
                          _buildSettingsTile(
                            Icons.notifications_none,
                            lang.translate('notifications'),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const NotificationSettingsScreen(),
                                ),
                              );
                            },
                          ),
                          const Divider(height: 1),
                          _buildSettingsTile(
                            Icons.language_rounded,
                            lang.translate('language'),
                            onTap: () => _showLanguageSheet(context, lang),
                          ),
                          const Divider(height: 1),
                          _buildSettingsTile(Icons.shield_outlined, lang.translate('security')),
                          const Divider(height: 1),
                          _buildSettingsTile(
                            Icons.help_outline,
                            lang.translate('help_support'),
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  title: const Text(
                                    'Contact Support',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text(
                                        'Our team is here to help you finding your elite sanctuary.',
                                      ),
                                      const SizedBox(height: 24),
                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: const Color(
                                            0xFFF59E0B,
                                          ).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        child: InkWell(
                                          onTap: () async {
                                            if (_settings?.supportPhone == null)
                                              return;
                                            final Uri telLaunchUri = Uri(
                                              scheme: 'tel',
                                              path: _settings!.supportPhone,
                                            );
                                            if (await canLaunchUrl(
                                              telLaunchUri,
                                            )) {
                                              await launchUrl(telLaunchUri);
                                            }
                                          },
                                          child: Row(
                                            children: [
                                              const Icon(
                                                Icons.phone_rounded,
                                                color: Color(0xFFF59E0B),
                                              ),
                                              const SizedBox(width: 16),
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  const Text(
                                                    'Support Hotline',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: Colors.grey,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  Text(
                                                    _settings?.supportPhone ??
                                                        'Not Available',
                                                    style: const TextStyle(
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Color(0xFF0F172A),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const Spacer(),
                                              const Icon(
                                                Icons.arrow_forward_ios_rounded,
                                                size: 14,
                                                color: Color(0xFFF59E0B),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Close'),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildSettingsTile(
    IconData icon,
    String title, {
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Theme.of(context).colorScheme.secondary),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.secondary,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }
}
