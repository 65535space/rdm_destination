import 'package:flutter/material.dart';

import 'package:rdm_destination/settings.dart';
import 'generate_route_page.dart';
import 'simple_direction.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const HomeApp());
}

class HomeApp extends StatefulWidget {
  const HomeApp({super.key});

  @override
  State<HomeApp> createState() => _HomeAppState();
}

class _HomeAppState extends State<HomeApp> {
  var _currentIndex = 1;

  // 各タブに対応するページウィジェット
  late List<Widget> _pages;

  void _onTap(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    _pages = [
      SettingsHomePage(
        onTap: _onTap,
      ), // 設定画面のホームページ
      GenerateRoutePage(
        onTap: _onTap,
      ), // 生成画面
      const SimpleDirection(), // 切り替え画面
    ];
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(fontFamily: 'NotoSansJP'),
      home: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
    );
  }
}
