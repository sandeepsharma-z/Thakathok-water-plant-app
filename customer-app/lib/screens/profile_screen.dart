import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import 'bulk_order_form_screen.dart' show kVillages;

/// Customer profile. Editable on screen; saving to the backend arrives with
/// customer accounts (phone-OTP auth).
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController(text: 'Rupali');
  final _mobile = TextEditingController(text: '9876543210');
  final _address = TextEditingController(text: 'Shubham Lawns, Main Road');
  String _village = kVillages.first;
  bool _editing = false;

  @override
  void dispose() {
    _name.dispose();
    _mobile.dispose();
    _address.dispose();
    super.dispose();
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _editing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Saved on this device — syncing needs an account.'),
      ),
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
        title: const Text('My Profile',
            style: TextStyle(
                color: AppColors.brand,
                fontWeight: FontWeight.w700,
                fontSize: 19)),
        actions: [
          if (!_editing)
            TextButton.icon(
              onPressed: () => setState(() => _editing = true),
              icon: const Icon(Icons.edit_outlined, size: 17),
              label: const Text('Edit'),
              style: TextButton.styleFrom(foregroundColor: AppColors.brand),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 6, 18, 28),
          children: [
            // Avatar
            Center(
              child: Column(
                children: [
                  Container(
                    height: 88,
                    width: 88,
                    decoration: BoxDecoration(
                      color: AppColors.tint,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: AppColors.brand.withValues(alpha: 0.25),
                          width: 2),
                    ),
                    child: const Icon(Icons.person_rounded,
                        size: 48, color: AppColors.brand),
                  ),
                  const SizedBox(height: 10),
                  Text(_name.text,
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark)),
                  Text('+91 ${_mobile.text}',
                      style: const TextStyle(
                          fontSize: 12.5, color: AppColors.body)),
                ],
              ),
            ),
            const SizedBox(height: 26),

            const _Label('Full Name'),
            TextFormField(
              controller: _name,
              enabled: _editing,
              decoration: _dec('Your name'),
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? 'Enter your name' : null,
            ),
            const SizedBox(height: 18),

            const _Label('Mobile Number'),
            TextFormField(
              controller: _mobile,
              enabled: _editing,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              decoration: _dec('XXXXX XXXXX').copyWith(
                prefixText: '+91  ',
                prefixStyle: const TextStyle(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w600,
                    fontSize: 14),
              ),
              validator: (v) =>
                  (v ?? '').trim().length != 10 ? 'Enter 10 digits' : null,
            ),
            const SizedBox(height: 18),

            const _Label('Village / Area'),
            DropdownButtonFormField<String>(
              value: _village,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded,
                  color: AppColors.brand),
              decoration: _dec('Select your village'),
              items: kVillages
                  .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                  .toList(),
              onChanged:
                  _editing ? (v) => setState(() => _village = v!) : null,
            ),
            const SizedBox(height: 18),

            const _Label('Address / Hall Name'),
            TextFormField(
              controller: _address,
              enabled: _editing,
              maxLines: 3,
              decoration: _dec('Your address'),
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? 'Enter an address' : null,
            ),

            if (_editing) ...[
              const SizedBox(height: 28),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brand,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('SAVE CHANGES',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 7),
        child: Text(text,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark)),
      );
}

InputDecoration _dec(String hint) => InputDecoration(
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
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.hairline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.brand, width: 1.4),
      ),
    );
