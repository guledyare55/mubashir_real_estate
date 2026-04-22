import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/category.dart';
import '../models/property.dart';
import '../models/inquiry.dart';
import '../models/profile.dart';
import '../models/agency_settings.dart';
import '../models/owner.dart';
import '../models/rental.dart';
import '../models/payout.dart';
import '../models/employee.dart';
import '../models/office_expense.dart';
import '../models/notification.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  // --- CATEGORIES ---

  Future<List<PropertyCategory>> fetchCategories() async {
    final response = await _client.from('categories').select().order('name', ascending: true);
    return (response as List).map((json) => PropertyCategory.fromJson(json)).toList();
  }

  Future<void> addCategory(String name) async {
    await _client.from('categories').insert({'name': name});
  }

  Future<void> deleteCategory(String id) async {
    await _client.from('categories').delete().eq('id', id);
  }

  Future<Map<String, int>> fetchCategoryStats() async {
    final response = await _client.from('properties').select('category_name');
    final Map<String, int> stats = {};
    for (var row in (response as List)) {
      final cat = row['category_name'] as String?;
      if (cat != null) {
        stats[cat] = (stats[cat] ?? 0) + 1;
      }
    }
    return stats;
  }

  // --- AUTHENTICATION ---

  Future<AuthResponse> signInAdmin(String email, String password) async {
    final response = await _client.auth.signInWithPassword(email: email, password: password);
    final profile = await getCurrentUserProfile();
    if (profile == null || profile.role != 'admin') {
      await signOut();
      throw Exception('Access Denied: You do not have administrative privileges.');
    }
    return response;
  }

  Future<AuthResponse> signInCustomer(String email, String password) async {
    final response = await _client.auth.signInWithPassword(email: email, password: password);
    final profile = await getCurrentUserProfile();
    if (profile != null && profile.role == 'admin') {
      await signOut();
      throw Exception('Admin accounts must use the Administrative Portal. Access to the customer app is restricted.');
    }
    return response;
  }

  Future<void> signInWithGoogle() async {
    await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'com.guledyare55.mubashir://login-callback',
    );
  }

  Future<bool> checkIfUserExists(String email) async {
    final response = await _client.from('profiles').select().eq('email', email);
    return (response as List).isNotEmpty;
  }

  Future<AuthResponse> signUpCustomer(String email, String password, String fullName, {String? phone}) async {
    return await _client.auth.signUp(
      email: email, 
      password: password,
      data: {'full_name': fullName, if (phone != null) 'phone': phone},
    );
  }

  Future<void> registerWalkInCustomer(String email, String fullName, String phone) async {
    final url = Uri.parse('${dotenv.env['SUPABASE_URL']}/auth/v1/signup');
    final response = await http.post(
      url,
      headers: {'apikey': dotenv.env['SUPABASE_ANON_KEY'] ?? '', 'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': 'WalkInUser2026!',
        'data': {'full_name': fullName, 'phone': phone}
      })
    );
    if (response.statusCode >= 400) throw Exception('Failed to register natively: ${response.body}');
  }

  Future<void> signOut() async => await _client.auth.signOut();
  bool get isUserLoggedIn => _client.auth.currentUser != null;
  String? get currentUserEmail => _client.auth.currentUser?.email;
  Stream<AuthState> get onAuthStateChange => _client.auth.onAuthStateChange;

  Future<void> verifyOtp(String email, String token, {OtpType type = OtpType.signup}) async {
    await _client.auth.verifyOTP(
      email: email,
      token: token,
      type: type,
    );
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  Future<void> updatePassword(String newPassword) async {
    await _client.auth.updateUser(UserAttributes(password: newPassword));
  }

  // --- PROPERTIES ---

  Future<List<Property>> fetchProperties() async {
    final response = await _client.from('properties').select().order('created_at', ascending: false);
    return (response as List).map((json) => Property.fromJson(json)).toList();
  }

  Stream<List<Property>> get propertiesStream {
    return _client.from('properties')
      .stream(primaryKey: ['id'])
      .order('created_at', ascending: false)
      .map((data) => data.map((json) => Property.fromJson(json)).toList());
  }

  Stream<Property?> propertyStream(String id) {
    return _client.from('properties')
      .stream(primaryKey: ['id'])
      .eq('id', id)
      .map((data) => data.isNotEmpty ? Property.fromJson(data.first) : null);
  }

  Future<void> addProperty(Property property) async {
    await _client.from('properties').insert(property.toJson());
  }

  Future<void> updateProperty(Property property) async {
    await _client.from('properties').update(property.toJson()).eq('id', property.id);
  }

  Future<void> deleteProperty(String id) async {
    // 1. Fetch the property to get its image URLs before deleting
    final response = await _client.from('properties').select().eq('id', id).single();
    if (response != null) {
      final property = Property.fromJson(response);
      // 2. Delete images from storage
      final images = property.galleryUrls;
      if (images.isNotEmpty) {
        await deleteImages(images);
      }
    }
    // 3. Delete the database record
    await _client.from('properties').delete().eq('id', id);
  }

  // --- OWNERS ---

  Future<List<Owner>> fetchOwners() async {
    final response = await _client.from('owners').select().order('created_at', ascending: false);
    return (response as List).map((json) => Owner.fromJson(json)).toList();
  }

  Future<void> addOwner(Owner owner) async {
    await _client.from('owners').insert(owner.toJson());
  }

  Future<void> deleteOwner(String id) async {
    await _client.from('owners').delete().eq('id', id);
  }

  // --- RENTALS & PAYOUTS ---

  Future<List<Rental>> fetchActiveRentals() async {
    final response = await _client.from('rentals').select().eq('status', 'Active').order('created_at', ascending: false);
    return (response as List).map((json) => Rental.fromJson(json)).toList();
  }

  Future<void> createRental(Rental rental) async {
    // 1. Create the rental agreement
    final rentalResponse = await _client.from('rentals').insert(rental.toJson()).select().single();
    final String rentalId = rentalResponse['id'];
    
    // 2. Mark property as 'Rented'
    await _client.from('properties').update({'status': 'Rented'}).eq('id', rental.propertyId);

    // 3. Create the initial Payout record (Owner 100% + Agency 10% Extra)
    final double agencyCut = rental.monthlyRent * (rental.commissionRate / 100);
    final double ownerCut = rental.monthlyRent; // Owner receives 100%
    final double totalCollected = ownerCut + agencyCut;

    final payout = Payout(
      id: '',
      rentalId: rentalId,
      amount: totalCollected,
      agencyCut: agencyCut,
      ownerCut: ownerCut,
      createdAt: DateTime.now(),
    );

    await _client.from('payouts').insert(payout.toJson());
  }

  Future<List<Payout>> fetchPayouts() async {
    final response = await _client.from('payouts').select().order('created_at', ascending: false);
    return (response as List).map((json) => Payout.fromJson(json)).toList();
  }

  Future<void> markPayoutAsPaid(String payoutId) async {
    await _client.from('payouts').update({
      'is_paid_to_owner': true,
      'payout_date': DateTime.now().toIso8601String(),
    }).eq('id', payoutId);
  }

  // --- INQUIRIES & PROFILES ---

  Future<List<Inquiry>> fetchInquiries() async {
    final response = await _client.from('inquiries').select('*, property:properties(*)').order('created_at', ascending: false);
    return (response as List).map((json) => Inquiry.fromJson(json)).toList();
  }

  Future<void> updateInquiryStatus(String id, String status) async {
    await _client.from('inquiries').update({'status': status}).eq('id', id);
  }

  Future<void> deleteInquiry(String id) async {
    await _client.from('inquiries').delete().eq('id', id);
  }

  Future<void> submitInquiry(Inquiry inquiry) async {
    final userId = _client.auth.currentUser?.id;
    final data = inquiry.toJson();
    // Normalize email for consistent duplication checking
    if (data['customer_email'] != null) {
      data['customer_email'] = data['customer_email'].toString().toLowerCase().trim();
    }
    if (userId != null) {
      data['customer_id'] = userId;
    }
    await _client.from('inquiries').insert(data);
  }

  Future<bool> hasAlreadyInquired(String propertyId, String email) async {
    final lowerEmail = email.toLowerCase().trim();
    final response = await _client
        .from('inquiries')
        .select('id')
        .eq('property_id', propertyId)
        .ilike('customer_email', lowerEmail)
        .limit(1);
    
    final List data = response as List;
    return data.isNotEmpty;
  }

  Stream<List<Inquiry>> inquiryStatusStream() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return Stream.value([]);
    
    // Listen to changes in the inquiries table for this specific customer
    return _client
        .from('inquiries')
        .stream(primaryKey: ['id'])
        .eq('customer_id', userId)
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => Inquiry.fromJson(json)).toList());
  }

  Stream<List<Inquiry>> adminInquiryStream() {
    // We fetch the properties list first to map them to inquiries in the stream
    // as Supabase real-time streams do not support joins.
    return _client
        .from('inquiries')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .asyncMap((data) async {
          final inquiries = data.map((json) => Inquiry.fromJson(json)).toList();
          
          // Enrich with property data
          for (var i = 0; i < inquiries.length; i++) {
            final propResponse = await _client
                .from('properties')
                .select()
                .eq('id', inquiries[i].propertyId)
                .maybeSingle();
            
            if (propResponse != null) {
              inquiries[i] = Inquiry(
                id: inquiries[i].id,
                propertyId: inquiries[i].propertyId,
                customerId: inquiries[i].customerId,
                customerName: inquiries[i].customerName,
                customerEmail: inquiries[i].customerEmail,
                customerPhone: inquiries[i].customerPhone,
                message: inquiries[i].message,
                status: inquiries[i].status,
                createdAt: inquiries[i].createdAt,
                property: Property.fromJson(propResponse),
              );
            }
          }
          return inquiries;
        });
  }

  Future<List<Profile>> fetchProfiles() async {
    final response = await _client.from('profiles').select().order('created_at', ascending: false);
    return (response as List).map((json) => Profile.fromJson(json)).toList();
  }

  Future<Profile?> getCurrentUserProfile() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;
    final response = await _client.from('profiles').select().eq('id', userId).maybeSingle();
    return response != null ? Profile.fromJson(response) : null;
  }

  Future<void> updateNotificationPreferences(Map<String, bool> prefs) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    await _client.from('profiles').update({'notification_preferences': prefs}).eq('id', userId);
  }

  Future<void> updateFcmToken(String? token) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    await _client.from('profiles').update({'fcm_token': token}).eq('id', userId);
  }

  Future<void> updateUserProfile({String? fullName, String? phone}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    final updates = {
      if (fullName != null) 'full_name': fullName,
      if (phone != null) 'phone': phone,
    };

    if (updates.isEmpty) return;
    await _client.from('profiles').update(updates).eq('id', userId);
  }

  // --- AGENCY SETTINGS ---

  Future<AgencySettings> fetchAgencySettings() async {
    final response = await _client.from('agency_settings').select().eq('id', 1).single();
    return AgencySettings.fromJson(response);
  }

  Future<void> updateAgencySettings(AgencySettings settings) async {
    await _client.from('agency_settings').update(settings.toJson()).eq('id', 1);
  }

  // --- OFFICE MANAGEMENT (STAFF & EXPENSES) ---

  Future<List<Employee>> fetchEmployees() async {
    final response = await _client.from('employees').select().order('joined_at', ascending: false);
    return (response as List).map((json) => Employee.fromJson(json)).toList();
  }

  Future<void> addEmployee(Employee employee) async {
    await _client.from('employees').insert(employee.toJson());
  }

  Future<void> updateEmployee(Employee employee) async {
    await _client.from('employees').update(employee.toJson()).eq('id', employee.id);
  }

  Future<void> deleteEmployee(String id) async {
    await _client.from('employees').delete().eq('id', id);
  }

  Future<List<OfficeExpense>> fetchOfficeExpenses() async {
    final response = await _client.from('office_expenses').select().order('date', ascending: false);
    return (response as List).map((json) => OfficeExpense.fromJson(json)).toList();
  }

  Future<void> addOfficeExpense(OfficeExpense expense) async {
    await _client.from('office_expenses').insert(expense.toJson());
  }

  Future<void> deleteOfficeExpense(String id) async {
    await _client.from('office_expenses').delete().eq('id', id);
  }

  // --- ENTERPRISE: PAYROLL & PERFORMANCE ---

  Future<void> processPayroll(Employee employee) async {
    // 1. Record the salary as an office expense
    final payrollExpense = OfficeExpense(
      id: '',
      title: 'Monthly Salary: ${employee.name}',
      amount: employee.salary,
      category: 'Payroll',
      date: DateTime.now(),
    );
    await addOfficeExpense(payrollExpense);

    // 2. Update the employee's last_pay_date
    await _client.from('employees').update({
      'last_pay_date': DateTime.now().toIso8601String(),
    }).eq('id', employee.id);
  }

  Future<Map<String, int>> fetchAgentPerformance(String agentId) async {
    final propsResponse = await _client.from('properties').select('id').eq('agent_id', agentId);
    final rentalsResponse = await _client.from('rentals').select('id').eq('agent_id', agentId);
    
    return {
      'properties': (propsResponse as List).length,
      'rentals': (rentalsResponse as List).length,
    };
  }

  // --- FAVORITES ---

  Future<bool> isFavorite(String propertyId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return false;
    final response = await _client.from('user_favorites')
        .select()
        .eq('user_id', userId)
        .eq('property_id', propertyId)
        .maybeSingle();
    return response != null;
  }

  Future<void> toggleFavorite(String propertyId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    final currentlyFav = await isFavorite(propertyId);
    if (currentlyFav) {
      await _client.from('user_favorites').delete().eq('user_id', userId).eq('property_id', propertyId);
    } else {
      await _client.from('user_favorites').insert({'user_id': userId, 'property_id': propertyId});
    }
  }

  Future<List<Property>> fetchSavedProperties() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];
    
    // Join favorites with properties
    final response = await _client.from('user_favorites')
        .select('properties!inner(*)')
        .eq('user_id', userId);
    
    return (response as List).map((row) => Property.fromJson(row['properties'])).toList();
  }

  // --- STORAGE ---

  Future<String> uploadPropertyImage(Uint8List bytes, String fileName) async {
    final path = 'prop_${DateTime.now().millisecondsSinceEpoch}_$fileName';
    await _client.storage.from('properties').uploadBinary(path, bytes, fileOptions: const FileOptions(cacheControl: '3600', upsert: true));
    return _client.storage.from('properties').getPublicUrl(path);
  }

  Future<String> uploadAgencyLogo(Uint8List bytes, String fileName) async {
    final path = 'logo_${DateTime.now().millisecondsSinceEpoch}_$fileName';
    await _client.storage.from('branding').uploadBinary(path, bytes, fileOptions: const FileOptions(cacheControl: '3600', upsert: true));
    return _client.storage.from('branding').getPublicUrl(path);
  }

  Future<String> uploadIdentityDocument(Uint8List bytes, String fileName, String userId) async {
    final path = 'kyc/${userId}_${DateTime.now().millisecondsSinceEpoch}_$fileName';
    await _client.storage.from('kyc').uploadBinary(path, bytes, fileOptions: const FileOptions(cacheControl: '3600', upsert: true));
    return _client.storage.from('kyc').getPublicUrl(path);
  }

  Future<void> updateCustomerKyc(String userId, String idType, String? frontUrl, String? backUrl) async {
    await _client.from('profiles').update({
      'id_type': idType,
      if (frontUrl != null) 'id_front_url': frontUrl,
      if (backUrl != null) 'id_back_url': backUrl,
    }).eq('id', userId);
  }

  Future<String> uploadLeaseDocument(Uint8List bytes, String userId) async {
    final path = 'leases/${userId}_${DateTime.now().millisecondsSinceEpoch}_lease.pdf';
    await _client.storage.from('kyc').uploadBinary(path, bytes, fileOptions: const FileOptions(contentType: 'application/pdf', cacheControl: '3600', upsert: true));
    return _client.storage.from('kyc').getPublicUrl(path);
  }

  Future<void> updateCustomerLease(String userId, String? leaseUrl) async {
    await _client.from('profiles').update({
      'lease_url': leaseUrl,
    }).eq('id', userId);
  }

  Future<void> deleteLeaseDocument(String userId, String leaseUrl) async {
    // 1. Remove from storage
    await deleteImages([leaseUrl], bucket: 'kyc');
    // 2. Clear from database
    await updateCustomerLease(userId, null);
  }

  Future<int> deleteImages(List<String> urls, {String bucket = 'properties'}) async {
    if (urls.isEmpty) return 0;
    
    final List<String> paths = urls.map((url) {
      try {
        final uri = Uri.parse(url);
        final path = uri.path;
        final parts = path.split('/$bucket/');
        if (parts.length > 1) {
          return Uri.decodeFull(parts.last);
        }
        return '';
      } catch (e) {
        print('Error parsing image URL for deletion: $e');
        return '';
      }
    }).where((path) => path.isNotEmpty).toList();

    if (paths.isEmpty) return 0;

    // No local try-catch here, let the UI handle the exception so we see the real error
    final List response = await _client.storage.from(bucket).remove(paths);
    return response.length;
  }

  // --- NOTIFICATIONS ---

  Future<List<AppNotification>> fetchNotifications() async {
    final user = _client.auth.currentUser;
    // Fetch global (user_id IS NULL) and specific user notifications
    final response = await _client
        .from('notifications')
        .select()
        .or('user_id.is.null,user_id.eq.${user?.id}')
        .order('created_at', ascending: false);

    return (response as List).map((json) => AppNotification.fromJson(json)).toList();
  }

  Future<void> markNotificationAsRead(String id) async {
    await _client.from('notifications').update({'is_read': true}).eq('id', id);
  }

  Future<void> broadcastAnnouncement(String title, String message, String type) async {
    // 1. Create In-App Global Notification (user_id is NULL)
    await _client.from('notifications').insert({
      'title': title,
      'message': message,
      'type': type,
      'is_read': false,
      'user_id': null, // Global broadcast
    });

    // 2. Placeholder for Push Notifications (FCM)
    // To trigger real push notifications for all users, 
    // a Supabase Edge Function or similar backend trigger 
    // should be hooked to the 'notifications' table insert event.
  }
}
