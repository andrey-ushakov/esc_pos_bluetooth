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
import 'package:flutter/cupertino.dart';
import 'package:flutter_bluetooth_basic/flutter_bluetooth_basic.dart';
import 'package:rxdart/rxdart.dart';

import './enums.dart';

/// Bluetooth printer
class PrinterBluetooth {
  PrinterBluetooth(this._device);
  final BluetoothDevice _device;

  String get name => _device.name;
  String get address => _device.address;
  int get type => _device.type;
}

/// Printer Bluetooth Manager
class PrinterBluetoothManager {
  final BluetoothManager _bluetoothManager = BluetoothManager.instance;
  bool _isPrinting = false;
  bool _isConnected = false;
  StreamSubscription _scanResultsSubscription;
  StreamSubscription _isScanningSubscription;
  PrinterBluetooth _selectedPrinter;

  final BehaviorSubject<bool> _isScanning = BehaviorSubject.seeded(false);
  Stream<bool> get isScanningStream => _isScanning.stream;

  final BehaviorSubject<List<PrinterBluetooth>> _scanResults =
      BehaviorSubject.seeded([]);
  Stream<List<PrinterBluetooth>> get scanResults => _scanResults.stream;

  List<int> _bufferedBytes = [];
  int _queueSleepTimeMs = 20;
  int _chunkSizeBytes = 20;
  int _timeOut = 5;

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
      if (_isScanning.value && !isScanningCurrent) {
        _scanResultsSubscription.cancel();
        _isScanningSubscription.cancel();
      }
      _isScanning.add(isScanningCurrent);
    });
  }

  void stopScan() async {
    await _bluetoothManager.stopScan();
  }

  void selectPrinter(PrinterBluetooth printer) {
    _selectedPrinter = printer;
    _bluetoothManager.state.listen((state) async {
      switch (state) {
        case BluetoothManager.CONNECTED:
          _isConnected = true;
          print('CONNECTED STATE');
          print('CONNECTED STATE');
          break;
        case BluetoothManager.DISCONNECTED:
          _isConnected = false;
          print('DISCONNECTED STATE');
          print('DISCONNECTED STATE');
          break;
        default:
          break;
      }
      print('BluetoothManager.STATE => $state');
    });
  }

  Future<PosPrintResult> _checkConnectionState() async {
    Timer _stateTimer;
    int _start = 10;
    final Completer<PosPrintResult> completer = Completer();
    const oneSec = Duration(seconds: 1);
    _stateTimer = Timer.periodic(
      oneSec,
      (Timer timer) {
        if (_start == 0 || _isConnected) {
          timer.cancel();
          print('ENDTIME');
          print(_isConnected);
          if (_isConnected) {
            _stateTimer?.cancel();
            completer.complete(PosPrintResult.success);
          } else {
            _stateTimer?.cancel();
            completer.complete(PosPrintResult.timeout);
          }
        } else {
          _start--;
        }
      },
    );
    return completer.future;
  }

  Future<PosPrintResult> _connectBluetooth(
    List<int> bytes, {
    int timeout = 5,
  }) async {
    if (_selectedPrinter == null) {
      return Future<PosPrintResult>.value(PosPrintResult.printerNotSelected);
    } else if (_isScanning.value) {
      return Future<PosPrintResult>.value(PosPrintResult.scanInProgress);
    } else if (_isPrinting) {
      return Future<PosPrintResult>.value(PosPrintResult.printInProgress);
    }
    // We have to rescan before connecting, otherwise we can connect only once
    await _bluetoothManager.startScan(timeout: Duration(seconds: 1));
    await _bluetoothManager.stopScan();

    // Connect
    await _bluetoothManager.connect(_selectedPrinter._device);
    final result = await _checkConnectionState();
    return result;
  }

  Future<PosPrintResult> _writeRequest(timeout) async {
    final Completer<PosPrintResult> completer = Completer();
    if (_bufferedBytes.isNotEmpty) {
      await _writePending();
      _runDelayed(timeout).then((dynamic v) async {
        if (_isPrinting) {
          _isPrinting = false;
          completer.complete(PosPrintResult.timeout);
          await _bluetoothManager.disconnect();
          print('TIMEOUT');
        }
        completer.complete(PosPrintResult.success);
      });
    }
    return completer.future;
  }

  Future<PosPrintResult> printTicket(
    Ticket ticket, {
    int chunkSizeBytes = 20,
    int queueSleepTimeMs = 20,
    int timeout = 5,
  }) async {
    if (ticket == null || ticket.bytes.isEmpty) {
      return Future<PosPrintResult>.value(PosPrintResult.ticketEmpty);
    }
    _bufferedBytes = [];
    _bufferedBytes = ticket.bytes;
    _queueSleepTimeMs = queueSleepTimeMs;
    _chunkSizeBytes = chunkSizeBytes;
    _timeOut = timeout;

    if (!_isConnected) {
      final result = await _connectBluetooth(
        ticket.bytes,
        timeout: timeout,
      );
      if (result.msg != 'Success') {
        return result;
      }
    }
    if (_isConnected) {
      return await _writeRequest(timeout);
    } else {
      return Future<PosPrintResult>.value(PosPrintResult.timeout);
    }
  }

  Future<PosPrintResult> printLabel(
    List<int> bytes, {
    int chunkSizeBytes = 20,
    int queueSleepTimeMs = 20,
    int timeout = 5,
  }) async {
    if (bytes == null || bytes.isEmpty) {
      return Future<PosPrintResult>.value(PosPrintResult.ticketEmpty);
    }
    _bufferedBytes = [];
    _bufferedBytes = bytes;
    _queueSleepTimeMs = queueSleepTimeMs;
    _chunkSizeBytes = chunkSizeBytes;
    _timeOut = timeout;
    if (!_isConnected) {
      final result = await _connectBluetooth(
        bytes,
        timeout: timeout,
      );
      if (result.msg != 'Success') {
        return result;
      }
    }

    if (_isConnected) {
      return await _writeRequest(timeout);
    } else {
      return Future<PosPrintResult>.value(PosPrintResult.timeout);
    }
  }

  disconnect(timeout) {
    _runDelayed(timeout).then((dynamic v) async {
      await _bluetoothManager.disconnect();
      print('PENDING DISCONNECTED');
    });
  }

  Future<void> _writePending() async {
    final len = _bufferedBytes.length;
    List<List<int>> chunks = [];
    for (var i = 0; i < len; i += _chunkSizeBytes) {
      var end = (i + _chunkSizeBytes < len) ? i + _chunkSizeBytes : len;
      chunks.add(_bufferedBytes.sublist(i, end));
    }
    _isPrinting = true;
    for (var i = 0; i < chunks.length; i += 1) {
      await _bluetoothManager.writeData(chunks[i]);
      sleep(Duration(milliseconds: _queueSleepTimeMs));
    }
    _isPrinting = false;
    _bufferedBytes = [];
  }
}
