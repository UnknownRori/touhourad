import 'package:flutter/material.dart';
import 'package:touhourad/page/musicplayer.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TouhouRad',
      theme: ThemeData.dark(),
      home: const MusicPlayer(),
    );
  }
}
