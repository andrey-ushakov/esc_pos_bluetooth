/*
 * esc_pos_bluetooth
 * Created by Andrey Ushakov
 * 
 * Copyright (c) 2019-2020. All rights reserved.
 * See LICENSE for distribution and usage details.
 */

import 'dart:async';
import 'dart:io';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:rxdart/rxdart.dart';
import 'package:flutter_bluetooth_basic/flutter_bluetooth_basic.dart';
import './enums.dart';

/// Bluetooth printer
class PrinterBluetooth {
  PrinterBluetooth(this._device);
  final BluetoothDevice _device;

  String? get name => _device.name;
  String? get address => _device.address;
  int? get type => _device.type;
}

/// Printer Bluetooth Manager
class PrinterBluetoothManager {
  final BluetoothManager _bluetoothManager = BluetoothManager.instance;
  bool _isPrinting = false;
  bool _isConnected = false;
  StreamSubscription? _scanResultsSubscription;
  StreamSubscription? _isScanningSubscription;
  PrinterBluetooth? _selectedPrinter;

  final BehaviorSubject<bool> _isScanning = BehaviorSubject.seeded(false);
  Stream<bool> get isScanningStream => _isScanning.stream;

  final BehaviorSubject<List<PrinterBluetooth>> _scanResults =
      BehaviorSubject.seeded([]);
  Stream<List<PrinterBluetooth>> get scanResults => _scanResults.stream;

  Future _runDelayed(int seconds) {
    return Future<dynamic>.delayed(Duration(seconds: seconds));
  }

  void startScan(Duration timeout) async {
    _scanResults.add(<PrinterBluetooth>[]);

    _bluetoothManager.startScan(timeout: timeout);

    _scanResultsSubscription = _bluetoothManager.scanResults.listen((devices) {
      _scanResults.add(devices.map((d) => PrinterBluetooth(d)).toList());
    });

    _isScanningSubscription =
        _bluetoothManager.isScanning.listen((isScanningCurrent) async {
      // If isScanning value changed (scan just stopped)
      if (_isScanning.value! && !isScanningCurrent) {
        _scanResultsSubscription!.cancel();
        _isScanningSubscription!.cancel();
      }
      _isScanning.add(isScanningCurrent);
    });
  }

  Future<void> stopScan() async {
    return _bluetoothManager.stopScan();
  }

  void selectPrinter(PrinterBluetooth printer) {
    _selectedPrinter = printer;
  }

  Future<PosPrintResult> writeBytes(List<int> bytes,
      {int chunkSizeBytes = 20,
      int queueSleepTimeMs = 20,
      Duration timeout = const Duration(seconds: 5)}) async {
    if (_selectedPrinter == null) {
      return PosPrintResult.printerNotSelected;
    } else if (_isScanning.value!) {
      return PosPrintResult.scanInProgress;
    } else if (_isPrinting) {
      return PosPrintResult.printInProgress;
    }

    // We have to rescan before connecting, otherwise we can connect only once
    await _bluetoothManager.startScan(timeout: Duration(seconds: 1));
    await _bluetoothManager.stopScan();

    // Connect
    await _bluetoothManager.connect(_selectedPrinter!._device);

    if (await _bluetoothManager.state
            .firstWhere((element) => element == BluetoothManager.CONNECTED)
            .timeout(timeout, onTimeout: () {
          return BluetoothManager.DISCONNECTED;
        }) !=
        BluetoothManager.CONNECTED) {
      _isConnected = false;
      return PosPrintResult.timeout;
    }
    _isConnected = true;

    final len = bytes.length;
    List<List<int>> chunks = [];
    for (var i = 0; i < len; i += chunkSizeBytes) {
      var end = (i + chunkSizeBytes < len) ? i + chunkSizeBytes : len;
      chunks.add(bytes.sublist(i, end));
    }

    List<Future> futures = <Future>[];

    _isPrinting = true;

    for (var i = 0; i < chunks.length; i += 1) {
      futures.add(_bluetoothManager.writeData(chunks[i]));
      sleep(Duration(milliseconds: queueSleepTimeMs));
    }

    return Future.wait(futures).then((_) async {
      _isPrinting = false;
      _isConnected = false;
      await _bluetoothManager.disconnect();
      return PosPrintResult.success;
    }).catchError((e) async {
      _isPrinting = false;
      _isConnected = false;
      await _bluetoothManager.disconnect();
      return PosPrintResult.error;
    }).timeout(timeout, onTimeout: () async {
      _isPrinting = false;
      _isConnected = false;
      await _bluetoothManager.disconnect();
      return PosPrintResult.timeout;
    });
  }

  Future<void> disconnect() async {
    await _bluetoothManager.disconnect();
    _isConnected = false;
  }

  Future<PosPrintResult> printTicket(
    List<int> bytes, {
    int chunkSizeBytes = 20,
    int queueSleepTimeMs = 20,
  }) async {
    if (bytes.isEmpty) {
      return Future<PosPrintResult>.value(PosPrintResult.ticketEmpty);
    }
    return writeBytes(
      bytes,
      chunkSizeBytes: chunkSizeBytes,
      queueSleepTimeMs: queueSleepTimeMs,
    );
  }
}
