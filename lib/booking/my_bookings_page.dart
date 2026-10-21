import 'package:flutter/material.dart';
import '../auth/auth_service.dart';
import '../model/format.dart';
import '../model/models.dart';
import 'booking_service.dart';

// นัดหมายของคนไข้ หมอเป็นคนจองให้ ฝั่งนี้ดูอย่างเดียว
class MyBookingsPage extends StatelessWidget {
  const MyBookingsPage({super.key});

  Widget _card(BuildContext context, Booking b, {required bool past}) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: past ? scheme.surfaceContainerHighest : null,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Text('นัดกับ ${b.doctor.name}',
                  style: Theme.of(context).textTheme.titleMedium),
            ),
            if (!past && isToday(b.start))
              const Chip(label: Text('วันนี้'), visualDensity: VisualDensity.compact),
          ]),
          const SizedBox(height: 4),
          Row(children: [
            const Icon(Icons.event, size: 18),
            const SizedBox(width: 6),
            Text('วันที่ ${fmtDate(b.start)}'),
          ]),
          Row(children: [
            const Icon(Icons.schedule, size: 18),
            const SizedBox(width: 6),
            Text('เวลา ${fmtTime(b.start)} - ${fmtTime(b.end)}'),
          ]),
          Row(children: [
            const Icon(Icons.spa, size: 18),
            const SizedBox(width: 6),
            Text('${b.program.name} (${b.minutes} นาที)  ฿${b.price}'),
          ]),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: bookingService,
      builder: (_, __) {
        final all = bookingService.forPatient(authService.currentUser ?? '');
        final now = DateTime.now();
        final upcoming = [for (final b in all) if (b.end.isAfter(now)) b];
        final past = [for (final b in all) if (!b.end.isAfter(now)) b].reversed;

        return Scaffold(
          appBar: AppBar(title: const Text('นัดหมายของฉัน')),
          body: all.isEmpty
              ? const Center(
                  child: Text('ยังไม่มีนัดหมาย\nเมื่อหมอจองนัดให้ จะแสดงที่นี่',
                      textAlign: TextAlign.center))
              : ListView(padding: const EdgeInsets.symmetric(vertical: 8), children: [
                  if (upcoming.isNotEmpty) ...[
                    const Padding(
                        padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
                        child: Text('นัดที่กำลังจะถึง',
                            style: TextStyle(fontWeight: FontWeight.bold))),
                    for (final b in upcoming) _card(context, b, past: false),
                  ],
                  if (past.isNotEmpty) ...[
                    const Padding(
                        padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
                        child: Text('ผ่านไปแล้ว',
                            style: TextStyle(fontWeight: FontWeight.bold))),
                    for (final b in past) _card(context, b, past: true),
                  ],
                ]),
        );
      },
    );
  }
}