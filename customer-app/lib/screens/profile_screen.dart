import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../services/booking_service.dart';
import '../services/profile_store.dart';
import '../theme/app_colors.dart';
import 'bulk_order_form_screen.dart' show kVillages;

/// Customer profile — saved on this device (no login needed). Starts empty
/// for a new user; they fill it once and it persists across app restarts.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _mobile = TextEditingController();
  final _address = TextEditingController();
  String _village = kVillages.first;
  bool _editing = false;
  bool _loaded = false;
  bool _uploadingAvatar = false;
  String _avatarUrl = '';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final p = await ProfileStore.instance.load();
    if (!mounted) return;
    setState(() {
      _name.text = p.name;
      _mobile.text = p.mobile;
      _address.text = p.address;
      _avatarUrl = p.avatarUrl;
      if (p.village.isNotEmpty && kVillages.contains(p.village)) {
        _village = p.village;
      }
      _loaded = true;
      // A brand-new user has nothing saved — drop them straight into editing.
      _editing = p.isEmpty;
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _mobile.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final name = _name.text.trim();
    final mobile = _mobile.text.trim();
    final address = _address.text.trim();
    // 1) Save on-device so it persists without a login.
    await ProfileStore.instance.save(CustomerProfile(
      name: name,
      mobile: mobile,
      village: _village,
      address: address,
      avatarUrl: _avatarUrl,
    ));
    // 2) Sync to Supabase so the admin sees this customer (best-effort).
    await BookingService.instance.upsertCustomer(
      mobile: mobile,
      name: name,
      village: _village,
      address: address,
      avatarUrl: _avatarUrl,
    );
    if (!mounted) return;
    setState(() => _editing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile saved.')),
    );
  }

  Future<void> _pickAvatar(ImageSource source) async {
    final mobile = _mobile.text.trim();
    if (mobile.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Save a valid mobile number first.')),
      );
      return;
    }
    final picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: 78,
      maxWidth: 1080,
      maxHeight: 1080,
    );
    if (picked == null || !mounted) return;
    setState(() => _uploadingAvatar = true);
    try {
      final bytes = await picked.readAsBytes();
      final extension =
          picked.name.contains('.') ? picked.name.split('.').last : 'jpg';
      final url = await BookingService.instance.uploadAvatar(
        mobile: mobile,
        bytes: bytes,
        extension: extension,
      );
      await BookingService.instance.updateCustomerAvatar(
        mobile: mobile,
        avatarUrl: url,
      );
      final current = await ProfileStore.instance.load();
      await ProfileStore.instance.save(CustomerProfile(
        name: _name.text.trim(),
        mobile: mobile,
        village: _village,
        address: _address.text.trim(),
        avatarUrl: url,
      ));
      await BookingService.instance.upsertCustomer(
        mobile: mobile,
        name: current.name.isEmpty ? _name.text.trim() : current.name,
        village: _village,
        address: _address.text.trim(),
        avatarUrl: url,
      );
      if (!mounted) return;
      setState(() => _avatarUrl = url);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile photo updated.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Could not upload photo. Current photo was kept.')),
      );
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  Future<void> _removeAvatar() async {
    final p = await ProfileStore.instance.load();
    await ProfileStore.instance.save(CustomerProfile(
      name: p.name,
      mobile: p.mobile,
      village: p.village,
      address: p.address,
    ));
    if (p.mobile.length == 10) {
      await BookingService.instance.updateCustomerAvatar(
        mobile: p.mobile,
        avatarUrl: '',
      );
      await BookingService.instance.upsertCustomer(
        mobile: p.mobile,
        name: p.name,
        village: p.village,
        address: p.address,
        avatarUrl: '',
      );
    }
    if (mounted) setState(() => _avatarUrl = '');
  }

  void _showAvatarOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickAvatar(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickAvatar(ImageSource.camera);
              },
            ),
            if (_avatarUrl.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Remove photo'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _removeAvatar();
                },
              ),
          ],
        ),
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
      body: !_loaded
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.brand))
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 6, 18, 28),
                children: [
                  // Avatar
                  Center(
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: _uploadingAvatar ? null : _showAvatarOptions,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                height: 88,
                                width: 88,
                                decoration: BoxDecoration(
                                  color: AppColors.tint,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: AppColors.brand
                                          .withValues(alpha: 0.25),
                                      width: 2),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: _uploadingAvatar
                                    ? const Padding(
                                        padding: EdgeInsets.all(28),
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: AppColors.brand),
                                      )
                                    : _avatarUrl.isEmpty
                                        ? const Icon(Icons.person_rounded,
                                            size: 48, color: AppColors.brand)
                                        : Image.network(
                                            _avatarUrl,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                const Icon(Icons.person_rounded,
                                                    size: 48,
                                                    color: AppColors.brand),
                                          ),
                              ),
                              Positioned(
                                right: -2,
                                bottom: -2,
                                child: Container(
                                  height: 28,
                                  width: 28,
                                  decoration: const BoxDecoration(
                                    color: AppColors.brand,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.camera_alt_rounded,
                                      size: 15, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                            _name.text.trim().isEmpty
                                ? 'Your Profile'
                                : _name.text,
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textDark)),
                        if (_mobile.text.trim().isNotEmpty)
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
                    validator: (v) => (v ?? '').trim().length != 10
                        ? 'Enter 10 digits'
                        : null,
                  ),
                  const SizedBox(height: 18),

                  const _Label('Village / Area'),
                  DropdownButtonFormField<String>(
                    initialValue: _village,
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
