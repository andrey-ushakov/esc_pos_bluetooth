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
import 'package:flutter_blue/flutter_blue.dart';
import 'package:rxdart/rxdart.dart';
import './enums.dart';

/// Bluetooth printer
class PrinterBluetooth {
  PrinterBluetooth(this._device);
  final BluetoothDevice _device;

  String get name => _device.name;
  String get address => _device.id.id;
  int get type => _device.type.index;
}

/// Printer Bluetooth Manager
class PrinterBluetoothManager {
  final FlutterBlue _flutterBlue = FlutterBlue.instance;
  bool _isPrinting = false;
  bool _isConnected = false;
  StreamSubscription _scanResultsSubscription;
  StreamSubscription _isScanningSubscription;
  PrinterBluetooth _selectedPrinter;
  List<BluetoothService> _bluetoothServices;


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

    _flutterBlue.startScan(timeout: timeout);

    _scanResultsSubscription = _flutterBlue.scanResults.listen((devices) {
      _scanResults.add(devices.map((d) => PrinterBluetooth(d.device)).toList());
    });

    _isScanningSubscription =
        _flutterBlue.isScanning.listen((isScanningCurrent) async {
      // If isScanning value changed (scan just stopped)
      if (_isScanning.value && !isScanningCurrent) {
        _scanResultsSubscription.cancel();
        _isScanningSubscription.cancel();
      }
      _isScanning.add(isScanningCurrent);
    });
  }

  void stopScan() async {
    await _flutterBlue.stopScan();
  }

  void selectPrinter(PrinterBluetooth printer) {
    _selectedPrinter = printer;
  }

  Future<PosPrintResult> writeBytes(
    List<int> bytes, {
    int chunkSizeBytes = 20,
    int queueSleepTimeMs = 20,
  }) async {
    final Completer<PosPrintResult> completer = Completer();

    const int timeout = 5;
    if (_selectedPrinter == null) {
      print(1);
      return Future<PosPrintResult>.value(PosPrintResult.printerNotSelected);
    } else if (_isScanning.value) {
      print(2);
      return Future<PosPrintResult>.value(PosPrintResult.scanInProgress);
    } else if (_isPrinting) {
      print(3);
      return Future<PosPrintResult>.value(PosPrintResult.printInProgress);
    } else{
      completer.complete(PosPrintResult.print);
    }

    _isPrinting = true;
    bool isFirst = true;
    // We have to rescan before connecting, otherwise we can connect only once
    await _flutterBlue.startScan(timeout: Duration(seconds: 1));
    await _flutterBlue.stopScan();

    // Connect
    if(!_isConnected) {
      await _selectedPrinter._device.connect();
      _isConnected = true;
    }

    _selectedPrinter._device.state.listen((state)async {
      switch(state){
        case BluetoothDeviceState.connected :
          final len = bytes.length;
          List<List<int>> chunks = [];
          for (var i = 0; i < len; i += chunkSizeBytes) {
            var end = (i + chunkSizeBytes < len) ? i + chunkSizeBytes : len;
            chunks.add(bytes.sublist(i, end));
          }

          if (_isConnected) {
            await _selectedPrinter._device.discoverServices();
            _selectedPrinter._device.services.listen((event) async {
              _bluetoothServices = event;
              for (BluetoothService bluetoothService in _bluetoothServices) {
                List<BluetoothCharacteristic> characteristics = bluetoothService
                    .characteristics;
                for (BluetoothCharacteristic characteristic in characteristics) {
                  if(isFirst){
                    for (var i = 0; i < chunks.length; i += 1) {
                      try {
                        await characteristic.write(
                            chunks[i], withoutResponse: true);
                        await characteristic.read();
                        isFirst = false;
                        sleep(Duration(milliseconds: queueSleepTimeMs));
                      } catch (e) {
                        break;
                      }
                    }
                  }
                }
              }
            });

            //completer.complete(PosPrintResult.success);
            _runDelayed(3).then((dynamic v) async {
              await _selectedPrinter._device.disconnect();
              _isPrinting = false;

            });
            _isConnected = false;

          }
          break;
        case BluetoothDeviceState.disconnected :
          _isConnected = false;
          break;
        default:
          break;

      }
    });

    _runDelayed(timeout).then((dynamic v) async {
      if (_isPrinting) {
        _isPrinting = false;
        completer.complete(PosPrintResult.timeout);
      }
    });

    return completer.future;
  }

  Future<PosPrintResult> printTicket(
    List<int> bytes, {
    int chunkSizeBytes = 20,
    int queueSleepTimeMs = 20,
  }) async {
    if (bytes == null || bytes.isEmpty) {
      return Future<PosPrintResult>.value(PosPrintResult.ticketEmpty);
    }
    return writeBytes(
      bytes,
      chunkSizeBytes: chunkSizeBytes,
      queueSleepTimeMs: queueSleepTimeMs,
    );
  }
}
