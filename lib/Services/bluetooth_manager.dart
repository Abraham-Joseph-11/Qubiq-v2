import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluetoothManager extends ChangeNotifier {
  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _writeCharacteristic;
  StreamSubscription? _connectionStateSubscription;

  bool get isConnected => _connectedDevice != null;
  BluetoothDevice? get connectedDevice => _connectedDevice;

  // Expose the scan results stream directly to the UI
  Stream<List<ScanResult>> get scanResults => FlutterBluePlus.scanResults;

  // =================================================================
  // 1. REVERTED & SIMPLIFIED START SCAN (Fixes "No Robots Found")
  // =================================================================
  Future<void> startScan() async {
    try {
      // Step A: Force stop any previous scan to clear "stuck" states
      if (FlutterBluePlus.isScanningNow) {
        await FlutterBluePlus.stopScan();
      }

      // Step B: Wait 500ms to let the bluetooth module breathe
      await Future.delayed(const Duration(milliseconds: 500));

      // Step C: Start Scan immediately (No complex checks)
      print("🚀 Force Starting Scan...");
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 15),
        androidUsesFineLocation: true,
      );

    } catch (e) {
      print("❌ Error starting scan: $e");
    }
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    await FlutterBluePlus.stopScan();
    try {
      await device.connect(autoConnect: false);
      _connectedDevice = device;

      _connectionStateSubscription = device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) disconnect();
      });

      await _discoverServices();
      notifyListeners();
    } catch (e) {
      print("Connection Error: $e");
      disconnect();
    }
  }

  Future<void> disconnect() async {
    try {
      await _connectedDevice?.disconnect();
    } catch (e) {
      print("Disconnect error: $e");
    }
    _connectionStateSubscription?.cancel();
    _connectedDevice = null;
    _writeCharacteristic = null;
    notifyListeners();
  }

  Future<void> _discoverServices() async {
    if (_connectedDevice == null) return;
    List<BluetoothService> services = await _connectedDevice!.discoverServices();
    for (var service in services.reversed) {
      for (var characteristic in service.characteristics) {
        if (characteristic.properties.write || characteristic.properties.writeWithoutResponse) {
          _writeCharacteristic = characteristic;
          return;
        }
      }
    }
  }

  // =================================================================
  // 2. CRASH FIX FOR SENDING DATA (Kept this from previous fix)
  // =================================================================
  Future<void> sendData(String data) async {
    if (_writeCharacteristic == null) {
      print("❌ Error: No writable characteristic found");
      return;
    }

    List<int> bytes = utf8.encode(data);
    try {
      // FIX: withoutResponse: false prevents the crash on ESP32
      await _writeCharacteristic!.write(bytes, withoutResponse: false);
      print("✅ Sent: $data");
    } catch (e) {
      print("❌ Send Error: $e");
    }
  }
}