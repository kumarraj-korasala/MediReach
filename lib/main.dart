import 'package:flutter/material.dart';
import 'package:miracle/core/remote/api_client.dart';
import 'package:miracle/core/session/session_manager.dart';
import 'package:miracle/data/notifiers.dart';
import 'package:miracle/views/pages/welcome_page.dart';
import 'package:miracle/views/widget_tree.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiClient.instance.init();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: darkMode,
      builder: (context, darkMode, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.teal,
              brightness: darkMode ? Brightness.dark : Brightness.light,
            ),
          ),
          home: FutureBuilder<bool>(
            future: SessionManager.instance.isLoggedIn(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator(color: Colors.teal)),
                );
              }
              if (snapshot.data == true) {
                return const witree();
              }
              return const WelcomePage();
            },
          ),
        );
      },
    );
  }
}

