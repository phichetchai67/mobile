import 'package:flutter/material.dart';
 
import '../auth/auth_service.dart';
import '../booking/booking_service.dart';
import '../model/format.dart';
import '../model/models.dart';
import 'admin_booking_page.dart';
import 'admin_patients_page.dart';
 
/// หน้าหลักของหมอ (ผู้ดูแล): ข้อมูลหมอ + นัดของหมอ + จองนัดให้คนไข้
class AdminHomePage extends StatelessWidget {
  final Doctor doctor;
  const AdminHomePage({super.key, required this.doctor});
 
  Future<void> _cancel(BuildContext context, Booking b) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('ยกเลิกนัดนี้?'),
        content: Text('${b.patientName}\n${b.program.name}\n'
            '${fmtDate(b.start)} ${fmtTime(b.start)}\n'
            'เวลานี้จะว่างให้จองใหม่ได้'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('ไม่ยกเลิก')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('ยกเลิกนัด')),
        ],
      ),
    );
    if (ok == true) bookingService.cancel(b);
  }
 
  Widget _stat(BuildContext context, String label, int value) => Expanded(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(children: [
              Text('$value',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(color: Colors.teal)),
              Text(label, style: Theme.of(context).textTheme.bodySmall),
            ]),
          ),
        ),
      );
 
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: bookingService,
      builder: (_, __) {
        final list = bookingService.forDoctor(doctor.id);
        final today = list.where((b) => isToday(b.start)).length;
 
        return Scaffold(
          appBar: AppBar(
            title: const Text('ระบบหมอ'),
            actions: [
              IconButton(
                tooltip: 'ข้อมูลคนไข้',
                icon: const Icon(Icons.people),
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const AdminPatientsPage())),
              ),
              IconButton(
                tooltip: 'ออกจากระบบ',
                icon: const Icon(Icons.logout),
                onPressed: authService.logout,
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => AdminBookingPage(doctor: doctor))),
            icon: const Icon(Icons.add),
            label: const Text('จองนัดให้คนไข้'),
          ),
          body: ListView(padding: const EdgeInsets.only(bottom: 88), children: [
            // ---- ข้อมูลหมอ ----
            Card(
              margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.medical_services)),
                title: Text(doctor.name,
                    style: Theme.of(context).textTheme.titleMedium),
                subtitle: Text('${doctor.specialty}\nโทร ${doctor.phone}  •  ไอดี ${doctor.id}'),
                isThreeLine: true,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
              child: Row(children: [
                _stat(context, 'นัดทั้งหมด', list.length),
                _stat(context, 'นัดวันนี้', today),
              ]),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text('นัดหมายของฉัน',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            if (list.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                    child: Text('ยังไม่มีนัด\nกด "จองนัดให้คนไข้" เพื่อเริ่มต้น',
                        textAlign: TextAlign.center)),
              ),
            for (final b in list)
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Expanded(
                            child: Text(b.patientName,
                                style: Theme.of(context).textTheme.titleMedium),
                          ),
                          if (isToday(b.start))
                            const Chip(
                                label: Text('วันนี้'),
                                visualDensity: VisualDensity.compact),
                        ]),
                        Text('โทร ${b.patientPhone}'),
                        Text('${b.program.name} (${b.minutes} นาที)  ฿${b.price}'),
                        Text(
                            'วันที่ ${fmtDate(b.start)}  เวลา ${fmtTime(b.start)} - ${fmtTime(b.end)}'),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => _cancel(context, b),
                            child: const Text('ยกเลิกนัด'),
                          ),
                        ),
                      ]),
                ),
              ),
          ]),
        );
      },
    );
  }
}