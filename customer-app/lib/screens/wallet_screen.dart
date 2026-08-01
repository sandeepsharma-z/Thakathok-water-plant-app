import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../services/auth_service.dart';
import '../services/wallet_service.dart';
import '../services/app_config_service.dart';
import '../services/language_service.dart';
import '../theme/app_colors.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key, this.mobile = ''});

  final String mobile;

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final _amount = TextEditingController();
  late final Razorpay _razorpay;
  String _mobile = '';
  String? _pendingOrderId;
  int _balance = 0;
  bool _loading = true;
  bool _creatingOrder = false;
  bool _verifying = false;
  String? _error;
  List<Map<String, dynamic>> _transactions = const [];

  @override
  void initState() {
    super.initState();
    LanguageService.instance.addListener(_onLanguageChanged);
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _onPaymentError);
    _load();
  }

  @override
  void dispose() {
    LanguageService.instance.removeListener(_onLanguageChanged);
    _razorpay.clear();
    _amount.dispose();
    super.dispose();
  }

  void _onLanguageChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _load() async {
    final mobile = widget.mobile.length == 10
        ? widget.mobile
        : await AuthService.instance.currentMobile() ?? '';
    if (mobile.length != 10) {
      if (mounted) {
        setState(() {
          _error = 'Please login again to use your wallet.';
          _loading = false;
        });
      }
      return;
    }
    try {
      final results = await Future.wait([
        WalletService.instance.balance(mobile),
        WalletService.instance.transactions(mobile),
      ]);
      if (!mounted) return;
      setState(() {
        _mobile = mobile;
        _balance = results[0] as int;
        _transactions = results[1] as List<Map<String, dynamic>>;
        _error = null;
      });
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not load wallet.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _addMoney() async {
    final amount = int.tryParse(_amount.text.trim());
    if (amount == null || amount < 10 || amount > 100000) {
      setState(() => _error = 'Enter an amount between ₹10 and ₹1,00,000.');
      return;
    }
    setState(() {
      _creatingOrder = true;
      _error = null;
    });
    try {
      final order = await WalletService.instance.createTopUpOrder(
        mobile: _mobile,
        amount: amount,
      );
      _pendingOrderId = order.orderId;
      _razorpay.open({
        'key': order.keyId,
        'order_id': order.orderId,
        'amount': order.amountPaise,
        'currency': 'INR',
        'name': order.plantName,
        'description': '${AppConfigService.instance.brandName} wallet top-up',
        'prefill': {
          'contact': _mobile,
          'name': order.customerName,
        },
        'theme': {'color': '#004FDA'},
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _pendingOrderId = null;
          _error = _message(error);
        });
      }
    } finally {
      if (mounted) setState(() => _creatingOrder = false);
    }
  }

  Future<void> _onPaymentSuccess(PaymentSuccessResponse response) async {
    final orderId = _pendingOrderId ?? response.orderId ?? '';
    final paymentId = response.paymentId ?? '';
    final signature = response.signature ?? '';
    if (orderId.isEmpty || paymentId.isEmpty || signature.isEmpty) {
      setState(() => _error = 'Incomplete payment response. Contact support.');
      return;
    }
    setState(() {
      _verifying = true;
      _error = null;
    });
    try {
      final balance = await WalletService.instance.verifyAndCredit(
        mobile: _mobile,
        orderId: orderId,
        paymentId: paymentId,
        signature: signature,
      );
      if (!mounted) return;
      _amount.clear();
      setState(() {
        _balance = balance;
        _pendingOrderId = null;
      });
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('Money added to wallet successfully.'))),
      );
    } catch (error) {
      if (mounted) {
        setState(() {
          _pendingOrderId = null;
          _error = _message(error);
        });
      }
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  void _onPaymentError(PaymentFailureResponse response) {
    setState(() {
      _pendingOrderId = null;
      _error = response.code == Razorpay.PAYMENT_CANCELLED
          ? 'Payment cancelled.'
          : 'Payment failed. No money was added.';
    });
  }

  String _message(Object error) {
    final message = error.toString().replaceFirst('Exception: ', '');
    return message.isEmpty ? 'Something went wrong. Try again.' : message;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: Icon(Icons.arrow_back_rounded, color: AppColors.liveBrand),
        ),
        title: Text(
          AppConfigService.instance.label('screen_wallet'),
          style: const TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: _loading
          ? Center(
              child: CircularProgressIndicator(color: AppColors.liveBrand),
            )
          : RefreshIndicator(
              onRefresh: _load,
              color: AppColors.liveBrand,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 30),
                children: [
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: AppColors.liveBlueGradient,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr('Available Balance'),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          '₹$_balance.00',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.hairline),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr('Add Money'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _amount,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(6),
                          ],
                          decoration: InputDecoration(
                            prefixText: '₹ ',
                            hintText: tr('Enter amount'),
                            filled: true,
                            fillColor: const Color(0xFFF5F9FF),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: AppColors.hairline),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          children: [100, 500, 1000, 2000]
                              .map(
                                (value) => ActionChip(
                                  label: Text('₹$value'),
                                  onPressed: () =>
                                      _amount.text = value.toString(),
                                ),
                              )
                              .toList(),
                        ),
                        SizedBox(height: 14),
                        SizedBox(
                          height: 50,
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed:
                                _creatingOrder || _verifying ? null : _addMoney,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.liveBrand,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _creatingOrder || _verifying
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    tr('ADD MONEY SECURELY'),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w800),
                                  ),
                          ),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 10),
                          Text(
                            _error!,
                            style: const TextStyle(
                              color: Color(0xFFD32020),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    tr('Transaction History'),
                    style: const TextStyle(
                      color: AppColors.textDark,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (_transactions.isEmpty)
                    const _EmptyTransactions()
                  else
                    for (final transaction in _transactions)
                      _TransactionTile(transaction),
                ],
              ),
            ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile(this.transaction);

  final Map<String, dynamic> transaction;

  @override
  Widget build(BuildContext context) {
    final credit = transaction['type'] == 'credit';
    final created =
        DateTime.tryParse('${transaction['created_at'] ?? ''}')?.toLocal();
    final date = created == null
        ? ''
        : '${created.day.toString().padLeft(2, '0')}/'
            '${created.month.toString().padLeft(2, '0')}/${created.year}';
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor:
                credit ? const Color(0xFFE7F7EF) : const Color(0xFFFDECEC),
            child: Icon(
              credit ? Icons.south_west_rounded : Icons.north_east_rounded,
              color: credit ? const Color(0xFF169B62) : const Color(0xFFD32020),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr('${transaction['description'] ?? 'Wallet transaction'}'),
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  date,
                  style: const TextStyle(color: AppColors.body, fontSize: 11),
                ),
              ],
            ),
          ),
          Text(
            '${credit ? '+' : '-'}₹${transaction['amount']}',
            style: TextStyle(
              color: credit ? const Color(0xFF169B62) : const Color(0xFFD32020),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyTransactions extends StatelessWidget {
  const _EmptyTransactions();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Text(
        tr('No wallet transactions yet'),
        style: const TextStyle(color: AppColors.body, fontSize: 13),
      ),
    );
  }
}
