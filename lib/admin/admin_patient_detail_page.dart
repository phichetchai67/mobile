import 'package:flutter/material.dart';
 
import '../auth/auth_service.dart';
import '../booking/booking_service.dart';
import '../model/format.dart';
import '../model/models.dart';
 
/// ข้อมูลคนไข้ฝั่งหมอ: เลขบัตร ชื่อ นามสกุล อายุ เบอร์โทร ชื่อโรค
/// และประวัตินัดย้อนหลังทั้งหมดของคนไข้คนนี้ (หมอแก้ชื่อโรคได้)
class AdminPatientDetailPage extends StatelessWidget {
  final String idCard;
  const AdminPatientDetailPage({super.key, required this.idCard});
 
  Future<void> _editDisease(BuildContext context, String current) async {
    final result = await showDialog<String>(
      context: context,
      builder: (_) => _DiseaseDialog(initial: current),
    );
    if (result != null) await authService.updateDisease(idCard, result);
  }
 
  Widget _row(String label, String value, {Widget? trailing}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
              width: 110,
              child: Text(label, style: const TextStyle(color: Colors.grey))),
          Expanded(child: Text(value.isEmpty ? '-' : value)),
          if (trailing != null) trailing,
        ]),
      );
 
  Widget _title(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
      );
 
  Widget _bookingCard(BuildContext context, Booking b, {required bool past}) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: past ? scheme.surfaceContainerHighest : null,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('นัดกับ ${b.doctor.name}',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text('วันที่ ${fmtDate(b.start)}  เวลา ${fmtTime(b.start)} - ${fmtTime(b.end)}'),
          Text('${b.program.name} (${b.minutes} นาที)  ฿${b.price}'),
        ]),
      ),
    );
  }
 
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([authService, bookingService]),
      builder: (context, _) {
        final a = authService.accountOf(idCard);
        if (a == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('ข้อมูลคนไข้')),
            body: const Center(child: Text('ไม่พบข้อมูลคนไข้')),
          );
        }
        final all = bookingService.forPatient(idCard);
        final now = DateTime.now();
        final upcoming = [
          for (final b in all)
            if (b.end.isAfter(now)) b
        ];
        // ย้อนหลัง: เรียงจากล่าสุดไปเก่าสุด
        final past = [
          for (final b in all)
            if (!b.end.isAfter(now)) b
        ].reversed.toList();
 
        return Scaffold(
          appBar: AppBar(title: Text('${a.firstName} ${a.lastName}')),
          body: ListView(padding: const EdgeInsets.only(bottom: 24), children: [
            Card(
              margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(children: [
                  _row('เลขบัตรประชาชน', idCard),
                  _row('ชื่อ', a.firstName),
                  _row('นามสกุล', a.lastName),
                  _row('อายุ',
                      a.birthYear == 0 ? '' : '${ageFromBirthYear(a.birthYear)} ปี'),
                  _row('เบอร์โทร', a.phone),
                  _row('ชื่อโรค', a.disease,
                      trailing: IconButton(
                        tooltip: 'แก้ไขชื่อโรค',
                        icon: const Icon(Icons.edit, size: 20),
                        visualDensity: VisualDensity.compact,
                        onPressed: () => _editDisease(context, a.disease),
                      )),
                ]),
              ),
            ),
            _title('ประวัติการมารับบริการ: ผ่านไปแล้ว ${past.length} ครั้ง'),
            if (all.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: Text('ยังไม่มีประวัตินัดหมาย')),
              ),
            if (upcoming.isNotEmpty) ...[
              _title('นัดที่กำลังจะถึง'),
              for (final b in upcoming) _bookingCard(context, b, past: false),
            ],
            if (past.isNotEmpty) ...[
              _title('นัดที่ผ่านไปแล้ว (ล่าสุดก่อน)'),
              for (final b in past) _bookingCard(context, b, past: true),
            ],
          ]),
        );
      },
    );
  }
}
 
class _DiseaseDialog extends StatefulWidget {
  final String initial;
  const _DiseaseDialog({required this.initial});
  @override
  State<_DiseaseDialog> createState() => _DiseaseDialogState();
}
 
class _DiseaseDialogState extends State<_DiseaseDialog> {
  late final TextEditingController _c =
      TextEditingController(text: widget.initial);
 
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }
 
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('แก้ไขชื่อโรค'),
      content: TextField(
        controller: _c,
        autofocus: true,
        maxLines: 2,
        decoration: const InputDecoration(
            labelText: 'ชื่อโรค', border: OutlineInputBorder()),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก')),
        FilledButton(
            onPressed: () => Navigator.pop(context, _c.text),
            child: const Text('บันทึก')),
      ],
    );
  }
}