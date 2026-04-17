import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cdc_app/core/constants/app_constants.dart';
import 'package:cdc_app/data/models/models.dart';

class SupabaseService {
  static final SupabaseService _i = SupabaseService._();
  factory SupabaseService() => _i;
  SupabaseService._();

  static const String url    = 'https://rkwcfrhgugllqndytink.supabase.co';
  static const String anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJrd2NmcmhndWdsbHFuZHl0aW5rIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzYzNzIzMDAsImV4cCI6MjA5MTk0ODMwMH0.Wk_sjVevUj5YC4o9TBPB9sqK7MrIRpYrR1MudnUYris';

  static Future<void> initialize() async {
    await Supabase.initialize(url: url, anonKey: anonKey);
  }

  SupabaseClient get client => Supabase.instance.client;

  AppUser? _currentUser;
  AppUser? get currentUser => _currentUser;
  bool     get isLoggedIn  => _currentUser != null;

  // ── LOGIN ─────────────────────────────────────────────
  Future<AppUser?> login(String email, String password) async {
    try {
      // Check user in users table
      final res = await client
        .from('users')
        .select()
        .eq('email', email.trim())
        .eq('is_active', true)
        .single();

      if (res == null) return null;

      // Simple password check (in production use proper hashing)
      final storedPass = res['password_hash'] as String?;
      if (storedPass == null || storedPass != password) return null;

      _currentUser = AppUser.fromMap(res);
      return _currentUser;
    } catch (e) {
      return null;
    }
  }

  void logout() { _currentUser = null; }

  Future<bool> changePassword(String newPassword) async {
    try {
      if (_currentUser == null) return false;
      await client.from('users').update({
        'password_hash': newPassword,
        'must_change_password': false,
      }).eq('id', _currentUser!.id);
      _currentUser = _currentUser!.copyWith(mustChangePassword: false);
      return true;
    } catch (_) { return false; }
  }

  // ── USERS ─────────────────────────────────────────────
  Future<List<AppUser>> getAllUsers() async {
    try {
      final res = await client.from('users').select().order('created_at');
      return (res as List).map((e) => AppUser.fromMap(e)).toList();
    } catch (_) { return []; }
  }

  Future<bool> createUser({
    required String fullName, required String email,
    required UserRole role, required String department, String phone = '',
  }) async {
    try {
      await client.from('users').insert({
        'name': fullName, 'email': email.trim(),
        'password_hash': 'Temp1234!',
        'role': role.name, 'department': department,
        'phone': phone, 'is_active': true,
        'must_change_password': true,
        'created_by': _currentUser?.id ?? 'system',
      });
      return true;
    } catch (_) { return false; }
  }

  Future<bool> updateUser({
    required String id, required String fullName,
    required String email, required UserRole role, required String department,
  }) async {
    try {
      await client.from('users').update({
        'name': fullName, 'email': email.trim(),
        'role': role.name, 'department': department,
      }).eq('id', id);
      return true;
    } catch (_) { return false; }
  }

  Future<bool> deleteUser(String id) async {
    try {
      await client.from('users').delete().eq('id', id);
      return true;
    } catch (_) { return false; }
  }

  // ── MISSIONS ──────────────────────────────────────────
  Future<List<Mission>> getMissions() async {
    try {
      final user = _currentUser;
      if (user == null) return [];
      List<Map<String, dynamic>> res;
      if (user.role == UserRole.magistrat || user.role == UserRole.directeur) {
        final all = await client.from('missions').select().order('date_debut');
        res = (all as List).cast<Map<String, dynamic>>()
          .where((m) => (m['equipe'] as List? ?? []).any((e) => e.toString().contains(user.fullName)))
          .toList();
      } else {
        res = ((await client.from('missions').select().order('date_debut')) as List)
          .cast<Map<String, dynamic>>();
      }
      return res.map((e) => Mission.fromMap(e)).toList();
    } catch (_) { return []; }
  }

  Future<bool> insertMission(Mission m) async {
    try {
      await client.from('missions').insert(m.toMap());
      return true;
    } catch (_) { return false; }
  }

  Future<bool> deleteMission(String id) async {
    try {
      await client.from('missions').delete().eq('id', id);
      return true;
    } catch (_) { return false; }
  }

  // ── EVENTS ────────────────────────────────────────────
  Future<List<AppEvent>> getEvents() async {
    try {
      final res = await client.from('events').select().order('date');
      return (res as List).map((e) => AppEvent.fromMap(e)).toList();
    } catch (_) { return []; }
  }

  Future<bool> insertEvent(AppEvent e) async {
    try {
      await client.from('events').insert(e.toMap());
      return true;
    } catch (_) { return false; }
  }

  Future<bool> deleteEvent(String id) async {
    try {
      await client.from('events').delete().eq('id', id);
      return true;
    } catch (_) { return false; }
  }
}
