import 'package:flutter/material.dart';
import 'package:miracle/data/notifiers.dart';

class Navbar extends StatelessWidget {
  const Navbar({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: selectedPageNotifier,
      builder: (context, selectedValue, child) {
        return NavigationBar(
          destinations: [
            NavigationDestination(icon: Icon(Icons.home), label: "HOME"),
            NavigationDestination(icon: Icon(Icons.person), label: "PROFILE"),
            NavigationDestination(
              icon: Icon(Icons.video_call),
              label: "VideoCall",
            ),
          ],
          onDestinationSelected: (int value) {
            selectedPageNotifier.value = value;
          },
          selectedIndex: selectedValue,
        );
      },
    );
  }
}
