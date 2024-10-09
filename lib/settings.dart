import 'package:flutter/material.dart';
import 'package:rdm_destination/bottom_bar.dart';

class SettingsHomePage extends StatefulWidget {
  final Function(int) onTap;

  const SettingsHomePage({super.key, required this.onTap});

  @override
  SettingsHomePageState createState() => SettingsHomePageState();
}

class SettingsHomePageState extends State<SettingsHomePage> {
  bool _isNotificationEnabled = true;
  bool _isDarkMode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("設定"),
      ),
      body: ListView(
        children: [
          // プロフィールセクション
          _buildProfileSection(),

          // アカウント設定セクション
          _buildSectionHeader("アカウント設定"),
          ListTile(
            leading: const Icon(Icons.lock),
            title: const Text("パスワードの変更"),
            onTap: () {
              // パスワード変更画面へ遷移する処理を実装
            },
          ),
          ListTile(
            leading: const Icon(Icons.email),
            title: const Text("メールアドレスの変更"),
            onTap: () {
              // メールアドレス変更画面へ遷移する処理を実装
            },
          ),

          // 通知設定セクション
          _buildSectionHeader("通知設定"),
          SwitchListTile(
            title: const Text("通知を有効にする"),
            secondary: const Icon(Icons.notifications),
            value: _isNotificationEnabled,
            onChanged: (bool value) {
              setState(() {
                _isNotificationEnabled = value;
              });
            },
          ),

          // アプリ設定セクション
          _buildSectionHeader("アプリ設定"),
          SwitchListTile(
            title: const Text("ダークモード"),
            secondary: const Icon(Icons.brightness_6),
            value: _isDarkMode,
            onChanged: (bool value) {
              setState(() {
                _isDarkMode = value;
              });
            },
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text("言語設定"),
            onTap: () {
              // 言語設定画面へ遷移する処理を実装
            },
          ),

          // その他セクション
          _buildSectionHeader("その他"),
          ListTile(
            leading: const Icon(Icons.support),
            title: const Text("サポート・お問い合わせ"),
            onTap: () {
              // サポート画面へ遷移する処理を実装
            },
          ),
          ListTile(
            leading: const Icon(Icons.article),
            title: const Text("利用規約"),
            onTap: () {
              // 利用規約ページへ遷移する処理を実装
            },
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: const Text("プライバシーポリシー"),
            onTap: () {
              // プライバシーポリシーページへ遷移する処理を実装
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text("ログアウト"),
            onTap: () {
              // ログアウトの処理を実装
            },
          ),
        ],
      ),
      bottomNavigationBar: BottomBar(onTap: widget.onTap),
    );
  }

  // プロフィールセクション
  Widget _buildProfileSection() {
    return Container(
      color: Colors.blueAccent,
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundImage: AssetImage('assets/profile_placeholder.png'),
          radius: 30.0,
        ),
        title: const Text(
          "ユーザー名",
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
        subtitle: const Text(
          "user@example.com",
          style: TextStyle(color: Colors.white70),
        ),
        trailing: const Icon(Icons.edit, color: Colors.white),
        onTap: () {
          // プロフィール編集画面への遷移を実装
        },
      ),
    );
  }

  // セクションのヘッダーを作成するウィジェット
  Widget _buildSectionHeader(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      color: Colors.grey[200],
      child: Text(
        title,
        style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
      ),
    );
  }
}
