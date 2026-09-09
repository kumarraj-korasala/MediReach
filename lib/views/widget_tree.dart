import 'package:flutter/material.dart';
import 'package:miracle/data/notifiers.dart';
import 'package:miracle/views/pages/home_page.dart';
import 'package:miracle/views/pages/profile_page.dart';
import 'package:miracle/views/pages/settings_page.dart';
import 'package:miracle/views/pages/videocall_page.dart';
import 'package:miracle/views/widgets/navbar.dart';

List<Widget> pages = [HomePage(), ProfilePage(), VideoCallPage()];

class witree extends StatelessWidget {
  const witree({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Medicare"),
        actions: [
          IconButton(
            onPressed: () {
              darkMode.value = !darkMode.value;
            },
            icon: ValueListenableBuilder(
              valueListenable: darkMode,
              builder: (context, darkMode, child) {
                return Icon(darkMode ? Icons.dark_mode : Icons.light_mode);
              },
            ),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return SettingsPage(title: 'Settings');
                  },
                ),
              );
            },
            icon: Icon(Icons.settings),
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: selectedPageNotifier,
        builder: (context, value, child) {
          return pages.elementAt(value);
        },
      ),
      bottomNavigationBar: Navbar(),
    );
  }
}
