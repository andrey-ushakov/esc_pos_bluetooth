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
  //String get address => _device.;
  // int get type => _device.type;
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
      print(4);
    }

    _isPrinting = true;

    // We have to rescan before connecting, otherwise we can connect only once
    await _flutterBlue.startScan(timeout: Duration(seconds: 1));
    await _flutterBlue.stopScan();

    // Connect
    print(_isConnected);
    if(!_isConnected){
      await _selectedPrinter._device.connect();
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
          if (!_isConnected) {
            await _selectedPrinter._device.discoverServices();
            _selectedPrinter._device.services.listen((event) async {
              _bluetoothServices = event;
              for (BluetoothService bluetoothService in _bluetoothServices) {
                List<BluetoothCharacteristic> characteristics = bluetoothService
                    .characteristics;
                for (BluetoothCharacteristic characteristic in characteristics) {
                  for (var i = 0; i < chunks.length; i += 1) {
                    try {
                      await characteristic.write(
                          chunks[i], withoutResponse: true);
                      await characteristic.read();
                      sleep(Duration(milliseconds: queueSleepTimeMs));
                    } catch (e) {
                      break;
                    }
                  }
                }
              }
            });

            completer.complete(PosPrintResult.success);

          }

          _runDelayed(3).then((dynamic v) async {
            await _selectedPrinter._device.disconnect();
          });
          _isConnected = true;
          print("==========================>" + _isPrinting.toString());

          break;
        default:
          break;

      }
    });

    _isPrinting = false;

    return completer.future;
  }

  Future<PosPrintResult> printTicket(
    Ticket ticket, {
    int chunkSizeBytes = 20,
    int queueSleepTimeMs = 20,
  }) async {
    if (ticket == null || ticket.bytes.isEmpty) {
      return Future<PosPrintResult>.value(PosPrintResult.ticketEmpty);
    }
    return writeBytes(
      ticket.bytes,
      chunkSizeBytes: chunkSizeBytes,
      queueSleepTimeMs: queueSleepTimeMs,
    );
  }
}
