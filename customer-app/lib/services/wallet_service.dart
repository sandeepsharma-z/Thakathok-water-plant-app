import 'package:supabase_flutter/supabase_flutter.dart';

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
    final response = await _invokeWalletPayment(
      {'action': 'create', 'mobile': mobile, 'amount': amount},
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
    final response = await _invokeWalletPayment(
      {
        'action': 'verify',
        'mobile': mobile,
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
    final row = await _db
        .from('customers')
        .select('wallet_balance')
        .eq('mobile', mobile)
        .single();
    return (row['wallet_balance'] as num?)?.toInt() ?? 0;
  }

  Future<List<Map<String, dynamic>>> transactions(String mobile) async {
    final rows = await _db
        .from('wallet_transactions')
        .select()
        .eq('mobile', mobile)
        .order('created_at', ascending: false)
        .limit(50);
    return List<Map<String, dynamic>>.from(rows);
  }
}
