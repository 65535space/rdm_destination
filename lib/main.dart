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
  final bool _isTracking = false;
  final List<LatLng> _routePoints = [];
  bool _followUser = false; // 新しい変数：ユーザーの位置を追跡するかどうか
  // クリアにする道
  final List<LatLng> _clearedPath = [];

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

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('位置情報サービスが無効です。');
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
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
                    // マップが移動されたら自動追跡を無効にする
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
                painter: FogPainter(_clearedPath, _currentPosition),
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
  final List<LatLng> clearedPath; // 霧が除去された道のリスト
  final LatLng? currentPosition;

  FogPainter(this.clearedPath, this.currentPosition);

  @override
  void paint(Canvas canvas, Size size) {
    // グラデーションを追加
    final Rect rect = Rect.fromLTWH(0, 0, size.width, size.height);

    final Gradient gradient = RadialGradient(
      colors: [
        Colors.white.withOpacity(0.00001),
        Colors.white.withOpacity(0.00001),
      ],
      stops: const [0.3, 1.0], //霧が中央から広がる感じ
    );

    final Paint fogPaint = Paint()..shader = gradient.createShader(rect);

    // 地図全体に霧を描画
    canvas.drawRect(rect, fogPaint);

    // クリアされた経路に沿って霧を削除
    Paint clearPaint = Paint()
      ..color = Colors.transparent
      ..blendMode = BlendMode.clear;

    for (var point in clearedPath) {
      // クリアする領域（ここでは円形を例とする）
      canvas.drawCircle(
        Offset(point.latitude, point.longitude),
        20, //霧がクリアされる範囲
        clearPaint,
      );
    }
    // 現在地部分の霧をクリアする
    if (currentPosition != null) {
      Paint clearPaint = Paint()
        ..color = Colors.transparent
        ..blendMode = BlendMode.clear;
      // 現在地を中心に円形に霧をクリアする
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
