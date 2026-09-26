// ============================================================
// MediReach — User Session Manager
// Persists login state across app restarts using shared_prefs.
// ============================================================
import 'package:shared_preferences/shared_preferences.dart';
import 'package:miracle/data/models/models.dart';

class SessionManager {
  SessionManager._();
  static final SessionManager instance = SessionManager._();

  static const _keyUserId     = 'user_id';
  static const _keyUserName   = 'user_name';
  static const _keyUserRole   = 'user_role';
  static const _keyPhone      = 'user_phone';
  static const _keyAbhaId     = 'user_abha_id';
  static const _keyFacilityId = 'user_facility_id';
  static const _keyLoggedIn   = 'is_logged_in';

  // ── Save session after login ───────────────────────────────
  Future<void> saveSession(AppUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserId,   user.id);
    await prefs.setString(_keyUserName, user.name);
    await prefs.setInt(_keyUserRole,    user.role.index);
    await prefs.setString(_keyPhone,    user.phone);
    if (user.abhaId != null) {
      await prefs.setString(_keyAbhaId, user.abhaId!);
    }
    if (user.facilityId != null) {
      await prefs.setString(_keyFacilityId, user.facilityId!);
    }
    await prefs.setBool(_keyLoggedIn,   true);
  }

  // ── Read session ──────────────────────────────────────────
  Future<AppUser?> getSession() async {
    final prefs = await SharedPreferences.getInstance();
    final loggedIn = prefs.getBool(_keyLoggedIn) ?? false;
    if (!loggedIn) return null;

    return AppUser(
      id:         prefs.getString(_keyUserId)   ?? '',
      name:       prefs.getString(_keyUserName) ?? '',
      role:       UserRole.values[prefs.getInt(_keyUserRole) ?? 4],
      phone:      prefs.getString(_keyPhone)    ?? '',
      abhaId:     prefs.getString(_keyAbhaId),
      facilityId: prefs.getString(_keyFacilityId),
    );
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyLoggedIn) ?? false;
  }

  Future<UserRole> getCurrentRole() async {
    final prefs = await SharedPreferences.getInstance();
    return UserRole.values[prefs.getInt(_keyUserRole) ?? 4];
  }

  Future<String?> getCurrentUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserName);
  }

  // ── Clear on logout ────────────────────────────────────────
  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
