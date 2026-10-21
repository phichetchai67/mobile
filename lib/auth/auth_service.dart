import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
 
import '../model/format.dart';
import '../model/models.dart';
 
class Account {
  final String firstName, lastName, phone, note, disease, salt, passwordHash;
  final int birthYear; // พ.ศ.
  const Account({
    required this.firstName,
    required this.lastName,
    required this.birthYear,
    required this.phone,
    this.note = '',
    this.disease = '', // ชื่อโรค
    required this.salt,
    required this.passwordHash,
  });
 
  Account copyWith({
    String? firstName,
    String? lastName,
    int? birthYear,
    String? phone,
    String? note,
    String? disease,
  }) =>
      Account(
        firstName: firstName ?? this.firstName,
        lastName: lastName ?? this.lastName,
        birthYear: birthYear ?? this.birthYear,
        phone: phone ?? this.phone,
        note: note ?? this.note,
        disease: disease ?? this.disease,
        salt: salt,
        passwordHash: passwordHash,
      );
 
  Map<String, dynamic> toJson() => {
        'firstName': firstName,
        'lastName': lastName,
        'birthYear': birthYear,
        'phone': phone,
        'note': note,
        'disease': disease,
        'salt': salt,
        'hash': passwordHash,
      };
 
  factory Account.fromJson(Map<String, dynamic> j) => Account(
        firstName: (j['firstName'] as String?) ?? '',
        lastName: (j['lastName'] as String?) ?? '',
        birthYear: (j['birthYear'] as int?) ?? 0,
        phone: (j['phone'] as String?) ?? '',
        note: (j['note'] as String?) ?? '',
        disease: (j['disease'] as String?) ?? '',
        salt: j['salt'] as String,
        passwordHash: j['hash'] as String,
      );
}
 
/// ข้อมูลคนไข้ที่หมอเลือกตอนจองนัด (ไม่เปิดเผยเลขบัตรในรายการ)
class PatientRef {
  final String id, name, phone, disease;
  final int birthYear;
  const PatientRef(this.id, this.name, this.phone, this.birthYear,
      [this.disease = '']);
  int get age => ageFromBirthYear(birthYear);
}
 
/// สมัคร / เข้าสู่ระบบ (คนไข้ด้วยเลขบัตรประชาชน + หมอด้วยไอดี) / ออกจากระบบ
/// บัญชีคนไข้และสถานะล็อกอินถูกเก็บในเครื่อง (shared_preferences)
/// รหัสผ่านไม่ถูกเก็บตรงๆ เก็บเป็นค่า hash (SHA-256 + salt)
/// บัญชีหมอกำหนดตายตัวใน models.dart (รายการ doctors)
class AuthService extends ChangeNotifier {
  static const _usersKey = 'auth_users_v2';
  static const _sessionKey = 'auth_current_user_v2';
  static const _doctorKey = 'auth_doctor_id';
 
  final Map<String, Account> _users = {}; // เลขบัตรประชาชน -> account
  String? currentUser; // เลขบัตรประชาชนของคนไข้ที่ล็อกอิน
  Doctor? currentDoctor; // หมอที่ล็อกอิน (ถ้ามี = โหมดผู้ดูแล)
  SharedPreferences? _prefs;
 
  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final raw = _prefs!.getString(_usersKey);
    if (raw != null) {
      try {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        map.forEach((id, v) {
          _users[id] = Account.fromJson(v as Map<String, dynamic>);
        });
      } catch (_) {
        _users.clear(); // ข้อมูลเสีย: เริ่มใหม่
      }
    }
    final doctorId = _prefs!.getString(_doctorKey);
    if (doctorId != null) {
      for (final d in doctors) {
        if (d.id == doctorId) currentDoctor = d;
      }
    }
    final session = _prefs!.getString(_sessionKey);
    if (currentDoctor == null && session != null && _users.containsKey(session)) {
      currentUser = session;
    }
  }
 
  bool get isAdmin => currentDoctor != null;
  bool get isLoggedIn => isAdmin || currentUser != null;
 
  Account? get currentAccount => _users[currentUser];
 
  String get displayName {
    final a = currentAccount;
    return a == null ? '' : '${a.firstName} ${a.lastName}';
  }
 
  /// คนไข้ทั้งหมดในระบบ (ให้หมอเลือกตอนจองนัด)
  List<PatientRef> get patients {
    final list = <PatientRef>[
      for (final e in _users.entries)
        PatientRef(e.key, '${e.value.firstName} ${e.value.lastName}',
            e.value.phone, e.value.birthYear, e.value.disease),
    ];
    list.sort((a, b) => a.name.compareTo(b.name));
    return list;
  }
 
  // ---------------- หมอ / ผู้ดูแลระบบ ----------------
  Future<String?> loginAdmin(String id, String password) async {
    await Future.delayed(const Duration(milliseconds: 600));
    Doctor? found;
    for (final d in doctors) {
      if (d.id == id.trim().toLowerCase() && d.password == password) {
        found = d;
      }
    }
    if (found == null) return 'ไอดีหรือรหัสผ่านไม่ถูกต้อง';
    currentDoctor = found;
    currentUser = null;
    await _prefs?.setString(_doctorKey, found.id);
    await _prefs?.remove(_sessionKey);
    notifyListeners();
    return null;
  }
 
  // ---------------- คนไข้ ----------------
  /// สมัครสมาชิก (ยังไม่ล็อกอินให้ ต้องกลับไปล็อกอินด้วยเลขบัตร + รหัสผ่าน)
  Future<String?> register({
    required String idCard,
    required String firstName,
    required String lastName,
    required int birthYear,
    required String phone,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final id = idCard.trim();
    if (!RegExp(r'^\d{13}$').hasMatch(id)) {
      return 'เลขบัตรประชาชนต้องมี 13 หลัก';
    }
    if (firstName.trim().isEmpty) return 'กรุณากรอกชื่อ';
    if (lastName.trim().isEmpty) return 'กรุณากรอกนามสกุล';
    if (!isValidBirthYear(birthYear)) return 'ปีเกิด (พ.ศ.) ไม่ถูกต้อง';
    if (!RegExp(r'^0\d{9}$').hasMatch(phone.trim())) {
      return 'เบอร์โทรต้องมี 10 หลัก ขึ้นต้นด้วย 0';
    }
    if (password.length < 6) return 'รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร';
    if (_users.containsKey(id)) return 'เลขบัตรประชาชนนี้สมัครสมาชิกแล้ว';
 
    final salt = _newSalt();
    _users[id] = Account(
      firstName: firstName.trim(),
      lastName: lastName.trim(),
      birthYear: birthYear,
      phone: phone.trim(),
      salt: salt,
      passwordHash: _hash(salt, password),
    );
    await _saveUsers();
    return null;
  }
 
  Future<String?> login(String idCard, String password) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final id = idCard.trim();
    if (!RegExp(r'^\d{13}$').hasMatch(id)) {
      return 'เลขบัตรประชาชนต้องมี 13 หลัก';
    }
    final a = _users[id];
    if (a == null || a.passwordHash != _hash(a.salt, password)) {
      return 'เลขบัตรประชาชนหรือรหัสผ่านไม่ถูกต้อง';
    }
    currentDoctor = null;
    currentUser = id;
    await _prefs?.setString(_sessionKey, id);
    await _prefs?.remove(_doctorKey);
    notifyListeners();
    return null;
  }
 
  /// แก้ไขข้อมูลส่วนตัวจากหน้า "ข้อมูลของฉัน" (เลขบัตรแก้ไม่ได้)
  Future<void> updateProfile(String first, String last, int birthYear,
      String phone, String note) async {
    final a = currentAccount;
    if (a == null) return;
    _users[currentUser!] = a.copyWith(
      firstName: first.trim(),
      lastName: last.trim(),
      birthYear: birthYear,
      phone: phone.trim(),
      note: note.trim(),
    );
    await _saveUsers();
    notifyListeners();
  }
 
  /// ข้อมูลบัญชีคนไข้ตามเลขบัตร (ให้หมอเปิดดูในหน้าข้อมูลคนไข้)
  Account? accountOf(String idCard) => _users[idCard];

  /// หมอแก้ชื่อโรคของคนไข้
  Future<void> updateDisease(String idCard, String disease) async {
    final a = _users[idCard];
    if (a == null) return;
    _users[idCard] = a.copyWith(disease: disease.trim());
    await _saveUsers();
    notifyListeners();
  }

  void logout() {
    currentUser = null;
    currentDoctor = null;
    _prefs?.remove(_sessionKey);
    _prefs?.remove(_doctorKey);
    notifyListeners();
  }
 
  Future<void> _saveUsers() async {
    final map = _users.map((k, v) => MapEntry(k, v.toJson()));
    await _prefs?.setString(_usersKey, jsonEncode(map));
  }
 
  String _newSalt() {
    final r = Random.secure();
    return base64UrlEncode(List<int>.generate(16, (_) => r.nextInt(256)));
  }
 
  String _hash(String salt, String password) =>
      sha256.convert(utf8.encode('$salt:$password')).toString();
}
 
final authService = AuthService();