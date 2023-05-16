import 'dart:async';

import 'package:flutter/services.dart';
import 'package:rxdart/rxdart.dart';

import '../model/bluetooth_device.dart';

/// A BluetoothManager.
class BluetoothManager {
  static const String NAMESPACE = 'flutter_bluetooth_basic';
  static const int CONNECTED = 1;
  static const int DISCONNECTED = 0;

  static const MethodChannel _channel = const MethodChannel('$NAMESPACE/methods');
  static const EventChannel _stateChannel = const EventChannel('$NAMESPACE/state');

  Stream<MethodCall> get _methodStream => _methodStreamController.stream;
  final StreamController<MethodCall> _methodStreamController = StreamController.broadcast();

  BluetoothManager._() {
    _channel.setMethodCallHandler((MethodCall call) {
      _methodStreamController.add(call);
      return Future(() => null);
    });
  }

  static BluetoothManager _instance = BluetoothManager._();

  static BluetoothManager get instance => _instance;

  // Future<bool> get isAvailable async =>
  //     await _channel.invokeMethod('isAvailable').then<bool>((d) => d);

  // Future<bool> get isOn async =>
  //     await _channel.invokeMethod('isOn').then<bool>((d) => d);

  Future<bool> get isConnected async => await _channel.invokeMethod('isConnected');

  BehaviorSubject<bool> _isScanning = BehaviorSubject.seeded(false);

  Stream<bool> get isScanning => _isScanning.stream;

  BehaviorSubject<List<BluetoothDevice>> _scanResults = BehaviorSubject.seeded([]);

  Stream<List<BluetoothDevice>> get scanResults => _scanResults.stream;

  PublishSubject _stopScanPill = new PublishSubject();

  /// Gets the current state of the Bluetooth module
  Stream<int?> get state async* {
    yield await _channel.invokeMethod('state').then((s) => s);

    yield* _stateChannel.receiveBroadcastStream().map((s) => s);
  }

  /// Starts a scan for Bluetooth Low Energy devices
  /// Timeout closes the stream after a specified [Duration]
  Stream<BluetoothDevice> scan({
    Duration? timeout,
  }) async* {
    if (_isScanning.value == true) {
      throw Exception('Another scan is already in progress.');
    }

    // Emit to isScanning
    _isScanning.add(true);

    final killStreams = <Stream>[];
    killStreams.add(_stopScanPill);
    if (timeout != null) {
      killStreams.add(Rx.timer(null, timeout));
    }

    // Clear scan results list
    _scanResults.add(<BluetoothDevice>[]);

    try {
      await _channel.invokeMethod('startScan');
    } catch (e) {
      print('Error starting scan.');
      _stopScanPill.add(null);
      _isScanning.add(false);
      throw e;
    }

    yield* BluetoothManager.instance._methodStream
        .where((m) => m.method == "ScanResult")
        .map((m) => m.arguments)
        .takeUntil(Rx.merge(killStreams))
        .doOnDone(stopScan)
        .map((map) {
      final device = BluetoothDevice.fromJson(Map<String, dynamic>.from(map));
      final List<BluetoothDevice>? list = _scanResults.value;
      int newIndex = -1;
      list!.asMap().forEach((index, e) {
        if (e.address == device.address) {
          newIndex = index;
        }
      });

      if (newIndex != -1) {
        list[newIndex] = device;
      } else {
        list.add(device);
      }
      _scanResults.add(list);
      return device;
    });
  }

  Future startScan({
    Duration? timeout,
  }) async {
    await scan(timeout: timeout).drain();
    return _scanResults.value;
  }

  /// Stops a scan for Bluetooth Low Energy devices
  Future stopScan() async {
    await _channel.invokeMethod('stopScan');
    _stopScanPill.add(null);
    _isScanning.add(false);
  }

  Future<dynamic> connect(BluetoothDevice device) =>
      _channel.invokeMethod('connect', device.toJson());

  Future<dynamic> disconnect() => _channel.invokeMethod('disconnect');

  Future<dynamic> destroy() => _channel.invokeMethod('destroy');

  Future<dynamic> writeData(List<int> bytes) {
    Map<String, Object> args = Map();
    args['bytes'] = bytes;
    args['length'] = bytes.length;

    _channel.invokeMethod('writeData', args);

    return Future.value(true);
  }
}
