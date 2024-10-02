import 'dart:async';
import 'dart:math';
import 'secret.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

class RdmKeiro extends StatefulWidget {
  const RdmKeiro({super.key});

  @override
  State<RdmKeiro> createState() => _RdmKeiroState();
}

class _RdmKeiroState extends State<RdmKeiro> {
  final Completer<GoogleMapController> _controller = Completer();
  LatLng? _currentPosition;
  CameraPosition? _initialCameraPosition;
  final bool _isTracking = false; // 経路情報を保存するかどうかを決める変数
  bool _followUser = false; // FloatingActionButtonを押した際に、追跡するようにするため

  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  final List<LatLng> _routePoints = []; // 霧機能のために通った経路を格納する
  final List<LatLng> _destinations = [
    const LatLng(34.3425, 134.0434),
    const LatLng(34.3429, 134.0534),
    const LatLng(34.3267, 134.0705),
    const LatLng(34.3549, 134.0483),
    const LatLng(34.3302, 134.0439),
    const LatLng(34.3521, 134.0564),
    const LatLng(34.3279, 134.0587),
    const LatLng(34.3386, 134.0331),
    const LatLng(34.3399, 134.0779),
    const LatLng(34.3498, 134.0466),
  ];
  List<LatLng> _sortedDestinations = [];

  @override
  void initState() {
    super.initState();
    _initializeAsync();
  }

  Future<void> _initializeAsync() async {
    debugPrint("initializeAsync was called");
    // 非同期処理を行う例
    await _getCurrentPosition();
    if (_currentPosition != null) {
      _sortDestinations();
      await _getOptimizedRoute();
    } else {
      debugPrint("_currentPosition == null:56");
    }
  }

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

    //位置情報のパーミッションを確認するフェーズ
    // permission = await Geolocator.checkPermission();
    // if (permission == LocationPermission.denied) {
    //   //denied=拒否
    //   permission = await Geolocator.requestPermission();
    //   if (permission == LocationPermission.denied) {
    //     debugPrint('位置情報の権限が拒否されました。');
    //     return;
    //   }
    // }
    // if (permission == LocationPermission.deniedForever) {
    //   debugPrint('位置情報の権限が永続的に拒否されています。');
    //   return;
    // }

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

  void _sortDestinations() {
    debugPrint("_sortDestinations was called");
    if (_currentPosition == null) {
      debugPrint("_currentPosition == null:129");
      return;
    }

    _sortedDestinations = List.from(_destinations);
    _sortedDestinations.sort((a, b) {
      double distA = _calculateDistance(_currentPosition!, a);
      double distB = _calculateDistance(_currentPosition!, b);
      return distA.compareTo(distB);
    });
  }

  double _calculateDistance(LatLng start, LatLng end) {
    debugPrint("_calculateDistance was called");
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 -
        c((end.latitude - start.latitude) * p) / 2 +
        c(start.latitude * p) *
            c(end.latitude * p) *
            (1 - c((end.longitude - start.longitude) * p)) /
            2;
    return 12742 * asin(sqrt(a));
  }

  Future<void> _getOptimizedRoute() async {
    debugPrint("_getOptimizedRoute was called");
    if (_currentPosition == null || _sortedDestinations.isEmpty) return;

    List<LatLng> waypoints = [_currentPosition!, ..._sortedDestinations];
    for (int i = 0; i < waypoints.length - 1; i++) {
      await _getRouteCoordinates(waypoints[i], waypoints[i + 1]);
    }

    setState(() {
      // 最後の目的地にマーカーを追加
      _markers.add(Marker(
        markerId: const MarkerId('destination'),
        position: _sortedDestinations.last,
      ));
    });
  }

  // 目的地までの経路を取得する
  Future<void> _getRouteCoordinates(LatLng start, LatLng destination) async {
    debugPrint("_getRouteCoordinates was called");
    String url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=${start.latitude},${start.longitude}&destination=${destination.latitude},${destination.longitude}&mode=walking&key=${Secrets.API_KEY}';

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

          List<LatLng> routeCoords = PolylinePoints()
              .decodePolyline(points)
              .map(
                (point) => LatLng(point.latitude, point.longitude),
              )
              .toList();

          setState(() {
            _polylines.add(Polyline(
              polylineId: PolylineId('${start.latitude},${start.longitude}'),
              color: Colors.blue,
              points: routeCoords,
              width: 5,
            ));
          });
          // _polylines の内容をデバッグ出力する
          debugPrint('Polyline Count: ${_polylines.length}');
        }
      } else {
        debugPrint("Error fetching directions: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error fetching directions: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: _initialCameraPosition == null
          ? const Center(child: CircularProgressIndicator())
          : GoogleMap(
              mapType: MapType.normal,
              initialCameraPosition: _initialCameraPosition!,
              onMapCreated: (GoogleMapController controller) {
                _controller.complete(controller);
              },
              onCameraMove: (CameraPosition position) {
                setState(() {
                  _followUser = false;
                });
              },
              polylines: _polylines,
              scrollGesturesEnabled: true,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              zoomGesturesEnabled: true,
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await _moveCameraToCurrentPosition();
        },
        child: const Icon(Icons.my_location),
      ),
    );
  }
}
