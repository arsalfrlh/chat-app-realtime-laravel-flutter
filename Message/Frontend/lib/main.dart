import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toko/pages/home_page.dart';
import 'package:toko/pages/login_page.dart';

void main()async{
  WidgetsFlutterBinding.ensureInitialized();
  final key = await SharedPreferences.getInstance();
  bool status = key.getBool("statusLogin") ?? false;
  runApp(MyApp(status: status,));
}

class MyApp extends StatelessWidget {
  MyApp({required this.status});
  bool status;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Gemini",
      home: status ? HomePage() : LoginPage(),
    );
  }
}

// ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response['pesan']), backgroundColor: Colors.green,));
// http://10.0.2.2:8000/api
// {'Content-Type': 'application/json'}
// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return const Placeholder();
//   }
// }