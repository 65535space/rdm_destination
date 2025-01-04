import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'secret.dart';

class ModalSheet extends StatefulWidget {
  final Set<Marker> markers;
  final Set<Polyline> polylines;

  const ModalSheet({super.key, required this.markers, required this.polylines});

  @override
  State<ModalSheet> createState() => _ModalSheetState();
}

class _ModalSheetState extends State<ModalSheet> {
  final Completer<GoogleMapController> _controller = Completer();
  LatLng? _currentPosition;
  final bool _isTracking = false; // 経路情報を保存するかどうかを決める変数
  bool _followUser = false; // FloatingActionButtonを押した際に、追跡するようにするため
  CameraPosition? _initialCameraPosition;
  final List<LatLng> _routePoints = []; // 霧機能のために通った経路を格納する
  List<LatLng> _allPoints = [];
  // List<LatLng> _sortedDestinations = [];
  final List<PolylineWayPoint> _waypoints = [];
  final TextEditingController _textEditingController = TextEditingController();
  int? _inputValue;
  LatLng startPoint = const LatLng(0, 0);
  LatLng nextStartPoint = const LatLng(0, 0);

  Future<void> _getCurrentPosition() async {
    debugPrint("_getCurrentPosition was called");
    bool serviceEnabled;
    // LocationPermission permission;

    // 開発側が位置情報サービスを使えているのか確認するフェーズ
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('位置情報サービスが無効です。');
      return;
    }

    LocationSettings locationSettings = const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 1,
    );

    // 現在地を1回だけ取得して _currentPosition に設定（この処理が完了するまで待機）
    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: locationSettings,
      );

      // 現在地が取得できたら _currentPosition を設定
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
      });

      debugPrint(
          "_getCurrentPosition: _currentPosition is set to $_currentPosition");
    } catch (e) {
      debugPrint("Failed to get current position: $e");
    }

    // 位置情報の更新時、カメラを現在地に動かし、現在地を保存
    Geolocator.getPositionStream(locationSettings: locationSettings)
        .listen((Position position) {
      debugPrint("getPositionStream was called");
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        if (_isTracking) {
          _routePoints.add(_currentPosition!);
        }
        _initialCameraPosition ??= CameraPosition(
          target: _currentPosition!,
          zoom: 16.0,
        );
        if (_followUser && _controller.isCompleted) {
          _moveCameraToCurrentPosition();
        }
      });
    });
  }

  // 現在地にカメラを移動するメソッド
  Future<void> _moveCameraToCurrentPosition() async {
    debugPrint("Move Camera: Start");
    if (_currentPosition != null) {
      final GoogleMapController mapController = await _controller.future;
      await mapController.animateCamera(
        CameraUpdate.newLatLngZoom(_currentPosition!, 16.0), // 現在地にカメラを移動
      );
      setState(() {
        _followUser = true;
      });
    } else {
      debugPrint('現在地が取得されていません');
    }
  }

  /// ランダムな距離と方角に基づいて中継地点の座標を計算するメソッド

  /// 現在地から半径1km (±100m) の範囲にランダムに5個の中継地点を生成するメソッド
  Future<void> _generateRandomRelayPoints() async {
    debugPrint("_generateRandomRelayPoints was called");
    debugPrint("inputValue is $_inputValue");

    // LocationSettingsを設定する（desiredAccuracyは使わない)
    LocationSettings locationSettings = const LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 0, // 0に設定することで、すべての位置情報を取得
    );

    LatLng positionToLatLng(Position position) {
      return LatLng(position.latitude, position.longitude);
    }

    // 現在の位置を取得
    Position currentPosition =
        await Geolocator.getCurrentPosition(locationSettings: locationSettings);
    LatLng currentLatLng = positionToLatLng(currentPosition);
    debugPrint("currentLatLng: $currentLatLng");

    // 中継地点を格納するリスト
    List<LatLng> relayPoints = [];
    // LatLng? newPoint;
    double? firstRandomAngle;
    double fromSecondAngle;
    DateTime? startTime; // ボタン押下時刻
    DateTime? endTime; // 経路表示完了時刻

    setState(() {
        startTime = DateTime.now();
    });

    // 中継地点を4個作成
    for (int i = 0; i < 5; i++) {
      debugPrint("Loop times: $i");

      double randomDistance = _inputValue! * 0.2 -
          _inputValue! * 0.05 +
          Random().nextDouble() * _inputValue! * 0.1;
      debugPrint("randomDistance = $randomDistance");

      //第一案：Angleが全て最初の位置から見て何度かになってる
      
      // 指定された距離と方角から目的地を生成
      // 20%の距離を5回に分けて中継地点を決める
      // 一回目に決めた角度から+ー45度の範囲を探索することで同じ道を通ることを回避する
      // 現在地からランダムな距離と方角で中継地点を計算
      if (i == 0) {
        firstRandomAngle = Random().nextDouble() * 360; // 0～360度
        // newPoint = _calculateRelayPoint(currentPosition.latitude,
        //     currentPosition.longitude, randomDistance, firstRandomAngle);

        // この後にURLを取得する
        debugPrint("159: currentLatLng.latitude: ${currentLatLng.latitude} currentLatLng.longitude: ${currentLatLng.longitude}");
        debugPrint("160: randomDistance: $randomDistance firstRandomAngle: $firstRandomAngle");

        LatLng destination = _calculateRelayPoint(currentLatLng.latitude, currentLatLng.longitude, randomDistance, firstRandomAngle);
        relayPoints.add(destination);
        debugPrint("destination is $destination");

        //1回目は捨てる(位置調整のため）
        String url = 'https://maps.googleapis.com/maps/api/directions/json?origin=${currentLatLng.latitude},${currentLatLng.longitude}&destination=${destination.latitude},${destination.longitude}&mode=walking&key=${Secrets.apiKey}';
        await _getRouteCoordinates(url);
        url = 'https://maps.googleapis.com/maps/api/directions/json?origin=${startPoint.latitude},${startPoint.longitude}&destination=${nextStartPoint.latitude},${nextStartPoint.longitude}&mode=walking&key=${Secrets.apiKey}';
        await _getRouteCoordinates(url);
        debugPrint("startPoint: $startPoint");
        debugPrint("nextStartPoint: $nextStartPoint");
      } else {
        fromSecondAngle = (firstRandomAngle! - 45) + Random().nextDouble() * 90;
        firstRandomAngle = fromSecondAngle; //次のfromSecondAngleを計算するために必要
        debugPrint("Angle(fromSecondAngle) is $fromSecondAngle");
        // newPoint = _calculateRelayPoint(newPoint!.latitude, newPoint.longitude,
        //     randomDistance, fromSecondAngle);
        // この後にURLを取得する

        LatLng destination = _calculateRelayPoint(nextStartPoint.latitude, nextStartPoint.longitude, randomDistance, fromSecondAngle);
        debugPrint("182: nextStartPoint.latitude: ${nextStartPoint.latitude} nextStartPoint.longitude: ${nextStartPoint.longitude}");
        debugPrint("183: destination is $destination");

        relayPoints.add(destination);
        String url = 'https://maps.googleapis.com/maps/api/directions/json?origin=${nextStartPoint.latitude},${nextStartPoint.longitude}&destination=${destination.latitude},${destination.longitude}&mode=walking&key=${Secrets.apiKey}';
        debugPrint("startPoint(2回目以降なのでnullかどうかどうかだけチェック): $startPoint");
        debugPrint("nextStartPoint: $nextStartPoint");
        await _getRouteCoordinates(url);
      }

      // 中継地点をリストに追加
      // relayPoints.add(newPoint);
    }

    setState(() {
      _allPoints = [currentLatLng, ...relayPoints];
      for (var i = 0; i < _allPoints.length; i++) {
        _waypoints.add(PolylineWayPoint(
          location:
              "${_allPoints[i].latitude},${_allPoints[i].longitude}",
        ));
      }
      debugPrint("_another Destinations is $_waypoints");
    });

    setState(() {
      endTime = DateTime.now();
    });
    // 結果を表示
    if (startTime != null && endTime != null) {
      Duration elapsed = endTime!.difference(startTime!);
      debugPrint('経路表示までの時間: ${elapsed.inMilliseconds} ms');
    }
  }


  LatLng _calculateRelayPoint(double baseLat, double baseLon, double distanceInMeters, double bearing) {
    const double earthRadius = 6371000; // 地球の半径（メートル）

    // ラジアン単位に変換
    double bearingRad = bearing * pi / 180;
    double latRad = baseLat * pi / 180;
    double lonRad = baseLon * pi / 180;

    // 距離を地球の半径で割り、ラジアンに変換
    double distanceRatio = distanceInMeters / earthRadius;

    // 中継地点の緯度を計算
    double newLatRad = asin(sin(latRad) * cos(distanceRatio) +
        cos(latRad) * sin(distanceRatio) * cos(bearingRad));

    // 中継地点の経度を計算
    double newLonRad = lonRad +
        atan2(sin(bearingRad) * sin(distanceRatio) * cos(latRad),
            cos(distanceRatio) - sin(latRad) * sin(newLatRad));

    // ラジアンを度に戻して、新しい座標を生成
    double newLat = newLatRad * 180 / pi;
    double newLon = newLonRad * 180 / pi;

    // LatLngオブジェクトを返す
    return LatLng(newLat, newLon);
  }

  // void _sortDestinations() {
  //   debugPrint("_sortDestinations was called");
  //   if (_currentPosition == null) {
  //     debugPrint("_currentPosition == null:214");
  //     return;
  //   }
  //
  //   _sortedDestinations = List.from(_allPoints);
  //   //距離を昇順に並べ替える？
  //   _sortedDestinations.sort((a, b) {
  //     double distA = _calculateDistance(_currentPosition!, a);
  //     double distB = _calculateDistance(_currentPosition!, b);
  //     // (distA < distB)
  //     return distA.compareTo(distB);
  //   });
  // }


  Future<void> _getOptimizedRoute() async {
    debugPrint("_getOptimizedRoute was called");
    //元は
    // if (_currentPosition == null || _sortedDestinations.isEmpty) return;
    if (_currentPosition == null) return;

    // List<LatLng> waypoints = [..._sortedDestinations];
    // debugPrint("waypoints is $waypoints");
    // for (int i = 0; i < waypoints.length - 1; i++) {
    //   await _getRouteCoordinates(waypoints[i], waypoints[i + 1]);
    // }

    setState(() {
      // 最後の目的地にマーカーを追加
      widget.markers.add(Marker(
        markerId: const MarkerId('destination'),
        //元 position: _sortedDestinations.last,
        position: _allPoints.last,
      ));
    });
  }


  // double _calculateDistance(LatLng start, LatLng end) {
  //   // ハバーサインの公式を用いた場合の2点間の距離
  //   debugPrint("_calculateDistance was called");
  //   var p = 0.017453292519943295;
  //   var c = cos;
  //   var a = 0.5 -
  //       c((end.latitude - start.latitude) * p) / 2 +
  //       c(start.latitude * p) *
  //           c(end.latitude * p) *
  //           (1 - c((end.longitude - start.longitude) * p)) /
  //           2;
  //   return 12742 * asin(sqrt(a));
  // }


  // 目的地までの経路を登録と次の始点と終点を格納
  Future<void> _getRouteCoordinates(String url) async {
    debugPrint("_getRouteCoordinates was called");

    //指定するスタートと目標地点の確認
    // debugPrint("startLatLng: $start");
    // debugPrint("destinationLatLng: $destination");
    //
    // String url =
    //     'https://maps.googleapis.com/maps/api/directions/json?origin=${start.latitude},${start.longitude}&destination=${destination.latitude},${destination.longitude}&mode=walking&key=${Secrets.apiKey}';

    try {
      var response = await http.get(Uri.parse(url));
      debugPrint('API Request URL: $url');
      if (response.statusCode == 200) {
        debugPrint("StatusCode is 200 !!");
        Map<String, dynamic> result = json.decode(response.body);
        debugPrint('Keys in result: ${result.keys}'); // すべてのキーを出力

        if (result['routes'].isNotEmpty) {
          debugPrint("result['routes'] is not Empty");
          String points = result['routes'][0]['overview_polyline']['points'];

          //一回目の始点を調整するため
          if(startPoint == const LatLng(0,0)) {
            try {
              double latitude = result['routes'][0]['legs'][0]['start_location']['lat'];
              double longitude = result['routes'][0]['legs'][0]['start_location']['lng'];
              debugPrint("JSON latitude: $latitude ,longitude: $longitude");
              startPoint = LatLng(latitude, longitude);
              nextStartPoint = LatLng(result['routes'][0]['legs'][0]['end_location']['lat'], result['routes'][0]['legs'][0]['end_location']['lng']);
              debugPrint('LatLng: (${startPoint.latitude}, ${startPoint.longitude})');
              return;
            } catch (e) {
              debugPrint('Invalid input (startPoint): $e');
            }
          }

          //二回目からの始点を調整するため
          try {
            double latitude = result['routes'][0]['legs'][0]['end_location']['lat'];
            double longitude = result['routes'][0]['legs'][0]['end_location']['lng'];
            debugPrint("latitude: $latitude ,longitude: $longitude");
            nextStartPoint = LatLng(latitude, longitude);
            debugPrint('LatLng: (${nextStartPoint.latitude}, ${nextStartPoint.longitude})');
          } catch (e) {
            debugPrint('Invalid input (nextStartPoint): $e');
          }
          debugPrint("341 startPoint: $startPoint");
          debugPrint("342 nextStartPoint: $nextStartPoint");
          debugPrint("points is $points");

          List<LatLng> routeCoords = PolylinePoints()
              .decodePolyline(points)
              .map(
                (point) => LatLng(point.latitude, point.longitude),
              )
              .toList();

          setState(() {
            widget.polylines.add(Polyline(
              polylineId: PolylineId('${result['routes'][0]['legs'][0]['start_location']['lat']},${result['routes'][0]['legs'][0]['start_location']['lng']}'),
              color: Colors.blue,
              points: routeCoords,
              width: 5,
            ));
          });
          // _polylines の内容をデバッグ出力する
          debugPrint('Polyline Count: ${widget.polylines.length}');
          debugPrint("362 startPoint: $startPoint");
          debugPrint("363 nextStartPoint: $nextStartPoint");
        }
      } else {
        debugPrint("Error fetching directions: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error fetching directions: $e");
    }
  }

  @override
  void dispose() {
    // 画面が破棄されるときにコントローラを解放
    _textEditingController.dispose();
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
                controller: _textEditingController,
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
                onTap: () async {
                  debugPrint("丸い画像がタップされました");
                  try {
                    setState(() {
                      try {
                        // 入力されたテキストを int 型に変換
                        _inputValue = int.parse(_textEditingController.text);
                        debugPrint('変換に成功しました: $_inputValue');
                      } catch (e) {
                        // 例外が発生した場合の処理
                        _inputValue = 0; // デフォルト値として 0 を設定する
                        debugPrint('入力値が数値ではありません。inputValue = $_inputValue');
                        debugPrint('int変換の例外発生: ${e.toString()}');
                      }
                    });
                    await _getCurrentPosition();
                    if (_currentPosition != null) {
                      await _generateRandomRelayPoints();
                      // _sortDestinations();
                      await _getOptimizedRoute();

                      if (!context.mounted) return;
                      Navigator.pop(context, {
                        'polyline': widget.polylines,
                        'marker': widget.markers,
                      });
                    } else {
                      debugPrint("_currentPosition == null:462");
                    }
                  } catch (e) {
                    debugPrint('例外発生: ${e.toString()}');
                  }
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
