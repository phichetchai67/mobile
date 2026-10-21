import 'package:flutter/material.dart';
import 'booking/my_bookings_page.dart';
import 'booking/booking_service.dart';
import 'patient/profile_page.dart';
import 'auth/auth_service.dart';
import 'auth/login_page.dart';
import 'admin/admin_home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await authService.load(); // อ่านบัญชีที่เคยสมัครไว้ก่อนเริ่มแอป
  await bookingService.load(); // อ่านนัดที่เคยจองไว้
  runApp(const MassageApp());
}

class MassageApp extends StatelessWidget {
  const MassageApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'จองคิวนวด',
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      home: ListenableBuilder(
        listenable: authService,
        builder: (_, __) {
          if (!authService.isLoggedIn) return const LoginPage();
          final doctor = authService.currentDoctor;
          if (doctor != null) return AdminHomePage(doctor: doctor);
          return const HomePage();
        },
      ),
    );
  }
}

// หน้าหลักของคนไข้ ดูนัดหมายกับข้อมูลของตัวเอง
class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;
  final _pages = const [MyBookingsPage(), ProfilePage()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.event), label: 'นัดหมายของฉัน'),
          NavigationDestination(icon: Icon(Icons.person), label: 'ข้อมูลของฉัน'),
        ],
      ),
    );
  }
}