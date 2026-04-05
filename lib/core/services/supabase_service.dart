import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/property.dart';
import '../models/inquiry.dart';
import '../models/profile.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  // --- AUTHENTICATION (ADMIN & CUSTOMER) ---

  Future<AuthResponse> signInAdmin(String email, String password) async {
    return await _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<AuthResponse> signInCustomer(String email, String password) async {
    return await _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<AuthResponse> signUpCustomer(String email, String password, String fullName, {String? phone}) async {
    return await _client.auth.signUp(
      email: email, 
      password: password,
      data: {
        'full_name': fullName,
        if (phone != null) 'phone': phone,
      }, // Tells our PostgreSQL trigger to generate a Profile!
    );
  }

  /// REST-API level Signup to bypass Flutter SDK's auto-login behavior!
  /// Perfect for Admin's registering walk-ins without dropping their current session.
  Future<void> registerWalkInCustomer(String email, String fullName, String phone) async {
    final url = Uri.parse('${dotenv.env['SUPABASE_URL']}/auth/v1/signup');
    
    final response = await http.post(
      url,
      headers: {
        'apikey': dotenv.env['SUPABASE_ANON_KEY'] ?? '',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': email,
        'password': 'WalkInUser2026!', // They can reset this later via Forgot Password
        'data': {
          'full_name': fullName,
          'phone': phone,
        }
      })
    );
    
    if (response.statusCode >= 400) {
      throw Exception('Failed to register walk-in client natively: ${response.body}');
    }
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  bool get isUserLoggedIn => _client.auth.currentUser != null;
  String? get currentUserEmail => _client.auth.currentUser?.email;

  // Listen to Auth State Changes natively
  Stream<AuthState> get onAuthStateChange => _client.auth.onAuthStateChange;

  // --- DATABASE INTERACTIONS ---

  /// Fetch all properties for both Customer and Admin apps
  Future<List<Property>> fetchProperties() async {
    final response = await _client
        .from('properties')
        .select()
        .order('created_at', ascending: false);
    
    return (response as List).map((json) => Property.fromJson(json)).toList();
  }

  /// Add a new property (Admin Only)
  Future<void> addProperty(Property property) async {
    await _client.from('properties').insert(property.toJson());
  }

  /// Delete a property (Admin Only)
  Future<void> deleteProperty(String id) async {
    await _client.from('properties').delete().eq('id', id);
  }

  // --- INQUIRIES INTERACTIONS ---

  /// Submit an inquiry (Public/Customer App)
  Future<void> submitInquiry(Inquiry inquiry) async {
    await _client.from('inquiries').insert(inquiry.toJson());
  }

  /// Fetch all inquiries (Admin Only)
  Future<List<Inquiry>> fetchInquiries() async {
    final response = await _client
        .from('inquiries')
        .select()
        .order('created_at', ascending: false);
    
    return (response as List).map((json) => Inquiry.fromJson(json)).toList();
  }

  /// Update an inquiry's status (Admin Only)
  Future<void> updateInquiryStatus(String id, String status) async {
    await _client.from('inquiries').update({'status': status}).eq('id', id);
  }

  // --- PROFILES INTERACTIONS ---

  /// Fetch all profiles registered to the platform (Admin Only)
  Future<List<Profile>> fetchProfiles() async {
    final response = await _client
        .from('profiles')
        .select()
        .order('created_at', ascending: false);
        
    return (response as List).map((json) => Profile.fromJson(json)).toList();
  }

  /// Get the currently logged in user's profile natively
  Future<Profile?> getCurrentUserProfile() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    final response = await _client.from('profiles').select().eq('id', userId).maybeSingle();
    if (response == null) return null;

    return Profile.fromJson(response);
  }
}
