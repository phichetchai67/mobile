import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../model/format.dart';
import 'auth_service.dart';

// หน้าสมัครสมาชิก ชื่อ นามสกุล ปีเกิด เบอร์โทร เลขบัตรประชาชน ตั้งรหัสผ่าน
// สมัครสำเร็จ กลับหน้าล็อกอิน ส่งเลขบัตรกลับไปเติมให้
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _year = TextEditingController();
  final _phone = TextEditingController();
  final _idCard = TextEditingController();
  final _pass = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false, _hide = true;
  String? _error;

  @override
  void dispose() {
    for (final c in [_first, _last, _year, _phone, _idCard, _pass, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final err = await authService.register(
      idCard: _idCard.text,
      firstName: _first.text,
      lastName: _last.text,
      birthYear: int.parse(_year.text),
      phone: _phone.text,
      password: _pass.text,
    );
    if (!mounted) return;
    if (err != null) {
      setState(() {
        _loading = false;
        _error = err;
      });
      return;
    }
    Navigator.pop(context, _idCard.text.trim());
  }

  Widget _field(
    TextEditingController c,
    String label, {
    TextInputType? keyboard,
    int? maxDigits,
    bool obscure = false,
    Widget? suffix,
    String? hint,
    String? Function(String?)? validator,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: c,
          keyboardType: keyboard,
          obscureText: obscure,
          textInputAction: TextInputAction.next,
          inputFormatters: maxDigits == null
              ? null
              : [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(maxDigits),
                ],
          decoration: InputDecoration(
              labelText: label,
              hintText: hint,
              suffixIcon: suffix,
              border: const OutlineInputBorder()),
          validator: validator,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('สมัครสมาชิก')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: _formKey,
              child: Column(children: [
                _field(_first, 'ชื่อ',
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'กรุณากรอกชื่อ' : null),
                _field(_last, 'นามสกุล',
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'กรุณากรอกนามสกุล'
                        : null),
                _field(_year, 'ปีเกิด (พ.ศ.)',
                    hint: 'เช่น 2540',
                    keyboard: TextInputType.number,
                    maxDigits: 4,
                    validator: (v) {
                      final n = int.tryParse(v ?? '');
                      return (n != null && isValidBirthYear(n))
                          ? null
                          : 'กรุณากรอกปีเกิดเป็น พ.ศ. (เช่น 2540)';
                    }),
                _field(_phone, 'เบอร์โทร',
                    keyboard: TextInputType.phone,
                    maxDigits: 10,
                    validator: (v) => RegExp(r'^0\d{9}$').hasMatch(v ?? '')
                        ? null
                        : 'เบอร์โทร 10 หลัก ขึ้นต้นด้วย 0'),
                _field(_idCard, 'เลขบัตรประชาชน',
                    keyboard: TextInputType.number,
                    maxDigits: 13,
                    validator: (v) => RegExp(r'^\d{13}$').hasMatch(v ?? '')
                        ? null
                        : 'เลขบัตรประชาชนต้องมี 13 หลัก'),
                _field(_pass, 'ตั้งรหัสผ่าน',
                    obscure: _hide,
                    suffix: IconButton(
                      icon: Icon(_hide ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => _hide = !_hide),
                    ),
                    validator: (v) => (v ?? '').length < 6
                        ? 'รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร'
                        : null),
                _field(_confirm, 'ยืนยันรหัสผ่าน',
                    obscure: _hide,
                    validator: (v) =>
                        v == _pass.text ? null : 'รหัสผ่านไม่ตรงกัน'),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(_error!,
                        style:
                            TextStyle(color: Theme.of(context).colorScheme.error)),
                  ),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('สมัครสมาชิก'),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}