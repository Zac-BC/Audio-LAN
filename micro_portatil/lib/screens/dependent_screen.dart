import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class DependentScreen extends StatefulWidget {
  const DependentScreen({super.key});

  @override
  State<DependentScreen> createState() => _DependentScreenState();
}

class _DependentScreenState extends State<DependentScreen> {
  // =============================
  // NETWORK CONFIG
  // =============================
  static const int _discoveryPort = 45678;
  static const int _audioPort = 50000;

  RawDatagramSocket? _discoverySocket;
  RawDatagramSocket? _audioSocket;

  InternetAddress? _masterAddress;

  // =============================
  // AUDIO
  // =============================
  final BytesBuilder _buffer = BytesBuilder();
  Timer? _playTimer;
  final AudioPlayer _player = AudioPlayer();

  int _sampleRate = 44100;

  // =============================
  // STATE
  // =============================
  bool _listening = false;
  String _status = 'Buscando Maestro...';

  // =============================
  // LIFECYCLE
  // =============================
  @override
  void initState() {
    super.initState();
    _startDiscovery();
  }

  @override
  void dispose() {
    _discoverySocket?.close();
    _stopListening();
    _player.dispose();
    super.dispose();
  }

  // =============================
  // DISCOVERY (MASTER ↔ DEPENDENT)
  // =============================
  Future<void> _startDiscovery() async {
    try {
      _discoverySocket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        _discoveryPort,
      );

      _discoverySocket!.listen((event) {
        if (event == RawSocketEvent.read) {
          final dg = _discoverySocket!.receive();
          if (dg == null) return;

          final msg = utf8.decode(dg.data);

          if (msg == 'MASTER_ANNOUNCE' && _masterAddress == null) {
            _masterAddress = dg.address;

            // Responder al maestro
            final reply = utf8.encode('DISCOVER:DEPENDIENTE');
            _discoverySocket!.send(reply, _masterAddress!, _discoveryPort);

            setState(() {
              _status = 'Conectado a Maestro ${_masterAddress!.address}';
            });
          }
        }
      });
    } catch (e) {
      setState(() {
        _status = 'Error discovery: $e';
      });
    }
  }

  // =============================
  // AUDIO LISTENING
  // =============================
  Future<void> _startListening() async {
    if (_listening) return;
    if (_masterAddress == null) {
      setState(() {
        _status = 'No hay Maestro conectado';
      });
      return;
    }

    try {
      _audioSocket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        _audioPort,
      );

      _audioSocket!.listen((event) {
        if (event == RawSocketEvent.read) {
          final dg = _audioSocket!.receive();
          if (dg != null) {
            _buffer.add(dg.data);
          }
        }
      });

      // Reproducir audio cada 300 ms (modo prueba)
      _playTimer = Timer.periodic(const Duration(milliseconds: 300), (_) async {
        final bytes = _buffer.toBytes();
        if (bytes.isEmpty) return;

        _buffer.clear();

        final wav = _makeWav(
          Uint8List.fromList(bytes),
          sampleRate: _sampleRate,
        );

        try {
          await _player.play(BytesSource(wav));
        } catch (_) {}
      });

      setState(() {
        _listening = true;
        _status = 'Recibiendo audio del Maestro';
      });
    } catch (e) {
      setState(() {
        _status = 'Error audio: $e';
      });
    }
  }

  void _stopListening() {
    _playTimer?.cancel();
    _playTimer = null;

    _audioSocket?.close();
    _audioSocket = null;

    _buffer.clear();

    setState(() {
      _listening = false;
      _status = 'Audio detenido';
    });
  }

  // =============================
  // WAV UTILS (PCM16 → WAV)
  // =============================
  Uint8List _makeWav(Uint8List pcm16, {int sampleRate = 44100}) {
    final byteRate = sampleRate * 2;
    final blockAlign = 2;

    final data = BytesBuilder();

    data.add(ascii.encode('RIFF'));
    data.add(_u32(36 + pcm16.length));
    data.add(ascii.encode('WAVE'));

    data.add(ascii.encode('fmt '));
    data.add(_u32(16));
    data.add(_u16(1));
    data.add(_u16(1));
    data.add(_u32(sampleRate));
    data.add(_u32(byteRate));
    data.add(_u16(blockAlign));
    data.add(_u16(16));

    data.add(ascii.encode('data'));
    data.add(_u32(pcm16.length));
    data.add(pcm16);

    return Uint8List.fromList(data.toBytes());
  }

  List<int> _u32(int v) {
    final bd = ByteData(4)..setUint32(0, v, Endian.little);
    return bd.buffer.asUint8List();
  }

  List<int> _u16(int v) {
    final bd = ByteData(2)..setUint16(0, v, Endian.little);
    return bd.buffer.asUint8List();
  }

  // =============================
  // UI (SIMPLE, SIN ANIMACIONES)
  // =============================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Modo Dependiente')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(_status, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _listening ? _stopListening : _startListening,
              child: Text(
                _listening ? 'Detener recepción' : 'Iniciar recepción',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
