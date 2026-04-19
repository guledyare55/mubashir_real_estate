import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/property.dart';
import '../models/inquiry.dart';
import '../models/profile.dart';
import '../models/agency_settings.dart';
import '../models/owner.dart';
import '../models/rental.dart';
import '../models/payout.dart';
import '../models/employee.dart';
import '../models/office_expense.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

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
    return await _client.auth.signInWithPassword(email: email, password: password);
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

  // --- PROPERTIES ---

  Future<List<Property>> fetchProperties() async {
    final response = await _client.from('properties').select().order('created_at', ascending: false);
    return (response as List).map((json) => Property.fromJson(json)).toList();
  }

  Future<void> addProperty(Property property) async {
    await _client.from('properties').insert(property.toJson());
  }

  Future<void> updateProperty(Property property) async {
    await _client.from('properties').update(property.toJson()).eq('id', property.id);
  }

  Future<void> deleteProperty(String id) async {
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

  Future<void> submitInquiry(Inquiry inquiry) async {
    await _client.from('inquiries').insert(inquiry.toJson());
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
}
