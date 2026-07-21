import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/order_details.dart';
import '../theme/app_colors.dart';
import '../widgets/brand_logo.dart';
import 'payment_screen.dart';

/// Per-can rate. Admin-controlled in the real app; hard-coded for now.
const int kPerCanRate = 45;

/// Delivery charge applied to orders under 25 cans (except Kasara Balkunda).
/// Admin-controlled later; hard-coded for now.
const int kDeliveryCharge = 200;
const int kDeliveryFreeThreshold = 25;
const String kFreeDeliveryVillage = 'Kasara Balkunda';

const List<String> kEventTypes = ['Wedding', 'Birthday', 'Other'];

const List<String> kCanOptions = ['20', '50', '100', '150', 'Custom'];

const List<String> kVillages = [
  'Kasara Balkunda',
  'Sardarwadi',
  'Tambala',
  'Chilwantwadi',
  'Pirupatelvadi',
  'Devi Hallali',
  'Mamdapur',
];

/// Screen 2 of the bulk-order flow — the enquiry form the customer fills in
/// before paying the 30% advance.
class BulkOrderFormScreen extends StatefulWidget {
  const BulkOrderFormScreen({super.key});

  @override
  State<BulkOrderFormScreen> createState() => _BulkOrderFormScreenState();
}

class _BulkOrderFormScreenState extends State<BulkOrderFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _customCansController = TextEditingController();
  final _mobileController = TextEditingController();
  final _addressController = TextEditingController();

  String? _eventType;
  String? _cansChoice;
  String? _village;
  DateTime? _eventDate;
  TimeOfDay? _eventTime;

  @override
  void dispose() {
    _customCansController.dispose();
    _mobileController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  /// Resolved can count from the dropdown / custom field (0 if not valid yet).
  int get _cans {
    if (_cansChoice == null) return 0;
    if (_cansChoice == 'Custom') {
      return int.tryParse(_customCansController.text.trim()) ?? 0;
    }
    return int.tryParse(_cansChoice!) ?? 0;
  }

  int get _total => _cans * kPerCanRate;

  bool get _hasDeliveryCharge =>
      _cans > 0 &&
      _cans < kDeliveryFreeThreshold &&
      _village != null &&
      _village != kFreeDeliveryVillage;

  int get _deliveryCharge => _hasDeliveryCharge ? kDeliveryCharge : 0;

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _eventDate ?? now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.brand),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _eventDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _eventTime ?? const TimeOfDay(hour: 10, minute: 0),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.brand),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _eventTime = picked);
  }

  void _submit() {
    final valid = _formKey.currentState?.validate() ?? false;
    if (_eventDate == null || _eventTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select event date & time')),
      );
      return;
    }
    if (!valid) return;

    final order = OrderDetails(
      eventType: _eventType!,
      cans: _cans,
      perCanRate: kPerCanRate,
      village: _village!,
      mobile: _mobileController.text.trim(),
      address: _addressController.text.trim(),
      eventDate: _eventDate!,
      eventTime: _eventTime!,
      deliveryCharge: _deliveryCharge,
    );

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PaymentScreen(order: order)),
    );
  }

  @override
  Widget build(BuildContext context) {
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
        centerTitle: true,
        title: const BrandLogo(size: 38),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 28),
          children: [
            const Text(
              'Bulk Order Enquiry',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.brand,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Fill in your event details to request a bulk water order.',
              style: TextStyle(fontSize: 12.5, color: AppColors.body),
            ),
            const SizedBox(height: 22),

            // 1. Event Type
            _FieldLabel('Event Type'),
            _Dropdown(
              hint: 'Select event type',
              value: _eventType,
              items: kEventTypes,
              onChanged: (v) => setState(() => _eventType = v),
            ),
            const SizedBox(height: 18),

            // 2. Number of Cans
            _FieldLabel('Number of Cans'),
            _Dropdown(
              hint: 'Select number of cans',
              value: _cansChoice,
              items: kCanOptions,
              onChanged: (v) => setState(() => _cansChoice = v),
            ),
            if (_cansChoice == 'Custom') ...[
              const SizedBox(height: 10),
              TextFormField(
                controller: _customCansController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (_) => setState(() {}),
                decoration: _inputDecoration('Enter number of cans'),
                validator: (v) {
                  if (_cansChoice != 'Custom') return null;
                  final n = int.tryParse((v ?? '').trim()) ?? 0;
                  if (n <= 0) return 'Enter a valid number of cans';
                  return null;
                },
              ),
            ],
            const SizedBox(height: 18),

            // 3 & 4. Per Can Rate (read-only) + Total (auto)
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _FieldLabel('Per Can Rate'),
                      _ReadOnlyBox('₹ $kPerCanRate / Can'),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _FieldLabel('Total Amount'),
                      _ReadOnlyBox(
                        _cans > 0 ? '₹ $_total' : '₹ 0',
                        highlight: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // 5. Event Date + Time
            _FieldLabel('Event Date & Time'),
            Row(
              children: [
                Expanded(
                  child: _PickerBox(
                    icon: Icons.calendar_month_rounded,
                    text: _eventDate == null
                        ? 'Select date'
                        : _formatDate(_eventDate!),
                    filled: _eventDate != null,
                    onTap: _pickDate,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _PickerBox(
                    icon: Icons.access_time_rounded,
                    text: _eventTime == null
                        ? 'Select time'
                        : _eventTime!.format(context),
                    filled: _eventTime != null,
                    onTap: _pickTime,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // 6. Mobile Number
            _FieldLabel('Mobile Number'),
            TextFormField(
              controller: _mobileController,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              decoration: _inputDecoration('XXXXX XXXXX').copyWith(
                prefixText: '+91  ',
                prefixStyle: const TextStyle(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              validator: (v) {
                final s = (v ?? '').trim();
                if (s.length != 10) return 'Enter a valid 10-digit number';
                return null;
              },
            ),
            const SizedBox(height: 18),

            // 7. Village / Area
            _FieldLabel('Village / Area'),
            _Dropdown(
              hint: 'Select your village',
              value: _village,
              items: kVillages,
              onChanged: (v) => setState(() => _village = v),
            ),
            const SizedBox(height: 18),

            // 8. Address / Hall Name
            _FieldLabel('Address / Hall Name'),
            TextFormField(
              controller: _addressController,
              maxLines: 3,
              textInputAction: TextInputAction.done,
              decoration: _inputDecoration('Enter address or hall name'),
              validator: (v) {
                if ((v ?? '').trim().isEmpty) {
                  return 'Please enter an address or hall name';
                }
                return null;
              },
            ),

            if (_hasDeliveryCharge) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF4E5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFFD9A0)),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.local_shipping_outlined,
                        size: 18, color: Color(0xFFB26A00)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Orders under 25 cans have a delivery charge '
                        '(₹$kDeliveryCharge) for this village.',
                        style: TextStyle(
                            fontSize: 11.5, color: Color(0xFF8A5200)),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 28),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brand,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'REQUEST BULK ORDER',
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

  static String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }
}

// ── Shared field styling ──────────────────────────────────────────────
InputDecoration _inputDecoration(String hint) {
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: AppColors.hint, fontSize: 13.5),
    filled: true,
    fillColor: const Color(0xFFF7FAFF),
    contentPadding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
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
}

class _Dropdown extends StatelessWidget {
  const _Dropdown({
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String hint;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      icon: const Icon(Icons.keyboard_arrow_down_rounded,
          color: AppColors.brand),
      decoration: _inputDecoration(hint),
      hint: Text(hint,
          style: const TextStyle(color: AppColors.hint, fontSize: 13.5)),
      items: items
          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
          .toList(),
      onChanged: onChanged,
      validator: (v) => v == null ? 'Please select an option' : null,
    );
  }
}

class _ReadOnlyBox extends StatelessWidget {
  const _ReadOnlyBox(this.text, {this.highlight = false});
  final String text;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      width: double.infinity,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: highlight ? AppColors.offerBg : const Color(0xFFF0F0F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: highlight ? AppColors.brand.withValues(alpha: 0.25)
                            : AppColors.hairline,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14.5,
          fontWeight: FontWeight.w700,
          color: highlight ? AppColors.brand : AppColors.body,
        ),
      ),
    );
  }
}

class _PickerBox extends StatelessWidget {
  const _PickerBox({
    required this.icon,
    required this.text,
    required this.filled,
    required this.onTap,
  });

  final IconData icon;
  final String text;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF7FAFF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.hairline),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.brand),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: filled ? AppColors.textDark : AppColors.hint,
                  fontWeight: filled ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
