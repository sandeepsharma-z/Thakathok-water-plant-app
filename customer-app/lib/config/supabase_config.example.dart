/// Template for `supabase_config.dart` (which is gitignored).
///
/// Copy this file to `lib/config/supabase_config.dart` and fill in the values
/// from your Supabase project: Dashboard → Project Settings → API.
///
/// Only the anon / publishable key belongs here — it is designed to be shipped
/// inside client apps and is protected by Row Level Security.
/// NEVER put the service_role / secret key in the app.
class SupabaseConfig {
  SupabaseConfig._();

  static const String url = 'https://YOUR-PROJECT-REF.supabase.co';
  static const String anonKey = 'YOUR-PUBLISHABLE-ANON-KEY';
}
