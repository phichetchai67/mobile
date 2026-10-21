import 'package:flutter/material.dart';
import '../auth/auth_service.dart';
import '../booking/booking_service.dart';
import '../model/format.dart';
import '../model/models.dart';

// หมอจองนัดให้คนไข้ พิมพ์ค้นหา/เลือกคนไข้ โปรแกรม ระยะเวลา วัน เวลา
// เวลานัดต้องไม่ทำให้ใช้เตียงเกินจำนวนเตียงของร้าน
class AdminBookingPage extends StatefulWidget {
  final Doctor doctor;
  const AdminBookingPage({super.key, required this.doctor});
  @override
  State<AdminBookingPage> createState() => _AdminBookingPageState();
}
class _AdminBookingPageState extends State<AdminBookingPage> {
  String? _patientId;
  String _query = ''; // ข้อความที่พิมพ์ในช่องคนไข้
  Program _program = programs.first;
  int _minutes = programs.first.options.first.minutes;
  DateTime _date = DateTime.now();
  int? _hour;
  final _hours = [for (var h = 10; h <= 18; h++) h];

  DurationOption get _option => _program.options.firstWhere(
      (o) => o.minutes == _minutes,
      orElse: () => _program.options.first);

  DateTime _slot(int h) => DateTime(_date.year, _date.month, _date.day, h);

  // ค้นหาด้วยเลขบัตรประชาชน (บางส่วนหรือครบ) ชื่อ หรือเบอร์โทร
  bool _matches(PatientRef p, String q) {
    final s = q.trim().toLowerCase();
    if (s.isEmpty) return true;
    return p.id.contains(s) ||
        p.name.toLowerCase().contains(s) ||
        p.phone.contains(s);
  }

  String _label(PatientRef p) => '${p.name}  (${p.phone})';

  // ผู้ใช้พิมพ์เอง: ล้างตัวที่เลือกไว้ แต่ถ้าพิมพ์เลขบัตรครบ 13 หลักตรงกับคนไข้ เลือกให้เลย
  void _onTyped(String v) {
    final q = v.trim();
    PatientRef? exact;
    for (final p in authService.patients) {
      if (p.id == q) exact = p;
    }
    setState(() {
      _query = v;
      _patientId = exact?.id;
    });
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (d != null) {
      setState(() {
        _date = d;
        _hour = null;
      });
    }
  }

  void _msg(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _submit() async {
    PatientRef? patient;
    for (final p in authService.patients) {
      if (p.id == _patientId) patient = p;
    }
    if (patient == null) {
      _msg('กรุณาเลือกคนไข้');
      return;
    }
    if (_hour == null) {
      _msg('กรุณาเลือกเวลา');
      return;
    }
    final result = bookingService.book(
        program: _program,
        minutes: _minutes,
        doctor: widget.doctor,
        start: _slot(_hour!),
        patient: patient);
    if (result.error != null) {
      _msg(result.error!);
      setState(() => _hour = null);
      return;
    }
    final b = result.booking!;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        icon: const Icon(Icons.check_circle, size: 56, color: Colors.green),
        title: const Text('จองนัดสำเร็จ'),
        content: Text('คนไข้: ${b.patientName}\n'
            'นัดกับ ${b.doctor.name}\n'
            '${b.program.name} ${b.minutes} นาที (฿${b.price})\n'
            'วันที่ ${fmtDate(b.start)}\n'
            'เวลา ${fmtTime(b.start)} - ${fmtTime(b.end)}'),
        actions: [
          FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ตกลง')),
        ],
      ),
    );
    if (mounted) Navigator.pop(context);
  }

  Widget _timeChip(int h) {
    final s = _slot(h);
    final m = _option.minutes;
    final future = s.isAfter(DateTime.now());
    final doctorFree = bookingService.isDoctorFree(widget.doctor.id, s, m);
    final beds = bookingService.bedsFree(s, m);
    final ok = future && doctorFree && beds > 0;
    final bedText = 'เตียงว่าง $beds/$kBedCount';
    return ChoiceChip(
      label: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('$h:00'),
        if (!future)
          Text('ผ่านแล้ว', style: Theme.of(context).textTheme.labelSmall)
        else ...[
          Text(bedText, style: Theme.of(context).textTheme.labelSmall),
          if (!doctorFree)
            Text('หมอไม่ว่าง',
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: Theme.of(context).colorScheme.error)),
        ],
      ]),
      selected: _hour == h,
      onSelected: ok ? (_) => setState(() => _hour = h) : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final all = authService.patients;
    PatientRef? selected;
    for (final p in all) {
      if (p.id == _patientId) selected = p;
    }
    final noMatch = _query.trim().isNotEmpty &&
        selected == null &&
        !all.any((p) => _matches(p, _query));

    return ListenableBuilder(
      listenable: bookingService,
      builder: (_, __) => Scaffold(
        appBar: AppBar(title: Text('จองนัด: ${widget.doctor.name}')),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          // คนไข้: พิมพ์เลขบัตร/ชื่อ/เบอร์ได้ หรือกดเลือกจากรายชื่อ
          if (all.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('ยังไม่มีคนไข้ในระบบ\nคนไข้ต้องสมัครสมาชิกก่อน'),
              ),
            )
          else ...[
            Autocomplete<PatientRef>(
              displayStringForOption: _label,
              optionsBuilder: (value) =>
                  all.where((p) => _matches(p, value.text)),
              onSelected: (p) => setState(() {
                _patientId = p.id;
                _query = _label(p);
              }),
              fieldViewBuilder: (context, controller, focusNode, onSubmit) =>
                  TextField(
                controller: controller,
                focusNode: focusNode,
                onChanged: _onTyped,
                decoration: InputDecoration(
                  labelText: 'คนไข้',
                  hintText: 'พิมพ์เลขบัตรประชาชน / ชื่อ / เบอร์โทร',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: controller.text.isEmpty
                      ? const Icon(Icons.arrow_drop_down)
                      : IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            controller.clear();
                            _onTyped('');
                          },
                        ),
                ),
              ),
            ),
            if (noMatch)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('ไม่พบคนไข้ที่ตรงกับที่พิมพ์',
                    style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ),
            // สรุปคนไข้ที่เลือก ไว้ตรวจว่าถูกคน
            if (selected != null)
              Card(
                margin: const EdgeInsets.only(top: 8),
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(selected.name),
                  subtitle:
                      Text('โทร ${selected.phone}  •  อายุ ${selected.age} ปี'),
                ),
              ),
          ],
          const SizedBox(height: 16),

          // โปรแกรม
          InputDecorator(
            decoration: const InputDecoration(
                labelText: 'โปรแกรม', border: OutlineInputBorder()),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<Program>(
                isExpanded: true,
                value: _program,
                items: [
                  for (final p in programs)
                    DropdownMenuItem(value: p, child: Text(p.name)),
                ],
                onChanged: (v) => setState(() {
                  _program = v ?? _program;
                  // ถ้าโปรแกรมใหม่มีระยะเวลาเดิมให้คงไว้ ไม่มีก็ใช้ตัวแรก
                  if (!_program.options.any((o) => o.minutes == _minutes)) {
                    _minutes = _program.options.first.minutes;
                  }
                  _hour = null;
                }),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ---- ระยะเวลา ----
          const Text('ระยะเวลา'),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final o in _program.options)
              ChoiceChip(
                label: Text('${o.minutes} นาที  ฿${o.price}'),
                selected: _minutes == o.minutes,
                onSelected: (_) => setState(() {
                  _minutes = o.minutes;
                  _hour = null; // ความยาวเปลี่ยน เวลาว่างเปลี่ยน ต้องเลือกใหม่
                }),
              ),
          ]),
          const SizedBox(height: 16),

          // ---- วัน/เวลา ----
          OutlinedButton.icon(
            onPressed: _pickDate,
            icon: const Icon(Icons.calendar_today),
            label: Text(fmtDate(_date)),
          ),
          const SizedBox(height: 16),
          Text('เลือกเวลาเริ่ม (ร้านมี $kBedCount เตียง ใช้ร่วมกันทุกหมอ '
              'สีเทา = เตียงเต็ม หมอไม่ว่าง หรือเลยเวลาแล้ว)'),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final h in _hours) _timeChip(h),
          ]),
          if (_hour != null) ...[
            const SizedBox(height: 12),
            Text(
              'นัด ${fmtTime(_slot(_hour!))} - '
              '${fmtTime(_slot(_hour!).add(Duration(minutes: _minutes)))}  '
              '(${_option.minutes} นาที ฿${_option.price})',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(
              onPressed: all.isEmpty ? null : _submit,
              child: const Text('ยืนยันการจองนัด')),
        ]),
      ),
    );
  }
}