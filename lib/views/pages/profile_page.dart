import 'package:flutter/material.dart';
import 'package:miracle/views/pages/welcome_page.dart';

import '../../data/notifiers.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(30.0),

          // Main vertical layout
          child: Column(
            children: [
              // ==========================================
              // PROFILE SECTION - NOT SCROLLABLE
              // ==========================================

              const CircleAvatar(
                radius: 70,
                backgroundImage: NetworkImage(
                  'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRBLSmCTD4ER6KS6-iOSfXPqzsx9m83z-h5SXsus0iHvA&s=10',
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                'John Doe',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              const Text(
                'john.doe@gmail.com',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),

              const SizedBox(height: 20),

              // Divider between fixed and scrollable sections
              const Divider(thickness: 1),

              const SizedBox(height: 10),

              // ==========================================
              // SCROLLABLE SECTION
              // ==========================================
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Job
                      const Text(
                        'Job',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),

                      const SizedBox(height: 5),

                      const Text(
                        'Software Developer',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Location
                      const Text(
                        'Location',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),

                      const SizedBox(height: 5),

                      const Text(
                        'Hyderabad, India',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // About
                      const Text(
                        'About Me',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 10),

                      const Text(
                        'I am a software developer interested in '
                        'Flutter and mobile application development. '
                        'I enjoy building beautiful and useful applications.',
                        style: TextStyle(fontSize: 16, height: 1.5),
                      ),

                      const SizedBox(height: 30),

                      // Edit Profile Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            // Edit profile
                          },
                          child: const Text('Edit Profile'),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Logout
                      ListTile(
                        contentPadding: EdgeInsets.zero,

                        title: const Text(
                          'Logout',
                          style: TextStyle(fontSize: 16),
                        ),

                        trailing: IconButton(
                          onPressed: () {
                            selectedPageNotifier.value = 0;

                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const WelcomePage(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.logout),
                        ),
                      ),

                      const SizedBox(height: 30),

                      // ==========================================
                      // EXTRA CONTENT
                      // ==========================================
                      // You can remove this. It is only here
                      // to demonstrate scrolling.
                      const Text(
                        'Additional Information',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 15),

                      const Text(
                        'This is some additional information '
                        'about the user. You can add whatever '
                        'profile details you want here.',
                        style: TextStyle(fontSize: 16, height: 1.5),
                      ),

                      const SizedBox(height: 30),

                      const Text(
                        'Skills',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 15),

                      const Text(
                        'Flutter\nDart\nFirebase\nUI/UX Design',
                        style: TextStyle(fontSize: 16, height: 1.8),
                      ),

                      const SizedBox(height: 30),

                      const Text(
                        'Experience',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 15),

                      const Text(
                        'Software Developer\n'
                        'Worked on mobile applications using Flutter '
                        'and Dart. Built responsive and user-friendly '
                        'interfaces.',
                        style: TextStyle(fontSize: 16, height: 1.5),
                      ),

                      const SizedBox(height: 50),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
