import 'package:flutter/material.dart';

class BottomBar extends StatefulWidget {
  final Function(int) onTap;

  const BottomBar({super.key, required this.onTap});

  @override
  State<BottomBar> createState() => _BottomBarState();
}

class _BottomBarState extends State<BottomBar> {
  int _currentIndex = 1;

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      // 選択中のアイテムindex
      currentIndex: _currentIndex,
      // タップ時のハンドラ
      onTap: (selectedIndex) {
        setState(() {
          _currentIndex = selectedIndex;
        });
        switch (_currentIndex) {
          case 0:
            widget.onTap(0);
            break;
          case 1:
            widget.onTap(1);
            break;
          case 2:
            widget.onTap(2);
        }
      },
      // ページ下部に表示するアイテム
      items: const [
        // labelは必須プロパティ
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: "設定"),
        BottomNavigationBarItem(icon: Icon(Icons.directions_walk), label: "生成"),
        BottomNavigationBarItem(icon: Icon(Icons.cached), label: "切り替え"),
      ],
    );
  }
}
