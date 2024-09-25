import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: Home());
  }
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  HomeState createState() => HomeState();
}

class HomeState extends State<Home> {
  final Completer<GoogleMapController> _controller = Completer();
  LatLng? _currentPosition;

  // late CameraPosition _currentCameraPosition;
  CameraPosition? _initialCameraPosition;
  double _direction = 0;
  final bool _isTracking = false; // 経路情報を保存するかどうかを決める変数
  final List<LatLng> _routePoints = [];
  bool _followUser = false; // カメラがユーザーを追跡するか決める変数
  final List<LatLng> _clearingTheFogPaths = []; //　ユーザーが通った経路情報を格納する

  @override
  void initState() {
    super.initState();
    _getCurrentPosition();
    FlutterCompass.events!.listen((event) {
      if (event.heading != null) {
        setState(() {
          _direction = event.heading!;
        });
      } else {
        setState(() {
          _direction = event.heading ?? 0.0;
        });
        debugPrint('方位を取得できませんでした');
      }
    });
  }

  Future<void> _getCurrentPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 開発側が位置情報サービスを使えているのか確認するフェーズ
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('位置情報サービスが無効です。');
      return;
    }

    //位置情報のパーミッションを確認するフェーズ
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      //denied=拒否
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('位置情報の権限が拒否されました。');
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      debugPrint('位置情報の権限が永続的に拒否されています。');
      return;
    }

    LocationSettings locationSettings = const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 1,
    );

    Geolocator.getPositionStream(locationSettings: locationSettings)
        .listen((Position position) {
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        if (_isTracking) {
          _routePoints.add(_currentPosition!);
        }
        _initialCameraPosition ??= CameraPosition(
          target: _currentPosition!,
          zoom: 16.0,
        );
        // ユーザーの位置を追跡する場合のみカメラを移動
        if (_followUser && _controller.isCompleted) {
          _moveCameraToCurrentPosition();
        }
      });
    });
  }

  // 現在地にカメラを移動するメソッド
  Future<void> _moveCameraToCurrentPosition() async {
    if (_currentPosition != null) {
      final GoogleMapController mapController = await _controller.future;
      mapController.animateCamera(
        CameraUpdate.newLatLngZoom(_currentPosition!, 16.0), // 現在地にカメラを移動
      );
    } else {
      debugPrint('現在地が取得されていません');
    }
  }

  // 現在地に戻るボタンのコールバック関数
  void _onCurrentLocationButtonPressed() {
    if (_currentPosition != null) {
      setState(() {
        _followUser = true;
      });
      _moveCameraToCurrentPosition(); // カメラを現在位置に移動
    } else {
      debugPrint('現在位置が取得されていません');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('google map'),
        automaticallyImplyLeading: false,
        centerTitle: false,
        backgroundColor: Colors.transparent,
        actions: <Widget>[
          Transform.rotate(
            angle: _direction * (pi / 180),
            child: SizedBox(
              width: 47,
              height: 47,
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xD7FFFFFF),
                ),
                child: const Icon(Icons.assistant_navigation),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          _initialCameraPosition == null
              ? const Center(child: CircularProgressIndicator())
              : GoogleMap(
                  mapType: MapType.normal,
                  initialCameraPosition: _initialCameraPosition!,
                  onMapCreated: (GoogleMapController controller) {
                    _controller.complete(controller);
                  },
                  scrollGesturesEnabled: true,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  zoomGesturesEnabled: true,
                  // 新しい位置に基づいて霧を再描画
                  onCameraMove: (CameraPosition position) {
                    // マップが移動されたらカメラが自動追跡しないようにする
                    setState(() {
                      _followUser = false;
                      // _currentCameraPosition = position;
                    });
                  },
                ),
          IgnorePointer(
            ignoring: true,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), // ぼかし効果を追加,
              child: CustomPaint(
                size: Size.infinite,
                painter: FogPainter(_clearingTheFogPaths, _currentPosition),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _onCurrentLocationButtonPressed,
        child: const Icon(Icons.my_location),
      ),
    );
  }
}

class FogPainter extends CustomPainter {
  final List<LatLng> clearingTheFogPaths;
  final LatLng? currentPosition;

  FogPainter(this.clearingTheFogPaths, this.currentPosition);

  @override
  void paint(Canvas canvas, Size size) {
    // 霧を再現する
    final Rect rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final Gradient gradient = RadialGradient(
      colors: [
        Colors.white.withOpacity(0.00001),
        Colors.white.withOpacity(0.00001),
      ],
      stops: const [0.3, 1.0], //霧が中央から広がる感じ
    );
    // TODO:後で学ぶべき場所
    final Paint fogPaint = Paint()..shader = gradient.createShader(rect);

    // 地図全体に霧を描画
    canvas.drawRect(rect, fogPaint);

    Paint clearPaint = Paint()
      ..color = Colors.transparent
      ..blendMode = BlendMode.clear;

    for (var point in clearingTheFogPaths) {
      // クリアする領域（円形）
      canvas.drawCircle(
        Offset(point.latitude, point.longitude),
        20, //霧がクリアされる範囲
        clearPaint,
      );
    }
    // 現在地中心から円形に霧をクリアする
    if (currentPosition != null) {
      Paint clearPaint = Paint()
        ..color = Colors.transparent
        ..blendMode = BlendMode.clear;
      canvas.drawCircle(
        Offset(size.width / 2, size.height / 2), // 現在地のスクリーン座標（仮）
        50, // 現在地周辺のクリア範囲
        clearPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
