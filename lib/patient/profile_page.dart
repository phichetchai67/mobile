import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
 
import '../auth/auth_service.dart';
import '../model/format.dart';
 
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}
 
class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _first, _last, _year, _phone, _note;
 
  @override
  void initState() {
    super.initState();
    final a = authService.currentAccount;
    _first = TextEditingController(text: a?.firstName ?? '');
    _last = TextEditingController(text: a?.lastName ?? '');
    _year = TextEditingController(
        text: (a == null || a.birthYear == 0) ? '' : '${a.birthYear}');
    _phone = TextEditingController(text: a?.phone ?? '');
    _note = TextEditingController(text: a?.note ?? '');
  }
 
  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    _year.dispose();
    _phone.dispose();
    _note.dispose();
    super.dispose();
  }
 
  Future<void> _confirmLogout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ออกจากระบบ?'),
        content: const Text('คุณต้องการออกจากระบบใช่หรือไม่'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('ยกเลิก')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('ออกจากระบบ')),
        ],
      ),
    );
    if (ok == true) authService.logout();
  }
 
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    await authService.updateProfile(_first.text, _last.text,
        int.parse(_year.text), _phone.text, _note.text);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('บันทึกข้อมูลแล้ว')));
  }
 
  @override
  Widget build(BuildContext context) {
    final idCard = authService.currentUser ?? '';
    return Scaffold(
      appBar: AppBar(title: const Text('ข้อมูลของฉัน'), actions: [
        IconButton(
            onPressed: _confirmLogout,
            icon: const Icon(Icons.logout),
            tooltip: 'ออกจากระบบ'),
      ]),
      body: Form(
        key: _formKey,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          // เลขบัตรประชาชน: ดูได้อย่างเดียว (ใช้เป็นไอดีล็อกอิน)
          TextFormField(
            initialValue: idCard,
            readOnly: true,
            enabled: false,
            decoration: const InputDecoration(
                labelText: 'เลขบัตรประชาชน (แก้ไขไม่ได้)',
                border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _first,
            decoration: const InputDecoration(
                labelText: 'ชื่อ', border: OutlineInputBorder()),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'กรุณากรอกชื่อ' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _last,
            decoration: const InputDecoration(
                labelText: 'นามสกุล', border: OutlineInputBorder()),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'กรุณากรอกนามสกุล' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _year,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(4),
            ],
            decoration: const InputDecoration(
                labelText: 'ปีเกิด (พ.ศ.)', border: OutlineInputBorder()),
            validator: (v) {
              final n = int.tryParse(v ?? '');
              return (n != null && isValidBirthYear(n))
                  ? null
                  : 'กรุณากรอกปีเกิดเป็น พ.ศ. (เช่น 2540)';
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            decoration: const InputDecoration(
                labelText: 'เบอร์โทร', border: OutlineInputBorder()),
            validator: (v) => RegExp(r'^0\d{9}$').hasMatch(v ?? '')
                ? null
                : 'เบอร์โทร 10 หลัก ขึ้นต้นด้วย 0',
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _note,
            maxLines: 3,
            decoration: const InputDecoration(
                labelText: 'อาการ / ข้อควรระวัง (ถ้ามี)',
                border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: _save, child: const Text('บันทึก')),
        ]),
      ),
    );
  }
}