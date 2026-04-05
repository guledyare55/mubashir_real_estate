import 'package:flutter/material.dart';
import '../../core/services/supabase_service.dart';
import '../../core/models/profile.dart';
import 'home_screen.dart';
import 'customer_auth_screen.dart';

class CustomerLayout extends StatefulWidget {
  const CustomerLayout({super.key});

  @override
  State<CustomerLayout> createState() => _CustomerLayoutState();
}

class _CustomerLayoutState extends State<CustomerLayout> {
  int _currentIndex = 0;
  final _supabaseService = SupabaseService();
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _isLoggedIn = _supabaseService.isUserLoggedIn;
    
    // Listen for login/logout natively to instantly swap screens
    _supabaseService.onAuthStateChange.listen((data) {
      if (mounted) {
        setState(() {
          _isLoggedIn = data.session != null;
        });
      }
    });
  }

  Widget _buildAuthGate(Widget authenticatedView) {
    if (_isLoggedIn) return authenticatedView;
    return CustomerAuthScreen(
      onLoginSuccess: () {
        // Auth state listener handles the rebuild automatically!
      },
    );
  }

  // Generate pages dynamically based on login state
  List<Widget> get _pages => [
    const HomeScreen(),
    const SearchView(),
    _buildAuthGate(const FavoritesView()),
    _buildAuthGate(const ProfileView()),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _pages[_currentIndex],
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: Colors.white,
        elevation: 10,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.search), label: 'Search'),
          NavigationDestination(icon: Icon(Icons.favorite_border), label: 'Favorites'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) {
          setState(() {
            _currentIndex = idx;
          });
        },
      ),
    );
  }
}

class SearchView extends StatelessWidget {
  const SearchView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('Search', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'City, neighborhood...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(color: const Color(0xFF1E3A8A), borderRadius: BorderRadius.circular(12)),
                  child: IconButton(icon: const Icon(Icons.tune, color: Colors.white), onPressed: () {}),
                )
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: GridView.builder(
                physics: const BouncingScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 0.75
                ),
                itemCount: 4,
                itemBuilder: (context, index) {
                  return Container(
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: Container(decoration: BoxDecoration(color: Colors.grey[300], borderRadius: const BorderRadius.vertical(top: Radius.circular(16))))),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text('\$2,500/mo', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                              Text('Luxury Condo', style: TextStyle(fontWeight: FontWeight.w500)),
                            ],
                          ),
                        )
                      ],
                    ),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}

class FavoritesView extends StatelessWidget {
  const FavoritesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('Saved Properties', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 2,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                Container(
                  width: 120, height: 120,
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: const BorderRadius.horizontal(left: Radius.circular(16))),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Modern Villa', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                        const SizedBox(height: 8),
                        const Text('\$1,250,000', style: TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                IconButton(icon: const Icon(Icons.favorite, color: Colors.red), onPressed: () {})
              ],
            ),
          );
        },
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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await _supabaseService.getCurrentUserProfile();
    if (mounted) {
      setState(() {
        _profile = profile;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('My Profile', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black87),
            onPressed: () => _supabaseService.signOut(),
          )
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                const SizedBox(height: 24),
                // Hero Header
                CircleAvatar(
                  radius: 48,
                  backgroundColor: const Color(0xFF1E3A8A).withOpacity(0.1),
                  backgroundImage: _profile?.avatarUrl != null ? NetworkImage(_profile!.avatarUrl!) : null,
                  child: _profile?.avatarUrl == null ? const Icon(Icons.person, size: 48, color: Color(0xFF1E3A8A)) : null,
                ),
                const SizedBox(height: 16),
                Text(_profile?.fullName ?? 'Valued Customer', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
                Text(_profile?.role.toUpperCase() ?? 'CUSTOMER', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.blue, letterSpacing: 1.2)),
                
                const SizedBox(height: 48),
                
                // Settings List
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    children: [
                      _buildSettingsTile(Icons.person_outline, 'Edit Profile'),
                      const Divider(height: 1),
                      _buildSettingsTile(Icons.notifications_none, 'Notifications'),
                      const Divider(height: 1),
                      _buildSettingsTile(Icons.shield_outlined, 'Security'),
                      const Divider(height: 1),
                      _buildSettingsTile(Icons.help_outline, 'Help & Support'),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
    );
  }

  Widget _buildSettingsTile(IconData icon, String title) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: Colors.black87),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: () {},
    );
  }
}
