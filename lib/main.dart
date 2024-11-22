import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/user_provider.dart';
import 'screens/login_screen.dart'; 
import 'services/database_helper.dart'; 
import 'services/mock_data.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MockData().createMockUserData(); // เรียกสร้างข้อมูลจำลองก่อนเริ่มแอปครั้งแรก ครั้งต่อไปก็ลบบรรทัดนี้ออก ไม่ก็//ไว้
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        Provider(create: (_) => DatabaseHelper()), 
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          scaffoldBackgroundColor: const Color(0xFF2C2C2C),
        ),
        home: const LoginScreen(),
      ),
    );
  }
}
