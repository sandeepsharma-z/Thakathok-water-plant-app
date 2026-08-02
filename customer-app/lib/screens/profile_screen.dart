import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

import '../services/booking_service.dart';
import '../services/auth_service.dart';
import '../services/profile_store.dart';
import '../services/app_config_service.dart';
import '../theme/app_colors.dart';
import '../widgets/dotted_loader.dart';
import '../widgets/language_selector.dart';
import '../services/language_service.dart';
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
  String _avatarUrl = '';
  Uint8List? _avatarPreviewBytes;
  bool _editing = false;
  bool _loaded = false;
  bool _uploadingAvatar = false;

  @override
  void initState() {
    super.initState();
    LanguageService.instance.addListener(_onLanguageChanged);
    _loadProfile();
  }

  void _onLanguageChanged() {
    if (mounted) setState(() {});
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
    LanguageService.instance.removeListener(_onLanguageChanged);
    _name.dispose();
    _mobile.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final name = _name.text.trim();
    final mobile =
        await AuthService.instance.currentMobile() ?? _mobile.text.trim();
    final address = _address.text.trim();
    try {
      // Validate the authenticated session and persist server-side first.
      await BookingService.instance.upsertCustomer(
        mobile: mobile,
        name: name,
        village: _village,
        address: address,
      );
      await ProfileStore.instance.save(CustomerProfile(
        name: name,
        mobile: mobile,
        village: _village,
        address: address,
        avatarUrl: _avatarUrl,
      ));
    } catch (error) {
      if (!mounted) return;
      _showMessage(error.toString().replaceFirst('Exception: ', ''));
      return;
    }
    if (!mounted) return;
    setState(() => _editing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(tr('Profile saved.'))),
    );
  }

  Future<void> _showPhotoOptions() async {
    if (_uploadingAvatar) return;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(tr('Profile photo'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _PhotoOption(
                      icon: Icons.photo_library_outlined,
                      label: tr('Gallery'),
                      onTap: () {
                        Navigator.pop(sheetContext);
                        _pickAvatar(ImageSource.gallery);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _PhotoOption(
                      icon: Icons.photo_camera_outlined,
                      label: tr('Camera'),
                      onTap: () {
                        Navigator.pop(sheetContext);
                        _pickAvatar(ImageSource.camera);
                      },
                    ),
                  ),
                ],
              ),
              if (_avatarUrl.isNotEmpty) ...[
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    _removeAvatar();
                  },
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: Text(tr('Remove current photo')),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickAvatar(ImageSource source) async {
    final mobile = _mobile.text.trim();
    if (mobile.length != 10) {
      _showMessage('Save a valid 10-digit mobile number first.');
      return;
    }
    final selected = await ImagePicker().pickImage(
      source: source,
      imageQuality: 78,
      maxWidth: 1000,
      maxHeight: 1000,
    );
    if (selected == null || !mounted) return;

    final cropped = await ImageCropper().cropImage(
      sourcePath: selected.path,
      compressFormat: ImageCompressFormat.jpg,
      compressQuality: 82,
      maxWidth: 1000,
      maxHeight: 1000,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: tr('Crop profile photo'),
          toolbarColor: AppColors.liveBrand,
          toolbarWidgetColor: Colors.white,
          activeControlsWidgetColor: AppColors.liveBrand,
          backgroundColor: Colors.black,
          cropFrameColor: Colors.white,
          cropGridColor: Colors.white54,
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: true,
          aspectRatioPresets: const [CropAspectRatioPreset.square],
        ),
        IOSUiSettings(
          title: tr('Crop profile photo'),
          aspectRatioLockEnabled: true,
          resetAspectRatioEnabled: false,
          aspectRatioPresets: const [CropAspectRatioPreset.square],
        ),
      ],
    );
    if (cropped == null || !mounted) return;

    final previousUrl = _avatarUrl;
    final croppedBytes = await cropped.readAsBytes();
    setState(() {
      _avatarPreviewBytes = croppedBytes;
      _uploadingAvatar = true;
    });
    try {
      final uploadedUrl = await BookingService.instance.uploadAvatar(
        mobile: mobile,
        bytes: croppedBytes,
        extension: 'jpg',
      );
      await BookingService.instance.updateCustomerAvatar(
        mobile: mobile,
        avatarUrl: uploadedUrl,
      );
      await _saveLocalAvatar(uploadedUrl);
      if (!mounted) return;
      setState(() {
        _avatarUrl = uploadedUrl;
        _uploadingAvatar = false;
      });
      _showMessage(previousUrl.isEmpty
          ? 'Profile photo updated.'
          : 'Profile photo replaced.');
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _avatarUrl = previousUrl;
        _avatarPreviewBytes = null;
      });
      _showMessage('Could not upload photo. Current photo was kept.');
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  Future<void> _removeAvatar() async {
    final shouldRemove = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(tr('Remove profile photo?')),
            content:
                Text(tr('The default profile icon will be shown instead.')),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: Text(tr('CANCEL'))),
              TextButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: Text(tr('REMOVE'))),
            ],
          ),
        ) ??
        false;
    if (!shouldRemove || !mounted) return;

    final previousUrl = _avatarUrl;
    setState(() => _uploadingAvatar = true);
    try {
      await BookingService.instance.updateCustomerAvatar(
        mobile: _mobile.text.trim(),
        avatarUrl: '',
      );
      await _saveLocalAvatar('');
      if (!mounted) return;
      setState(() {
        _avatarUrl = '';
        _avatarPreviewBytes = null;
      });
      _showMessage('Profile photo removed.');
    } catch (_) {
      if (!mounted) return;
      setState(() => _avatarUrl = previousUrl);
      _showMessage('Could not remove photo. Please try again.');
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  Future<void> _saveLocalAvatar(String avatarUrl) async {
    await ProfileStore.instance.save(CustomerProfile(
      name: _name.text.trim(),
      mobile: _mobile.text.trim(),
      village: _village,
      address: _address.text.trim(),
      avatarUrl: avatarUrl,
    ));
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(tr(message))));
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
        title: Text(AppConfigService.instance.label('screen_profile'),
            style: TextStyle(
                color: AppColors.liveBrand,
                fontWeight: FontWeight.w700,
                fontSize: 19)),
        actions: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 7),
            child: LanguageSelector(compact: true),
          ),
          if (!_editing)
            TextButton.icon(
              onPressed: () => setState(() => _editing = true),
              icon: const Icon(Icons.edit_outlined, size: 17),
              label: Text(tr('Edit')),
              style: TextButton.styleFrom(foregroundColor: AppColors.liveBrand),
            ),
        ],
      ),
      body: !_loaded
          ? Center(child: CircularProgressIndicator(color: AppColors.liveBrand))
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
                          onTap: _showPhotoOptions,
                          child: SizedBox(
                            height: 98,
                            width: 98,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  height: 88,
                                  width: 88,
                                  decoration: BoxDecoration(
                                    color: AppColors.tint,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: AppColors.liveBrand
                                            .withValues(alpha: 0.25),
                                        width: 2),
                                  ),
                                  child: ClipOval(
                                    child: _avatarPreviewBytes != null
                                        ? Image.memory(
                                            _avatarPreviewBytes!,
                                            fit: BoxFit.cover,
                                            width: 88,
                                            height: 88,
                                          )
                                        : _uploadingAvatar
                                            ? const DottedLoader(size: 36)
                                            : _avatarUrl.isEmpty
                                                ? Icon(Icons.person_rounded,
                                                    size: 48,
                                                    color: AppColors.liveBrand)
                                                : Image.network(
                                                    _avatarUrl,
                                                    key: ValueKey(_avatarUrl),
                                                    fit: BoxFit.cover,
                                                    width: 88,
                                                    height: 88,
                                                    errorBuilder:
                                                        (_, __, ___) => Icon(
                                                      Icons.person_rounded,
                                                      size: 48,
                                                      color:
                                                          AppColors.liveBrand,
                                                    ),
                                                  ),
                                  ),
                                ),
                                Positioned(
                                  right: 0,
                                  bottom: 3,
                                  child: Container(
                                    height: 34,
                                    width: 34,
                                    decoration: BoxDecoration(
                                      color: AppColors.liveBrand,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: Colors.white, width: 3),
                                    ),
                                    child: const Icon(Icons.camera_alt_rounded,
                                        size: 17, color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed:
                              _uploadingAvatar ? null : _showPhotoOptions,
                          child: Text(tr(_avatarUrl.isEmpty
                              ? 'Add photo'
                              : 'Change photo')),
                        ),
                        Text(
                            _name.text.trim().isEmpty
                                ? tr('Your Profile')
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

                  _Label(tr('Full Name')),
                  TextFormField(
                    controller: _name,
                    enabled: _editing,
                    decoration: _dec('Your name'),
                    validator: (v) =>
                        (v ?? '').trim().isEmpty ? 'Enter your name' : null,
                  ),
                  const SizedBox(height: 18),

                  _Label(tr('Mobile Number')),
                  TextFormField(
                    controller: _mobile,
                    enabled: false,
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
                        ? tr('Enter 10 digits')
                        : null,
                  ),
                  const SizedBox(height: 18),

                  _Label(tr('Village / Area')),
                  DropdownButtonFormField<String>(
                    initialValue: _village,
                    isExpanded: true,
                    icon: Icon(Icons.keyboard_arrow_down_rounded,
                        color: AppColors.liveBrand),
                    decoration: _dec(tr('Select your village')),
                    items: kVillages
                        .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                        .toList(),
                    onChanged:
                        _editing ? (v) => setState(() => _village = v!) : null,
                  ),
                  const SizedBox(height: 18),

                  _Label(tr('Address / Hall Name')),
                  TextFormField(
                    controller: _address,
                    enabled: _editing,
                    maxLines: 3,
                    decoration: _dec('Your address'),
                    validator: (v) =>
                        (v ?? '').trim().isEmpty ? 'Enter an address' : null,
                  ),

                  if (_editing) ...[
                    SizedBox(height: 28),
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.liveBrand,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(tr('SAVE CHANGES'),
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

class _PhotoOption extends StatelessWidget {
  const _PhotoOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: Color(0xFFF3F7FF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.hairline),
          ),
          child: Column(
            children: [
              Icon(icon, color: AppColors.liveBrand, size: 28),
              const SizedBox(height: 7),
              Text(label,
                  style: const TextStyle(
                      color: AppColors.textDark, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );
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
        borderSide: BorderSide(color: AppColors.liveBrand, width: 1.4),
      ),
    );
