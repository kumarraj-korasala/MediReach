import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.title});
  final String title;
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  TextEditingController inputText = TextEditingController();
  bool? check = false;
  bool switcho = false;
  double Svalues = 0.00;
  String? menuitem = '3';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        centerTitle: true,
        leading: BackButton(
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(55.0),
          child: Column(
            spacing: 10,
            children: [
              ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Snackbar'),
                      duration: Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child: Text('snackbar'),
              ),
              Divider(color: Colors.white, thickness: 2.0),
              Container(
                height: 50.0,

                child: VerticalDivider(color: Colors.white, thickness: 1.0),
              ),
              ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: Text('text alert'),
                        content: Text('content for the text'),
                        actions: [
                          FilledButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: Text('close'),
                          ),
                        ],
                      );
                    },
                  );
                },
                child: Text('dialog'),
              ),
              TextField(
                decoration: InputDecoration(border: OutlineInputBorder()),
                controller: inputText,
                onEditingComplete: () => setState(() {}),
              ),
              Text(inputText.text),
              CheckboxListTile(
                tristate: true,
                title: Text("Are you a prgrammer???"),
                activeColor: Colors.pinkAccent,
                tileColor: Colors.lightBlue,
                value: check,
                onChanged: (bool? value) {
                  setState(() {
                    check = value;
                  });
                },
              ),
              SwitchListTile(
                title: Text('is it flutter?'),
                activeThumbColor: Colors.lightBlue,
                value: switcho,
                onChanged: (value) => setState(() {
                  switcho = value;
                }),
              ),
              Slider(
                max: 25.0,
                divisions: 5,
                value: Svalues,

                onChanged: (value) {
                  setState(() {
                    Svalues = value;
                  });
                },
              ),
              Text("$Svalues"),
              Container(
                height: 100.0,
                width: 500.0,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black),
                  borderRadius: BorderRadius.circular(20.0),
                  gradient: RadialGradient(
                    colors: List.filled(30, Colors.black54, growable: true),
                  ),
                ),
                child: Image.asset(
                  'assets/images/Screenshot 2025-05-07 180511.png',
                ),
              ),
              Image.asset(
                'assets/images/automobile-racing-sports-competition.jpg',
              ),
              GestureDetector(
                onTap: () {
                  print("object");
                },
                child: Image.asset(
                  'assets/images/automobile-racing-sports-competition.jpg',
                ),
              ),
              InkWell(
                onTap: () {
                  print("object");
                },
                child: Container(
                  height: 30.0,
                  width: double.infinity,
                  color: Colors.white12,
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  print('clicked');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white24,
                  foregroundColor: Colors.white,
                ),
                child: Text('yo!!!'),
              ),
              ElevatedButton(
                onPressed: () {
                  print('clicked');
                },
                child: Text('yo!!!'),
              ),
              FilledButton(
                onPressed: () {
                  print('clicked');
                },
                child: Text('yo!!!'),
              ),
              TextButton(
                onPressed: () {
                  print('clicked');
                },
                child: Text('yo!!!'),
              ),
              OutlinedButton(onPressed: () {}, child: Text('kumar')),
              CloseButton(),
              BackButton(),
              DropdownButton(
                value: menuitem,
                items: [
                  DropdownMenuItem(value: '1', child: Text('ele1')),
                  DropdownMenuItem(value: '2', child: Text('ele2')),
                  DropdownMenuItem(value: '3', child: Text('ele3')),
                ],
                onChanged: (String? value) {
                  setState(() {
                    menuitem = value;
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
