import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'profile_store.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  static const _sessionMobileKey = 'customer_session_mobile';
  static const _sessionTokenKey = 'customer_session_token';

  SupabaseClient get _db => Supabase.instance.client;

  Future<String?> currentMobile() async {
    final preferences = await SharedPreferences.getInstance();
    final mobile = preferences.getString(_sessionMobileKey) ?? '';
    return mobile.length == 10 ? mobile : null;
  }

  Future<String?> currentToken() async {
    final preferences = await SharedPreferences.getInstance();
    final token = preferences.getString(_sessionTokenKey) ?? '';
    return token.length >= 32 ? token : null;
  }

  Future<void> register({
    required String name,
    required String mobile,
    required String password,
  }) async {
    final result = await _db.rpc('register_customer_account', params: {
      'p_name': name.trim(),
      'p_mobile': mobile.trim(),
      'p_password': password,
    });
    final profile = Map<String, dynamic>.from(result as Map);
    await _startSession(profile, fallbackName: name.trim());
  }

  Future<void> login({
    required String mobile,
    required String password,
  }) async {
    final result = await _db.rpc('login_customer_account', params: {
      'p_mobile': mobile.trim(),
      'p_password': password,
    });
    await _startSession(Map<String, dynamic>.from(result as Map));
  }

  Future<void> _startSession(
    Map<String, dynamic> data, {
    String fallbackName = '',
  }) async {
    final mobile = '${data['mobile'] ?? ''}';
    if (mobile.length != 10) throw const FormatException('Invalid account');
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_sessionMobileKey, mobile);
    final token = '${data['session_token'] ?? ''}';
    if (token.length >= 32) {
      await preferences.setString(_sessionTokenKey, token);
    }
    await ProfileStore.instance.save(CustomerProfile(
      name: '${data['name'] ?? fallbackName}',
      mobile: mobile,
      village: '${data['village'] ?? ''}',
      address: '${data['address'] ?? ''}',
      avatarUrl: '${data['avatar_url'] ?? ''}',
    ));
  }

  Future<void> logout() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_sessionMobileKey);
    await preferences.remove(_sessionTokenKey);
  }
}
