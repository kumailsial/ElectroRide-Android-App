import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'login_page.dart';
import 'home_page.dart';
import 'Signup_page.dart';
import 'splash_page.dart';


final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();


  await Supabase.initialize(
    url: 'https://dmymjkihevuoobgdofbg.supabase.co',
    anonKey:
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRteW1qa2loZXZ1b29iZ2RvZmJnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjUyNzg5NDEsImV4cCI6MjA4MDg1NDk0MX0.RCRFFeV7Z7EccYG0xJ37WOmfNQ80zyYgI6xjvRteGs0',
  );


  const AndroidInitializationSettings androidInit =
  AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initSettings =
  InitializationSettings(android: androidInit);

  await flutterLocalNotificationsPlugin.initialize(initSettings);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,


      home: const SplashScreen(),


      routes: {
        '/login': (context) => login_page(),
        '/home': (context) => home_page(),
        '/signup': (context) => const Signup_page(),
      },
    );
  }
}
