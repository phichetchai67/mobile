import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
 
import 'auth_service.dart';
import 'register_page.dart';
 
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}
 
class _LoginPageState extends State<LoginPage> {
  final _idCard = TextEditingController(); // เลขบัตรประชาชน (คนไข้)
  final _doctorId = TextEditingController(); // ไอดีหมอ
  final _pass = TextEditingController();
  bool _isAdmin = false; // false = ผู้ใช้, true = หมอ/ผู้ดูแล
  bool _loading = false;
  String? _error;
 
  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final err = _isAdmin
        ? await authService.loginAdmin(_doctorId.text, _pass.text)
        : await authService.login(_idCard.text, _pass.text);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = err;
    });
  }
 
  Future<void> _openRegister() async {
    final id = await Navigator.push<String>(
        context, MaterialPageRoute(builder: (_) => const RegisterPage()));
    if (id != null && mounted) {
      setState(() {
        _idCard.text = id; // เติมเลขบัตรให้ ใส่แค่รหัสผ่าน
        _pass.clear();
        _error = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('สมัครสมาชิกสำเร็จ กรุณาเข้าสู่ระบบ')));
    }
  }
 
  void _switchRole(bool admin) => setState(() {
        _isAdmin = admin;
        _error = null;
        _pass.clear();
      });
 
  @override
  void dispose() {
    _idCard.dispose();
    _doctorId.dispose();
    _pass.dispose();
    super.dispose();
  }
 
  @override
  Widget build(BuildContext context) {
    final title = _isAdmin ? 'เข้าสู่ระบบสำหรับหมอ' : 'เข้าสู่ระบบ';
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(children: [
              Icon(_isAdmin ? Icons.admin_panel_settings : Icons.spa,
                  size: 72, color: Colors.teal),
              const SizedBox(height: 8),
              Text(title, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                      value: false,
                      icon: Icon(Icons.person),
                      label: Text('ผู้ใช้')),
                  ButtonSegment(
                      value: true,
                      icon: Icon(Icons.admin_panel_settings),
                      label: Text('หมอ / ผู้ดูแล')),
                ],
                selected: {_isAdmin},
                onSelectionChanged: (s) => _switchRole(s.first),
              ),
              const SizedBox(height: 24),
              if (_isAdmin)
                TextField(
                  controller: _doctorId,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                      labelText: 'ไอดีหมอ', border: OutlineInputBorder()),
                )
              else
                TextField(
                  controller: _idCard,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(13),
                  ],
                  decoration: const InputDecoration(
                      labelText: 'เลขบัตรประชาชน',
                      border: OutlineInputBorder()),
                ),
              const SizedBox(height: 12),
              TextField(
                controller: _pass,
                obscureText: true,
                onSubmitted: (_) => _loading ? null : _submit(),
                decoration: const InputDecoration(
                    labelText: 'รหัสผ่าน', border: OutlineInputBorder()),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(_error!,
                      style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(title),
                ),
              ),
              if (!_isAdmin)
                TextButton(
                  onPressed: _loading ? null : _openRegister,
                  child: const Text('ยังไม่มีบัญชี? สมัครสมาชิก'),
                ),
            ]),
          ),
        ),
      ),
    );
  }
}