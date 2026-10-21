import 'package:flutter/material.dart';
import '../auth/auth_service.dart';
import 'admin_patient_detail_page.dart';

// รายชื่อคนไข้ทั้งหมดสำหรับหมอ ค้นหาด้วยเลขบัตร ชื่อ หรือเบอร์โทร
// กดที่ชื่อเพื่อดูข้อมูลและประวัตินัดของคนไข้
class AdminPatientsPage extends StatefulWidget {
  const AdminPatientsPage({super.key});
  @override
  State<AdminPatientsPage> createState() => _AdminPatientsPageState();
}

class _AdminPatientsPageState extends State<AdminPatientsPage> {
  String _query = '';

  bool _matches(PatientRef p, String q) {
    final s = q.trim().toLowerCase();
    if (s.isEmpty) return true;
    return p.id.contains(s) ||
        p.name.toLowerCase().contains(s) ||
        p.phone.contains(s);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: authService,
      builder: (context, _) {
        final all = authService.patients;
        final list = [
          for (final p in all)
            if (_matches(p, _query)) p
        ];
        return Scaffold(
          appBar: AppBar(title: const Text('ข้อมูลคนไข้')),
          body: Column(children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                onChanged: (v) => setState(() => _query = v),
                decoration: const InputDecoration(
                  hintText: 'ค้นหาเลขบัตรประชาชน / ชื่อ / เบอร์โทร',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            Expanded(
              child: all.isEmpty
                  ? const Center(
                      child: Text('ยังไม่มีคนไข้ในระบบ\nคนไข้ต้องสมัครสมาชิกก่อน',
                          textAlign: TextAlign.center))
                  : list.isEmpty
                      ? const Center(child: Text('ไม่พบคนไข้ที่ตรงกับที่พิมพ์'))
                      : ListView.builder(
                          itemCount: list.length,
                          itemBuilder: (_, i) {
                            final p = list[i];
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              child: ListTile(
                                leading: const CircleAvatar(
                                    child: Icon(Icons.person)),
                                title: Text(p.name),
                                subtitle: Text(
                                    'โทร ${p.phone}  •  อายุ ${p.age} ปี'
                                    '${p.disease.isEmpty ? '' : '\nโรค: ${p.disease}'}'),
                                isThreeLine: p.disease.isNotEmpty,
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => AdminPatientDetailPage(
                                            idCard: p.id))),
                              ),
                            );
                          },
                        ),
            ),
          ]),
        );
      },
    );
  }
}