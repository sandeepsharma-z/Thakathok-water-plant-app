import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_service.dart';
import 'customer_api_service.dart';

class WalletOrder {
  const WalletOrder({
    required this.keyId,
    required this.orderId,
    required this.amountPaise,
    required this.plantName,
    required this.customerName,
  });

  final String keyId;
  final String orderId;
  final int amountPaise;
  final String plantName;
  final String customerName;
}

class WalletService {
  WalletService._();
  static final WalletService instance = WalletService._();

  SupabaseClient get _db => Supabase.instance.client;

  Future<WalletOrder> createTopUpOrder({
    required String mobile,
    required int amount,
  }) async {
    final token = await AuthService.instance.currentToken() ?? '';
    final response = await _invokeWalletPayment(
      {
        'action': 'create',
        'mobile': mobile,
        'session_token': token,
        'amount': amount,
      },
    );
    final data = Map<String, dynamic>.from(response.data as Map);
    if (data['error'] != null) throw Exception(data['error']);
    return WalletOrder(
      keyId: '${data['key_id'] ?? ''}',
      orderId: '${data['order_id'] ?? ''}',
      amountPaise: (data['amount_paise'] as num).toInt(),
      plantName: '${data['plant_name'] ?? 'ThakaThok'}',
      customerName: '${data['customer_name'] ?? ''}',
    );
  }

  Future<int> verifyAndCredit({
    required String mobile,
    required String orderId,
    required String paymentId,
    required String signature,
  }) async {
    final token = await AuthService.instance.currentToken() ?? '';
    final response = await _invokeWalletPayment(
      {
        'action': 'verify',
        'mobile': mobile,
        'session_token': token,
        'order_id': orderId,
        'payment_id': paymentId,
        'signature': signature,
      },
    );
    final data = Map<String, dynamic>.from(response.data as Map);
    if (data['error'] != null || data['success'] != true) {
      throw Exception(data['error'] ?? 'Payment verification failed.');
    }
    return (data['balance'] as num).toInt();
  }

  Future<FunctionResponse> _invokeWalletPayment(
    Map<String, dynamic> body,
  ) async {
    try {
      return await _db.functions.invoke('wallet-payment', body: body);
    } on FunctionException catch (error) {
      final details = error.details;
      if (details is Map && details['error'] != null) {
        throw Exception('${details['error']}');
      }
      throw Exception('Payment service is unavailable. Please try again.');
    }
  }

  Future<int> balance(String mobile) async {
    final result = await CustomerApiService.instance.call('wallet');
    return (result['balance'] as num?)?.toInt() ?? 0;
  }

  Future<List<Map<String, dynamic>>> transactions(String mobile) async {
    final result = await CustomerApiService.instance.call('wallet');
    return List<Map<String, dynamic>>.from(result['transactions'] as List);
  }
}
