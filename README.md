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

このソフトウェアの問題点と解決方法
1. 敷地を跨いでしまうor途中区間が途切れてしまう問題
_getRouteCoordinatesメソッドの引数と、その引数を用いて入手した経路の詳細情報（JSON)を調査した。
すると、引数に指定した始点と終点地点の緯度と経度が、JSONのものと異なっていた。
ユーザーが、1kmを指定したとする。メソッドは、現在地からランダムな方向に200m進んだ点を指す。
そこから、90度の角度で再度200m先の点を指すということを繰り返す。そのため、指す点が建物や、通れない道となる場合がでてくる。
指した点が、GCPが経路計算に使用可能な場所（道）とずれていると修正しようとすると推論したため、
それを防ぐために、2回目からは、一つ前のGCPから得られたJSON内の目標地点を次の始点として経路を生成するようにする。
→JSONのn-1の目標地点をnの始点にすることにより、経路がつながり、敷地をまたぐことや、区間ごとにとぎれなくなった。

2. 生成速度が少し遅い問題
3. 生成後も現在地中心の画面のまま
4. modalseet.dartで次のエラーが出ている原因"Don't use 'BuildContext's across async gaps, guarded by an unrelated 'mounted' check."
   https://dart.dev/tools/linter-rules/use_build_context_synchronously
次のコードを付け足すことで回避した
   if (!context.mounted) return;
5. 簡易画面表示を作っていない
6. 設定画面いるかいらないか
7. 機能が少ない点（霧とかを追加したらどう？）