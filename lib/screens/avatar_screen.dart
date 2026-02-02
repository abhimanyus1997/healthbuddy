import 'package:flutter/material.dart';
import 'package:fluttermoji/fluttermoji.dart';

class AvatarScreen extends StatelessWidget {
  const AvatarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Customize Avatar")),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: FluttermojiCircleAvatar(
                  radius: 80,
                  backgroundColor: Colors.grey[200],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: FluttermojiCustomizer(
                  scaffoldHeight: 400,
                  scaffoldWidth: MediaQuery.of(context).size.width * 0.9,
                  autosave: true,
                  theme: FluttermojiThemeData(
                    boxDecoration: const BoxDecoration(
                      boxShadow: [BoxShadow(color: Colors.transparent)],
                    ),
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
