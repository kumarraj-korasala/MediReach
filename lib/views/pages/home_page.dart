import 'package:flutter/material.dart';
import 'package:miracle/data/constants.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsGeometry.all(22.0),
      child: Column(
        children: [
          Divider(thickness: 0),
          Text('HOMEPAGE'),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 2.0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(15.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'This is a card',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 20,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    Text(
                      'can store the text and so on',
                      style: C_textstyle.titleText, //these are created by me the code is in the constants.dart file
                    ),
                    Text(
                      'Give a try for it',
                      style: C_textstyle.descriptionText,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
