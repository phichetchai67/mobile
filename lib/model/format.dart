String fmtDate(DateTime d) => '${d.day}/${d.month}/${d.year}';
 
String fmtTime(DateTime t) =>
    '${t.hour}:${t.minute.toString().padLeft(2, '0')}';
 
bool isToday(DateTime d) {
  final n = DateTime.now();
  return d.year == n.year && d.month == n.month && d.day == n.day;
}
 
/// ปีปัจจุบันเป็น พ.ศ.
int currentBuddhistYear() => DateTime.now().year + 543;
 
/// ปีเกิด (พ.ศ.) ที่เป็นไปได้: ไม่เกินปีนี้ และไม่เกิน 120 ปีย้อนหลัง
bool isValidBirthYear(int y) =>
    y <= currentBuddhistYear() && y >= currentBuddhistYear() - 120;
 
int ageFromBirthYear(int birthYearBE) => currentBuddhistYear() - birthYearBE;
 