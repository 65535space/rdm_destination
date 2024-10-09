import 'package:flutter/material.dart';

class SimpleDirection extends StatefulWidget {
  const SimpleDirection({super.key});

  @override
  State<SimpleDirection> createState() => _SimpleDirectionState();
}

class _SimpleDirectionState extends State<SimpleDirection> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('簡易指示方向'),
      ),
      body: Container(
        color: Colors.red,
      ),
    );
  }
}
