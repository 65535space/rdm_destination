import 'dart:async';
// import 'dart:math';

import 'package:rdm_destination/bottom_bar.dart';
import 'package:rdm_destination/modal_sheet.dart';

// import 'secret.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:flutter_polyline_points/flutter_polyline_points.dart';

class GenerateRoutePage extends StatefulWidget {
  final Function(int) onTap;

  const GenerateRoutePage({super.key, required this.onTap});

  @override
  State<GenerateRoutePage> createState() => _GenerateRoutePageState();
}

class _GenerateRoutePageState extends State<GenerateRoutePage> {
  final Completer<GoogleMapController> _controller = Completer(); // 初期化に必要
  LatLng? _currentPosition; // 初期化に必要
  CameraPosition? _initialCameraPosition; // 初期化に必要
  // final bool _isTracking = false; // 経路情報を保存するかどうかを決める変数
  bool _followUser = false; // FloatingActionButtonを押した際に、追跡するようにするため　初期化に必要
  // bool firstCalculateTime = true;

  late Set<Marker> _markers = {};
  late Set<Polyline> _polylines = {}; // 初期化に必要
  // final List<LatLng> _routePoints = []; // 霧機能のために通った経路を格納する
  // final List<PolylineWayPoint> _waypoints = [];
  // List<LatLng> _anotherDestinations = [];
  // List<LatLng> _sortedDestinations = [];

  @override
  void initState() {
    super.initState();
    _initializeAsync();
  }

  Future<void> _initializeAsync() async {
    debugPrint("initializeAsync was called");
    // 非同期処理を行う例
    await _getCurrentPosition();
    // if (_currentPosition != null) {
    //   await _generateRandomRelayPoints();
    //   _sortDestinations();
    //   await _getOptimizedRoute();
    // } else {
    //   debugPrint("_currentPosition == null:56");
    // }
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
        // if (_isTracking) {
        //   _routePoints.add(_currentPosition!);
        // }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: _initialCameraPosition == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                Positioned(
                  child: GoogleMap(
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
                    markers: _markers,
                    // 位置情報を更新した際に、経路を再取得すべきかいなか
                    scrollGesturesEnabled: true,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    zoomGesturesEnabled: true,
                  ),
                ),
                Positioned(
                  right: 15,
                  bottom: 100,
                  child: FloatingActionButton(
                    child: const Icon(Icons.add),
                    onPressed: () async {
                      final result =
                          await showModalBottomSheet<Map<String, dynamic>>(
                        backgroundColor: Colors.transparent,
                        isScrollControlled: true,
                        context: context,
                        builder: (context) {
                          return ModalSheet(
                            polylines: _polylines,
                            markers: _markers,
                          );
                        },
                      );
                      if (result != null) {
                        setState(() {
                          _polylines = result['polyline'] ?? _polylines;
                          // markers プロパティを取得して出力
                          _markers = result['marker'] ?? _markers;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
      bottomNavigationBar: BottomBar(onTap: widget.onTap),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await _moveCameraToCurrentPosition();
        },
        child: const Icon(Icons.my_location),
      ),
    );
  }
}
