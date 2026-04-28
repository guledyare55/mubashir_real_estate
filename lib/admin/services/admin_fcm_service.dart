import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/supabase_service.dart';

class AdminFcmService {
  static final AdminFcmService _instance = AdminFcmService._internal();
  factory AdminFcmService() => _instance;
  AdminFcmService._internal();

  final _supabase = SupabaseService();
  final List<String> _scopes = ['https://www.googleapis.com/auth/firebase.messaging'];

  Future<void> sendBroadcastNotification({
    required String title,
    required String body,
  }) async {
    try {
      // 1. Load the Service Account Key
      String jsonString;
      try {
        jsonString = await rootBundle.loadString('assets/admin/firebase_service_account.json');
      } catch (e) {
        throw Exception('Firebase Service Account Key not found. Please ensure assets/admin/firebase_service_account.json exists.');
      }

      final accountCredentials = ServiceAccountCredentials.fromJson(jsonString);
      final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
      final String projectId = jsonMap['project_id'];

      // 2. Generate Access Token
      final client = await clientViaServiceAccount(accountCredentials, _scopes);

      // 3. Get all customer FCM tokens from Supabase
      final response = await Supabase.instance.client
          .from('profiles')
          .select('fcm_token');

      final List<dynamic> records = response;
      if (records.isEmpty) {
        if (kDebugMode) print('No customer devices found with FCM tokens.');
        client.close();
        return;
      }

      // 4. Send Notifications
      int successCount = 0;
      int failureCount = 0;

      // Deduplicate tokens so we don't send double notifications to the same device
      final Set<String> uniqueTokens = {};
      for (var record in records) {
        final token = record['fcm_token'];
        if (token != null && token.toString().trim().isNotEmpty) {
          uniqueTokens.add(token.toString().trim());
        }
      }

      for (var token in uniqueTokens) {
        final url = Uri.parse('https://fcm.googleapis.com/v1/projects/$projectId/messages:send');
        
        final payload = {
          'message': {
            'token': token,
            'notification': {
              'title': title,
              'body': body,
            },
            'android': {
              'notification': {
                'channel_id': 'high_importance_channel',
              }
            },
            'data': {
              'click_action': 'FLUTTER_NOTIFICATION_CLICK',
              'type': 'broadcast',
            }
          }
        };

        final fcmResponse = await client.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        );

        if (fcmResponse.statusCode == 200) {
          successCount++;
        } else {
          failureCount++;
          if (kDebugMode) print('FCM Send Error: ${fcmResponse.body}');
        }
      }

      client.close();
      if (kDebugMode) {
        print('Broadcast Complete: $successCount succeeded, $failureCount failed.');
      }

    } catch (e) {
      if (kDebugMode) print('AdminFcmService Error: $e');
      rethrow;
    }
  }
}
