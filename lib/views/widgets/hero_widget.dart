import 'package:flutter/material.dart';

class HeroWidget extends StatefulWidget {
  const HeroWidget({super.key, required this.title});

  final String title;

  @override
  State<HeroWidget> createState() => _HeroWidgetState();
}

class _HeroWidgetState extends State<HeroWidget> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Hero(
          tag: 'ima',
          child: ClipRRect(
            borderRadius: BorderRadiusGeometry.circular(33),
            child: Image.asset(
              'assets/images/automobile-racing-sports-competition.jpg',
            ),
          ),
        ),
        Text(
          widget.title,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 9,
            fontSize: 40,
          ),
        ),
      ],
    );
  }
}
