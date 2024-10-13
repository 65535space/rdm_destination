# rdm_map

目標:ランダムな目的地、経路を生成するアプリを作る

Completerウィジェットについて
要約：非同期処理をオブジェクト指向的に扱うことができる
ポイントや利点

1. Future の生成と完了を別々に管理できる
2. 成功と失敗の両方のケースを明示的に扱える

handle：処理する、扱う

.listen についてStreamを勉強した

_calculateDistanceメソッド
このメソッドは、2つの地点（startとend）間の直線距離を計算します。
ここで使われているのは「ハバースィンの公式」で、
これは地球上の2点間の大円距離（最短距離）を計算するために用いられます。
地球は球体に近い形状をしているため、この公式は地球表面での距離計算に適しています。

"..."演算子->リストを全要素を展開する
decodeとは->解読する
json.decode->Json形式からMapへ変換

位置情報を使用するか確認する場合は以下のコードを追加
//位置情報のパーミッションを確認するフェーズ
// permission = await Geolocator.checkPermission();
// if (permission == LocationPermission.denied) {
// //denied=拒否
// permission = await Geolocator.requestPermission();
// if (permission == LocationPermission.denied) {
// debugPrint('位置情報の権限が拒否されました。');
// return;
// }
// }
// if (permission == LocationPermission.deniedForever) {
// debugPrint('位置情報の権限が永続的に拒否されています。');
// return;
// }
