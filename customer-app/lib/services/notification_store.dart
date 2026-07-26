import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationStore {
  NotificationStore._();
  static final NotificationStore instance = NotificationStore._();

  String _accountKey(String mobile, String suffix) =>
      'notifications_${mobile.trim()}_$suffix';

  SupabaseClient get _db => Supabase.instance.client;

  Future<bool> areAllRead(String mobile) async {
    final preferences = await SharedPreferences.getInstance();
    if (mobile.length == 10) {
      try {
        final customer = await _db
            .from('customers')
            .select('notifications_read')
            .eq('mobile', mobile)
            .maybeSingle();
        final serverValue = customer?['notifications_read'] as bool?;
        if (serverValue != null) {
          await preferences.setBool(
            _accountKey(mobile, 'read_v2'),
            serverValue,
          );
          return serverValue;
        }
      } catch (_) {
        // Use the on-device copy when offline or before schema migration.
      }
    }
    final accountValue = preferences.getBool(_accountKey(mobile, 'read_v2'));
    if (accountValue != null) return accountValue;

    // Carry forward the read state from builds that stored one device-wide
    // flag, so an existing customer does not see old notifications as new
    // immediately after updating the app.
    final legacyValue = preferences.getBool('notifications_read_v1') ?? false;
    if (legacyValue) {
      await preferences.setBool(_accountKey(mobile, 'read_v2'), true);
    }
    return legacyValue;
  }

  Future<void> markAllRead(String mobile) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_accountKey(mobile, 'read_v2'), true);
    if (mobile.length == 10) {
      try {
        await _db
            .from('customers')
            .update({'notifications_read': true}).eq('mobile', mobile);
      } catch (_) {
        // Local state still prevents the badge from returning while offline.
      }
    }
  }

  Future<Set<String>> removedIds(String mobile) async {
    final preferences = await SharedPreferences.getInstance();
    if (mobile.length == 10) {
      try {
        final customer = await _db
            .from('customers')
            .select('notification_removed_ids')
            .eq('mobile', mobile)
            .maybeSingle();
        final serverIds = List<String>.from(
          customer?['notification_removed_ids'] as List? ?? const [],
        );
        await preferences.setStringList(
          _accountKey(mobile, 'removed_v2'),
          serverIds,
        );
        return serverIds.toSet();
      } catch (_) {
        // Use local state when the server is unavailable.
      }
    }
    return (preferences.getStringList(_accountKey(mobile, 'removed_v2')) ??
            const <String>[])
        .toSet();
  }

  Future<void> remove(String mobile, String notificationId) async {
    final preferences = await SharedPreferences.getInstance();
    final removed = await removedIds(mobile)
      ..add(notificationId);
    await preferences.setStringList(
      _accountKey(mobile, 'removed_v2'),
      removed.toList(),
    );
    await _syncRemoved(mobile, removed);
  }

  Future<void> removeAll(
      String mobile, Iterable<String> notificationIds) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(
      _accountKey(mobile, 'removed_v2'),
      notificationIds.toSet().toList(),
    );
    await _syncRemoved(mobile, notificationIds.toSet());
    await markAllRead(mobile);
  }

  Future<void> _syncRemoved(String mobile, Set<String> ids) async {
    if (mobile.length != 10) return;
    try {
      await _db.from('customers').update({
        'notification_removed_ids': ids.toList(),
      }).eq('mobile', mobile);
    } catch (_) {
      // The local copy remains authoritative until the next successful sync.
    }
  }
}
