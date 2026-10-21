
import 'dart:convert';
 
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
 
import '../auth/auth_service.dart';
import '../model/models.dart';
 
/// เก็บนัดหมาย เช็กว่าหมอ/คนไข้ว่างไหม และเตียงนวดพอไหม (กันนัดทับกันจนเตียงเกิน)
/// ข้อมูลถูกเก็บในเครื่อง (shared_preferences)
class BookingService extends ChangeNotifier {
  static const _key = 'bookings_v2';
 
  final List<Booking> bookings = [];
  SharedPreferences? _prefs;
 
  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final raw = _prefs!.getString(_key);
    if (raw == null) return;
    try {
      for (final j in jsonDecode(raw) as List) {
        final b = Booking.fromJson(j as Map<String, dynamic>);
        if (b != null) bookings.add(b);
      }
    } catch (_) {
      bookings.clear(); // ข้อมูลเสีย: เริ่มใหม่
    }
  }
 
  Future<void> _save() async {
    await _prefs?.setString(
        _key, jsonEncode([for (final b in bookings) b.toJson()]));
  }
 
  List<Booking> forDoctor(String doctorId) => [
        for (final b in bookings)
          if (b.doctor.id == doctorId) b
      ]..sort((a, b) => a.start.compareTo(b.start));
 
  List<Booking> forPatient(String id) => [
        for (final b in bookings)
          if (b.patientId == id) b
      ]..sort((a, b) => a.start.compareTo(b.start));
 
  bool _overlap(Booking b, DateTime start, DateTime end) =>
      start.isBefore(b.end) && b.start.isBefore(end);
 
  /// หมอว่างในช่วง [start, start+minutes) ไหม
  bool isDoctorFree(String doctorId, DateTime start, int minutes) {
    final end = start.add(Duration(minutes: minutes));
    return !bookings
        .any((b) => b.doctor.id == doctorId && _overlap(b, start, end));
  }
 
  bool isPatientFree(String id, DateTime start, int minutes) {
    final end = start.add(Duration(minutes: minutes));
    return !bookings.any((b) => b.patientId == id && _overlap(b, start, end));
  }
 
  /// จำนวนเตียงที่ถูกใช้พร้อมกันมากที่สุดในช่วง [start, end)
  int _peakBedsInUse(DateTime start, DateTime end) {
    final overlapping = [
      for (final b in bookings)
        if (_overlap(b, start, end)) b
    ];
    // จุดที่จำนวนคนใช้เตียงอาจเปลี่ยน = ตอนเริ่มช่วงนี้ และตอนที่นัดอื่นเริ่ม
    final points = <DateTime>[
      start,
      for (final b in overlapping)
        if (b.start.isAfter(start)) b.start,
    ];
    var peak = 0;
    for (final t in points) {
      final n =
          overlapping.where((b) => !b.start.isAfter(t) && b.end.isAfter(t)).length;
      if (n > peak) peak = n;
    }
    return peak;
  }
 
  /// จำนวนเตียงที่ยังว่างตลอดช่วง [start, start+minutes)
  int bedsFree(DateTime start, int minutes) {
    final free =
        kBedCount - _peakBedsInUse(start, start.add(Duration(minutes: minutes)));
    return free < 0 ? 0 : free;
  }
 
  /// หมอจองนัดให้คนไข้ คืน booking ถ้าสำเร็จ หรือข้อความ error
  ({Booking? booking, String? error}) book({
    required Program program,
    required int minutes,
    required Doctor doctor,
    required DateTime start,
    required PatientRef patient,
  }) {
    final option = program.options.firstWhere((o) => o.minutes == minutes,
        orElse: () => program.options.first);
    if (!start.isAfter(DateTime.now())) {
      return (booking: null, error: 'เลือกเวลาที่ยังไม่ผ่านมาแล้ว');
    }
    if (!isDoctorFree(doctor.id, start, option.minutes)) {
      return (booking: null, error: 'ช่วงเวลานี้หมอไม่ว่างแล้ว');
    }
    if (bedsFree(start, option.minutes) <= 0) {
      return (
        booking: null,
        error: 'เตียงนวดเต็มในช่วงเวลานี้ (ร้านมี $kBedCount เตียง)'
      );
    }
    if (!isPatientFree(patient.id, start, option.minutes)) {
      return (booking: null, error: 'คนไข้มีนัดอื่นในช่วงเวลานี้แล้ว');
    }
    final b = Booking(program, option.minutes, option.price, doctor, start,
        patientId: patient.id,
        patientName: patient.name,
        patientPhone: patient.phone);
    bookings.add(b);
    _save();
    notifyListeners();
    return (booking: b, error: null);
  }
 
  /// ยกเลิกนัด (เวลาและเตียงจะว่างให้จองใหม่ได้)
  void cancel(Booking b) {
    if (bookings.remove(b)) {
      _save();
      notifyListeners();
    }
  }
}
 
final bookingService = BookingService();