import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ModalSheet extends StatefulWidget {
  const ModalSheet({super.key});

  @override
  State<ModalSheet> createState() => _ModalSheetState();
}

class _ModalSheetState extends State<ModalSheet> {
  final TextEditingController _controller = TextEditingController();
  String _inputValue = '';

  @override
  void dispose() {
    // 画面が破棄されるときにコントローラを解放
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: double.infinity,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8, // 高さを調整
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(10),
          topRight: Radius.circular(10),
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    side:
                        const BorderSide(color: Color(0xFFBDBDBD), width: 2.0),
                    fixedSize: const Size(80, 60),
                  ),
                  child: const Text(
                    "+100",
                    style: TextStyle(color: Color(0xFF000000), fontSize: 18),
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    side:
                        const BorderSide(color: Color(0xFFBDBDBD), width: 2.0),
                    fixedSize: const Size(80, 60),
                  ),
                  child: const Text(
                    "+200",
                    style: TextStyle(color: Color(0xFF000000), fontSize: 18),
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    side:
                        const BorderSide(color: Color(0xFFBDBDBD), width: 2.0),
                    fixedSize: const Size(80, 60),
                  ),
                  child: const Text(
                    "+300",
                    style: TextStyle(color: Color(0xFF000000), fontSize: 18),
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: 24),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    side:
                        const BorderSide(color: Color(0xFFBDBDBD), width: 2.0),
                    fixedSize: const Size(80, 60),
                  ),
                  child: const Text(
                    "+500",
                    style: TextStyle(color: Color(0xFF000000), fontSize: 18),
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    side:
                        const BorderSide(color: Color(0xFFBDBDBD), width: 2.0),
                    fixedSize: const Size(80, 60),
                  ),
                  child: const Text(
                    "+800",
                    style: TextStyle(color: Color(0xFF000000), fontSize: 18),
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    side:
                        const BorderSide(color: Color(0xFFBDBDBD), width: 2.0),
                    fixedSize: const Size(80, 60),
                  ),
                  child: const Text(
                    "+1300",
                    style: TextStyle(color: Color(0xFF000000), fontSize: 18),
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: 50),
            ),
            SizedBox(
              width: MediaQuery.of(context).size.width * 2 / 3,
              child: TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  suffixText: 'm',
                  border: OutlineInputBorder(),
                  labelText: '生成する距離',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly,
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: 50),
            ),
            Material(
              elevation: 8,
              shape: const CircleBorder(),
              child: InkWell(
                borderRadius: BorderRadius.circular(83),
                // タッチ領域を丸く設定
                onTap: () {
                  debugPrint("丸い画像がタップされました");
                  setState(() {
                    _inputValue = _controller.text;
                  });
                },
                child: ClipOval(
                  child: Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    width: 166, // コンテナの幅を設定
                    height: 166, // コンテナの高さを設定
                    child: Transform.scale(
                      scale: 0.6, // 画像を縮小（80%）
                      child: Image.asset(
                        'assets/images/appIcon.png',
                        fit: BoxFit.contain, // アスペクト比を保ちながら収める
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
