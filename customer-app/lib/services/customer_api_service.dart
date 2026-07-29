import 'dart:convert';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_service.dart';

class CustomerApiService {
  CustomerApiService._();
  static final instance = CustomerApiService._();
  SupabaseClient get _db => Supabase.instance.client;

  Future<Map<String, dynamic>> call(
    String action, [
    Map<String, dynamic> body = const {},
  ]) async {
    final mobile = await AuthService.instance.currentMobile() ?? '';
    final token = await AuthService.instance.currentToken() ?? '';
    if (mobile.length != 10 || token.length < 32) {
      throw StateError('Please login again.');
    }
    try {
      final response = await _db.functions.invoke('customer-api', body: {
        'action': action,
        'mobile': mobile,
        'session_token': token,
        ...body,
      });
      final data = Map<String, dynamic>.from(response.data as Map);
      if (data['error'] != null) throw StateError('${data['error']}');
      return data;
    } on FunctionException catch (error) {
      final details = error.details;
      if (details is Map && details['error'] != null) {
        throw StateError('${details['error']}');
      }
      throw StateError('Customer service is unavailable. Please try again.');
    }
  }

  Future<String> uploadAvatar(Uint8List bytes, String extension) async {
    final result = await call('avatar', {
      'image_base64': base64Encode(bytes),
      'extension': extension,
    });
    return '${result['avatar_url'] ?? ''}';
  }
}
