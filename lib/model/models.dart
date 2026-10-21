/// จำนวนเตียงนวดของร้าน (ใช้ร่วมกันทุกหมอ) แก้ตัวเลขนี้ได้
const kBedCount = 3;
 
/// ตัวเลือกระยะเวลาของโปรแกรม พร้อมราคา
class DurationOption {
  final int minutes, price;
  const DurationOption(this.minutes, this.price);
}
 
class Program {
  final String id, name;
  final List<DurationOption> options;
  const Program(this.id, this.name, this.options);
}
 
/// โปรแกรมนวด + ระยะเวลาที่เลือกได้ (ราคาตามป้ายราคาค่าบริการของร้าน)
const programs = [
  Program('p1', 'นวดไทย', [
    DurationOption(60, 300),
    DurationOption(90, 450),
    DurationOption(120, 550),
  ]),
  Program('p5', 'นวดไทยประคบ', [
    DurationOption(60, 500),
    DurationOption(90, 750),
    DurationOption(120, 900),
  ]),
  Program('p3', 'นวดฝ่าเท้า', [
    DurationOption(60, 300),
    DurationOption(90, 450),
    DurationOption(120, 550),
  ]),
  Program('p4', 'นวดคอ บ่า ไหล่', [
    DurationOption(60, 400),
    DurationOption(90, 600),
    DurationOption(120, 750),
  ]),
  Program('p6', 'นวดหลังส่วนล่าง', [
    DurationOption(60, 400),
    DurationOption(90, 600),
    DurationOption(120, 750),
  ]),
  Program('p2', 'นวดไทยออยรีดเส้น', [
    DurationOption(60, 450),
    DurationOption(90, 675),
    DurationOption(120, 850),
  ]),
  Program('p7', 'แช่เท้าสมุนไพร', [
    DurationOption(30, 150),
  ]),
  Program('p8', 'แช่มือสมุนไพร', [
    DurationOption(30, 150),
  ]),
];

/// หมอ = ผู้ดูแลระบบ แต่ละคนมีไอดี/รหัสผ่านและข้อมูลของตัวเองตายตัว
/// (แก้ชื่อ ไอดี รหัส ข้อมูลได้ที่รายการนี้)
class Doctor {
  final String id, password, name, specialty, phone;
  const Doctor(this.id, this.password, this.name, this.specialty, this.phone);
}
 
const doctors = [
  Doctor('mali', 'mali1234', 'หมอมะลิ', 'นวดไทย', '081-111-1111'),
  Doctor('somchai', 'somchai1234', 'หมอสมชาย', 'นวดน้ำมันอโรมา', '082-222-2222'),
  Doctor('namfon', 'namfon1234', 'หมอน้ำฝน', 'นวดเท้า / นวดคอ บ่า ไหล่',
      '083-333-3333'),
];
 
/// นัดหมาย: หมอเป็นคนจองให้คนไข้ (ใช้เตียง 1 เตียงตลอดช่วงเวลานัด)
class Booking {
  final Program program;
  final int minutes, price; // ระยะเวลาและราคาที่เลือก
  final Doctor doctor;
  final DateTime start;
  final String patientId, patientName, patientPhone;
 
  Booking(this.program, this.minutes, this.price, this.doctor, this.start,
      {required this.patientId,
      required this.patientName,
      required this.patientPhone});
 
  DateTime get end => start.add(Duration(minutes: minutes));
 
  Map<String, dynamic> toJson() => {
        'program': program.id,
        'minutes': minutes,
        'price': price,
        'doctor': doctor.id,
        'start': start.toIso8601String(),
        'pid': patientId,
        'name': patientName,
        'phone': patientPhone,
      };
 
  /// คืน null ถ้าโปรแกรม/หมอในข้อมูลที่เก็บไว้ไม่มีแล้ว
  static Booking? fromJson(Map<String, dynamic> j) {
    Program? p;
    for (final x in programs) {
      if (x.id == j['program']) p = x;
    }
    Doctor? d;
    for (final x in doctors) {
      if (x.id == j['doctor']) d = x;
    }
    final start = DateTime.tryParse((j['start'] as String?) ?? '');
    if (p == null || d == null || start == null) return null;
    final minutes = (j['minutes'] as int?) ?? p.options.first.minutes;
    final price = (j['price'] as int?) ??
        p.options
            .firstWhere((o) => o.minutes == minutes, orElse: () => p!.options.first)
            .price;
    return Booking(p, minutes, price, d, start,
        patientId: (j['pid'] as String?) ?? '',
        patientName: (j['name'] as String?) ?? '',
        patientPhone: (j['phone'] as String?) ?? '');
  }
}