import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:regexp/pages/regexp.dart';

void main() {
  runApp(const RegexpApp());
}

class RegexpApp extends StatelessWidget {
  const RegexpApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorObservers: [
        BotToastNavigatorObserver(),
      ],
      builder: BotToastInit(),
      home: const RegexpPage(),
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.system,
    );
  }
}
