import 'package:flutter/material.dart';
import 'package:regexp/pages/regexp.dart';

void main() {
  runApp(const RegexpApp());
}

class RegexpApp extends StatelessWidget {
  const RegexpApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: RegexpPage(),
    );
  }
}