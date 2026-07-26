import 'package:shared_preferences/shared_preferences.dart';

/// The customer's own profile, saved on-device (no login/account needed).
class CustomerProfile {
  const CustomerProfile({
    this.name = '',
    this.mobile = '',
    this.village = '',
    this.address = '',
    this.avatarUrl = '',
  });

  final String name;
  final String mobile;
  final String village;
  final String address;
  final String avatarUrl;

  bool get isEmpty => name.isEmpty && mobile.isEmpty && address.isEmpty;
}

/// Thin wrapper over SharedPreferences for the customer profile.
class ProfileStore {
  ProfileStore._();
  static final ProfileStore instance = ProfileStore._();

  static const _kName = 'profile_name';
  static const _kMobile = 'profile_mobile';
  static const _kVillage = 'profile_village';
  static const _kAddress = 'profile_address';
  static const _kAvatarUrl = 'profile_avatar_url';

  Future<CustomerProfile> load() async {
    final p = await SharedPreferences.getInstance();
    return CustomerProfile(
      name: p.getString(_kName) ?? '',
      mobile: p.getString(_kMobile) ?? '',
      village: p.getString(_kVillage) ?? '',
      address: p.getString(_kAddress) ?? '',
      avatarUrl: p.getString(_kAvatarUrl) ?? '',
    );
  }

  Future<void> save(CustomerProfile c) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kName, c.name);
    await p.setString(_kMobile, c.mobile);
    await p.setString(_kVillage, c.village);
    await p.setString(_kAddress, c.address);
    await p.setString(_kAvatarUrl, c.avatarUrl);
  }
}
