import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/booking_service.dart';
import '../../theme/app_colors.dart';

/// Admin-controlled pricing: per-can rate and the delivery charge applied to
/// orders under the free-delivery threshold.
class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _rate = TextEditingController();
  final _delivery = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  AppSettings? _settings;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _rate.dispose();
    _delivery.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final s = await BookingService.instance.fetchSettings();
    if (!mounted) return;
    setState(() {
      _settings = s;
      _loading = false;
      if (s == null) {
        _error = 'Could not load settings. Make sure the database tables '
            'have been created.';
      } else {
        _rate.text = '${s.perCanRate}';
        _delivery.text = '${s.deliveryCharge}';
      }
    });
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      await BookingService.instance.updateSettings(
        perCanRate: int.parse(_rate.text.trim()),
        deliveryCharge: int.parse(_delivery.text.trim()),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rates updated')),
      );
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save. Are you signed in?')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _settings;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.brand),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'Rates & Charges',
          style: TextStyle(
            color: AppColors.brand,
            fontWeight: FontWeight.w700,
            fontSize: 19,
          ),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.brand))
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 28),
                children: [
                  if (_error != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDECEC),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _error!,
                        style: const TextStyle(
                          color: Color(0xFFD32020),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],
                  const _Label('Per Can Rate (₹)'),
                  TextFormField(
                    controller: _rate,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: _dec('e.g. 45'),
                    validator: _positive,
                  ),
                  const SizedBox(height: 6),
                  const _Hint(
                      'Customers see this rate on the enquiry form but cannot '
                      'edit it. Update it per season or village.'),
                  const SizedBox(height: 22),
                  const _Label('Delivery Charge (₹)'),
                  TextFormField(
                    controller: _delivery,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: _dec('e.g. 200'),
                    validator: (v) {
                      final n = int.tryParse((v ?? '').trim());
                      if (n == null || n < 0) return 'Enter 0 or more';
                      return null;
                    },
                  ),
                  const SizedBox(height: 6),
                  _Hint(
                    'Charged only on orders under '
                    '${s?.deliveryFreeThreshold ?? 25} cans. '
                    '${s?.freeDeliveryVillage ?? 'Kasara Balkunda'} is always '
                    'free — set 0 to remove the charge everywhere.',
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: (_saving || s == null) ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brand,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _saving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'SAVE',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  static String? _positive(String? v) {
    final n = int.tryParse((v ?? '').trim());
    if (n == null || n <= 0) return 'Enter a valid amount';
    return null;
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 7),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
      );
}

class _Hint extends StatelessWidget {
  const _Hint(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(fontSize: 11.5, color: AppColors.hint),
      );
}

InputDecoration _dec(String hint) => InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.hint, fontSize: 13.5),
      prefixText: '₹  ',
      prefixStyle: const TextStyle(
        color: AppColors.textDark,
        fontWeight: FontWeight.w700,
        fontSize: 14,
      ),
      filled: true,
      fillColor: const Color(0xFFF7FAFF),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.hairline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.brand, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE23D3D)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE23D3D), width: 1.4),
      ),
    );
