import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // 1. Import Firebase Core
import 'package:trisikol_admin/adminlogin.dart';
import 'package:trisikol_admin/dashboard/admin_dashboard.dart';
import 'package:trisikol_admin/pages/admin_dashboard_home.dart';

void main() async {
  // 2. Ensure Flutter is initialized before Firebase
  WidgetsFlutterBinding.ensureInitialized();

  // 3. Initialize Firebase with your specific credentials
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyCLYuHMcjteQC4qMhn8t61lP6EcOfGnEY0",
      appId: "1:914212181060:web:da99ea2eb117b532701811",
      messagingSenderId: "914212181060",
      projectId: "triconnect-651ed",
      databaseURL: "https://triconnect-651ed-default-rtdb.firebaseio.com",
      storageBucket: "triconnect-651ed.firebasestorage.app",
      measurementId: "G-DLFTDB49TK",
    ),
  );

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AdminLoginPage(),
    );
  }
}
