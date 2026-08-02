import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/order_details.dart';
import '../services/auth_service.dart';
import '../services/app_config_service.dart';
import '../services/booking_service.dart';
import '../services/language_service.dart';
import '../services/plant_config.dart';
import '../services/profile_store.dart';
import '../theme/app_colors.dart';
import '../widgets/brand_logo.dart';
import 'payment_screen.dart';

/// Per-can rate — admin-controlled, loaded live from settings at app start.
int get kPerCanRate => PlantConfig.instance.perCanRate;

/// Delivery charge applied to orders under the free threshold (except the free
/// village). Admin-controlled, loaded live from settings.
int get kDeliveryFreeThreshold => PlantConfig.instance.deliveryFreeThreshold;
String get kFreeDeliveryVillage => PlantConfig.instance.freeDeliveryVillage;

List<String> get kEventTypes => AppConfigService.instance.eventTypes;

List<String> get kCanOptions => [
      ...AppConfigService.instance.quantityOptions.map((item) => '$item'),
      'Custom',
    ];

List<String> get kVillages => PlantConfig.instance.villages;

/// Screen 2 of the bulk-order flow — the enquiry form the customer fills in
/// before paying the 30% advance.
class BulkOrderFormScreen extends StatefulWidget {
  const BulkOrderFormScreen({
    super.key,
    this.initialCans,
    this.startWithCustomQuantity = false,
    this.initialEventType,
  });

  final int? initialCans;
  final bool startWithCustomQuantity;
  final String? initialEventType;

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

  // Name is pulled silently from the saved on-device profile (no form field).
  String _profileName = '';

  @override
  void initState() {
    super.initState();
    LanguageService.instance.addListener(_onLanguageChanged);
    if (widget.initialEventType != null &&
        kEventTypes.contains(widget.initialEventType)) {
      _eventType = widget.initialEventType;
    }
    if (widget.startWithCustomQuantity) {
      _cansChoice = 'Custom';
    } else if (widget.initialCans != null) {
      final value = widget.initialCans.toString();
      if (kCanOptions.contains(value)) {
        _cansChoice = value;
      } else {
        _cansChoice = 'Custom';
        _customCansController.text = value;
      }
    }
    _prefillFromProfile();
  }

  Future<void> _prefillFromProfile() async {
    final results = await Future.wait([
      ProfileStore.instance.load(),
      AuthService.instance.currentMobile(),
    ]);
    final p = results[0] as CustomerProfile;
    final accountMobile = results[1] as String?;
    if (!mounted) return;
    setState(() {
      _profileName = p.name;
      _mobileController.text = accountMobile ?? p.mobile;
      if (_addressController.text.isEmpty) _addressController.text = p.address;
      if (p.village.isNotEmpty && kVillages.contains(p.village)) {
        _village = p.village;
      }
    });
  }

  @override
  void dispose() {
    LanguageService.instance.removeListener(_onLanguageChanged);
    _customCansController.dispose();
    _mobileController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _onLanguageChanged() {
    if (mounted) setState(() {});
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

  int get _deliveryCharge => _hasDeliveryCharge
      ? PlantConfig.instance.deliveryChargeForVillage(_village!)
      : 0;

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final lastDate = now.add(const Duration(days: 365));
    Set<String> unavailable = const {};
    try {
      unavailable = await BookingService.instance.unavailableDates(
        from: now,
        to: lastDate,
      );
    } catch (_) {
      // Server-side enforcement still protects the booking if loading fails.
    }
    if (!mounted) return;
    String dateKey(DateTime date) => '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
    var initialDate = _eventDate ?? DateTime(now.year, now.month, now.day);
    while (unavailable.contains(dateKey(initialDate)) &&
        initialDate.isBefore(lastDate)) {
      initialDate = initialDate.add(const Duration(days: 1));
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: now,
      lastDate: lastDate,
      selectableDayPredicate: (date) => !unavailable.contains(dateKey(date)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(primary: AppColors.liveBrand),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _eventDate = picked);
  }

  Future<void> _pickTime() async {
    await PlantConfig.instance.load();
    if (!mounted) return;
    final now = DateTime.now();
    final earliest =
        now.add(Duration(minutes: PlantConfig.instance.minimumNoticeMinutes));
    final selectedToday = _eventDate != null &&
        _eventDate!.year == now.year &&
        _eventDate!.month == now.month &&
        _eventDate!.day == now.day;
    final slots = List.generate(48, (index) {
      final minutes = index * 30;
      return TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60);
    }).where((slot) {
      if (!selectedToday) return true;
      final value =
          DateTime(now.year, now.month, now.day, slot.hour, slot.minute);
      return !value.isBefore(earliest);
    }).toList();
    if (slots.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(tr(
              'No delivery slots remain today. Please choose another date.'))));
      return;
    }
    final picked = await showModalBottomSheet<TimeOfDay>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(sheetContext).height * .72,
          child: Column(children: [
            Text(tr('Select Required Delivery Time'),
                style: Theme.of(sheetContext).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700, color: AppColors.liveBrand)),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
              child: Text(
                selectedToday
                    ? tr('Only slots after the minimum notice are shown.')
                    : tr('Time means the required delivery time.'),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: AppColors.body),
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 22),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 2.4,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8),
                itemCount: slots.length,
                itemBuilder: (_, index) {
                  final slot = slots[index];
                  return OutlinedButton(
                    onPressed: () => Navigator.pop(sheetContext, slot),
                    child: Text(slot.format(sheetContext)),
                  );
                },
              ),
            ),
          ]),
        ),
      ),
    );
    if (picked != null) {
      if (selectedToday) {
        final requested =
            DateTime(now.year, now.month, now.day, picked.hour, picked.minute);
        if (requested.isBefore(earliest)) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(tr(
                'Choose a later delivery time that meets the minimum notice.')),
          ));
          return;
        }
      }
      setState(() => _eventTime = picked);
    }
  }

  Future<void> _submit() async {
    await PlantConfig.instance.load();
    if (!mounted) return;
    if (_village == null || !kVillages.contains(_village)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(tr('This delivery village is no longer available.'))),
      );
      return;
    }
    final valid = _formKey.currentState?.validate() ?? false;
    if (_eventDate == null || _eventTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppConfigService.instance.label('date_required_error'),
          ),
        ),
      );
      return;
    }
    if (!valid) return;

    try {
      final availability =
          await BookingService.instance.bookingAvailability(_eventDate!, _cans);
      if (availability.fullyBooked || !availability.canBook) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(availability.fullyBooked
                ? tr('This date is fully booked. Please choose another date.')
                : tr('Only {count} cans are available on this date.')
                    .replaceAll('{count}', '${availability.remaining}')),
          ),
        );
        return;
      }
      final now = DateTime.now();
      final requested = DateTime(_eventDate!.year, _eventDate!.month,
          _eventDate!.day, _eventTime!.hour, _eventTime!.minute);
      final earliest =
          now.add(Duration(minutes: availability.minimumNoticeMinutes));
      if (requested.isBefore(earliest)) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(tr(
              'Choose a later delivery time that meets the minimum notice.')),
        ));
        return;
      }
    } catch (_) {
      // Final database/checkout validation remains authoritative.
    }

    final eligibility = await BookingService.instance.customerOrderEligibility(
      _mobileController.text.trim(),
    );
    if (!mounted) return;
    if (!eligibility.eligible) {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          icon: Icon(Icons.lock_outline_rounded,
              color: AppColors.liveBrand, size: 34),
          title: Text(tr('New order unavailable')),
          content: Text(tr(eligibility.reason)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(tr('OK')),
            ),
          ],
        ),
      );
      return;
    }

    final order = OrderDetails(
      name: _profileName,
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
          icon: Icon(Icons.arrow_back, color: AppColors.liveBrand),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        centerTitle: true,
        title: const BrandLogo(size: 38),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.fromLTRB(18, 4, 18, 28),
          children: [
            Text(
              AppConfigService.instance.label('booking_form_title'),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.liveBrand,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              tr('Fill in your event details to request a bulk water order.'),
              style: const TextStyle(fontSize: 12.5, color: AppColors.body),
            ),
            const SizedBox(height: 22),

            // 1. Event Type
            _FieldLabel(tr('Event Type')),
            _Dropdown(
              hint: tr('Select event type'),
              value: _eventType,
              items: kEventTypes,
              onChanged: (v) => setState(() => _eventType = v),
            ),
            const SizedBox(height: 18),

            // 2. Number of Cans
            _FieldLabel(tr('Number of Cans')),
            _Dropdown(
              hint: tr('Select number of cans'),
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
                decoration: _inputDecoration(tr('Enter number of cans')),
                validator: (v) {
                  if (_cansChoice != 'Custom') return null;
                  final n = int.tryParse((v ?? '').trim()) ?? 0;
                  if (n <= 0) return tr('Enter a valid number of cans');
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
                      _FieldLabel(tr('Per Can Rate')),
                      _ReadOnlyBox('₹ $kPerCanRate / Can'),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _FieldLabel(tr('Total Amount')),
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
            _FieldLabel(tr('Event Date & Time')),
            Row(
              children: [
                Expanded(
                  child: _PickerBox(
                    icon: Icons.calendar_month_rounded,
                    text: _eventDate == null
                        ? tr('Select date')
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
                        ? tr('Select time')
                        : _eventTime!.format(context),
                    filled: _eventTime != null,
                    onTap: _pickTime,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // 6. Mobile Number
            _FieldLabel(tr('Mobile Number')),
            TextFormField(
              controller: _mobileController,
              readOnly: true,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              decoration: _inputDecoration('XXXXX XXXXX').copyWith(
                suffixIcon: const Icon(Icons.lock_outline_rounded, size: 18),
                prefixText: '+91  ',
                prefixStyle: const TextStyle(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              validator: (v) {
                final s = (v ?? '').trim();
                if (s.length != 10) return tr('Enter a valid 10-digit number');
                return null;
              },
            ),
            const SizedBox(height: 18),

            // 7. Village / Area
            _FieldLabel(tr('Village / Area')),
            _Dropdown(
              hint: tr('Select your village'),
              value: _village,
              items: kVillages,
              onChanged: (v) => setState(() => _village = v),
            ),
            const SizedBox(height: 18),

            // 8. Address / Hall Name
            _FieldLabel(tr('Address / Hall Name')),
            TextFormField(
              controller: _addressController,
              maxLines: 3,
              textInputAction: TextInputAction.done,
              decoration: _inputDecoration(tr('Enter address or hall name')),
              validator: (v) {
                if ((v ?? '').trim().isEmpty) {
                  return tr('Please enter an address or hall name');
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
                  children: [
                    const Icon(Icons.local_shipping_outlined,
                        size: 18, color: Color(0xFFB26A00)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Orders under $kDeliveryFreeThreshold cans have a '
                        'delivery charge (₹$_deliveryCharge) for this village.',
                        style: const TextStyle(
                            fontSize: 11.5, color: Color(0xFF8A5200)),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            SizedBox(height: 28),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.liveBrand,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  AppConfigService.instance.label('request_order_button'),
                  style: const TextStyle(
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
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
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
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: AppColors.hairline),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: AppColors.liveBrand, width: 1.4),
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
      initialValue: value,
      isExpanded: true,
      icon: Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.liveBrand),
      decoration: _inputDecoration(hint),
      hint: Text(hint,
          style: const TextStyle(color: AppColors.hint, fontSize: 13.5)),
      items: items
          .map((e) => DropdownMenuItem(value: e, child: Text(tr(e))))
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
        color: highlight ? AppColors.offerBg : Color(0xFFF0F0F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: highlight
              ? AppColors.liveBrand.withValues(alpha: 0.25)
              : AppColors.hairline,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14.5,
          fontWeight: FontWeight.w700,
          color: highlight ? AppColors.liveBrand : AppColors.body,
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
          color: Color(0xFFF7FAFF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.hairline),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.liveBrand),
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
