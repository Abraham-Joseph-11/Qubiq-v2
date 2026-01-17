import 'package:flutter/material.dart';
import 'package:flutter_libserialport/flutter_libserialport.dart';
import 'dart:convert';
import 'dart:typed_data';

class ArduinoProvider extends ChangeNotifier {
  // 1. CLASS VARIABLES (Keep the connection alive)
  SerialPort? _port;
  SerialPortReader? _reader;

  // 2. STATE VARIABLES
  List<String> _logs = [];
  bool get isConnected => _port != null && _port!.isOpen;
  List<String> get logs => _logs;

  // 3. CONNECT FUNCTION
  Future<void> connect(String portName) async {
    try {
      await disconnect(); // Close old connection first

      _port = SerialPort(portName);

      if (!_port!.openReadWrite()) {
        addLog("❌ Failed to open port (Is Arduino IDE still open?)");
        return;
      }

      SerialPortConfig config = _port!.config;
      config.baudRate = 115200;
      config.bits = 8;
      config.stopBits = 1;
      _port!.config = config;

      _reader = SerialPortReader(_port!);
      _reader!.stream.listen((data) {
        String response = utf8.decode(data);
        print("✅ BOARD REPLIED: $response");
        addLog("Board: $response");
      });

      addLog("✅ Connected to $portName");
      notifyListeners();

    } catch (e) {
      addLog("Error: $e");
    }
  }

  // 4. DISCONNECT FUNCTION
  Future<void> disconnect() async {
    if (_port != null) {
      if (_port!.isOpen) _port!.close();
      _port = null;
    }
    _reader = null;
    notifyListeners();
  }

  // 5. HELPER: Add Log
  void addLog(String message) {
    _logs.add(message);
    notifyListeners();
  }

  // 6. HELPER: Send Data
  void send(String command) {
    if (_port == null || !_port!.isOpen) return;

    String dataToSend = "$command\n";
    _port!.write(Uint8List.fromList(dataToSend.codeUnits));
    addLog("Sent: $command");
  }
}