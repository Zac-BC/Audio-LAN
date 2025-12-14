import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_audio_capture/flutter_audio_capture.dart';

class MasterScreen extends StatefulWidget {
  const MasterScreen({super.key});

  @override
  State<MasterScreen> createState() => _MasterScreenState();
}

class _MasterScreenState extends State<MasterScreen> {
  // =============================
  // NETWORK CONFIG
  // =============================
  static const int _discoveryPort = 45678;
  static const int _audioPort = 50000;

  RawDatagramSocket? _socket;
  Timer? _broadcastTimer;

  bool _broadcasting = false;

  final List<InternetAddress> _devices = [];

  // =============================
  // AUDIO
  // =============================
  final FlutterAudioCapture _audioCapture = FlutterAudioCapture();
  bool _capturing = false;
  final int _sampleRate = 44100;

  // =============================
  // UI STATE
  // =============================
  String _status = 'Inicializando...';

  // =============================
  // LIFECYCLE
  // =============================
  @override
  void initState() {
    super.initState();
    _initSocket();
  }

  @override
  void dispose() {
    _broadcastTimer?.cancel();
    _socket?.close();
    _audioCapture.stop();
    super.dispose();
  }

  // =============================
  // SOCKET INIT
  // =============================
  Future<void> _initSocket() async {
    try {
      _socket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        0, // puerto dinámico
      );

      _socket!.listen((event) {
        if (event == RawSocketEvent.read) {
          final dg = _socket!.receive();
          if (dg == null) return;

          final msg = utf8.decode(dg.data);

          // RESPUESTA DE DEPENDIENTES
          if (msg.startsWith('DISCOVER:')) {
            final addr = dg.address;

            if (!_devices.contains(addr)) {
              setState(() {
                _devices.add(addr);
                _status = 'Dependiente conectado: ${addr.address}';
              });
            }
          }
        }
      });

      setState(() {
        _status = 'Socket listo';
      });
    } catch (e) {
      setState(() {
        _status = 'Error socket: $e';
      });
    }
  }

  // =============================
  // DISCOVERY BROADCAST
  // =============================
  void _startBroadcast() {
    if (_socket == null || _broadcasting) return;

    _socket!.broadcastEnabled = true;
    _broadcasting = true;

    _broadcastTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      try {
        final msg = utf8.encode('MASTER_ANNOUNCE');
        _socket!.send(msg, InternetAddress('255.255.255.255'), _discoveryPort);
      } catch (_) {}
    });

    setState(() {
      _status = 'Anunciando Maestro';
    });
  }

  void _stopBroadcast() {
    _broadcastTimer?.cancel();
    _broadcastTimer = null;

    setState(() {
      _broadcasting = false;
      _status = 'Anuncio detenido';
    });
  }

  // =============================
  // AUDIO CAPTURE
  // =============================
  Future<void> _startCapture() async {
    if (_capturing) return;

    final mic = await Permission.microphone.request();
    if (!mic.isGranted) {
      setState(() {
        _status = 'Permiso de micrófono denegado';
      });
      return;
    }

    if (_socket == null || _devices.isEmpty) {
      setState(() {
        _status = 'Sin dependientes conectados';
      });
      return;
    }

    try {
      await _audioCapture.start(
        // LISTENER (audio data)
        (dynamic data) {
          final pcmBytes = _floatsToPcm16(data);
          for (final addr in _devices) {
            _socket!.send(pcmBytes, addr, _audioPort);
          }
        },
        // ERROR LISTENER (SEGUNDO ARGUMENTO POSICIONAL)
        (Object e) {
          if (mounted) {
            setState(() {
              _status = 'Error captura: $e';
            });
          }
        },
        // ARGUMENTOS OPCIONALES
        sampleRate: _sampleRate,
        bufferSize: 1024,
      );

      setState(() {
        _capturing = true;
        _status = 'Transmitiendo audio';
      });
    } catch (e) {
      setState(() {
        _status = 'Error inicio audio: $e';
      });
    }
  }

  Future<void> _stopCapture() async {
    try {
      await _audioCapture.stop();
    } catch (_) {}

    setState(() {
      _capturing = false;
      _status = 'Captura detenida';
    });
  }

  // =============================
  // PCM CONVERSION
  // =============================
  List<int> _floatsToPcm16(dynamic data) {
    if (data == null) return <int>[];

    if (data is Uint8List) {
      return data.toList();
    }

    final out = BytesBuilder();
    final bd = ByteData(2);

    if (data is Float32List) {
      for (final f in data) {
        final v = (f * 32767).clamp(-32768, 32767).toInt();
        bd.setInt16(0, v, Endian.little);
        out.add(bd.buffer.asUint8List());
      }
    } else if (data is List) {
      for (final item in data) {
        final f = item is num ? item.toDouble() : 0.0;
        final v = (f * 32767).clamp(-32768, 32767).toInt();
        bd.setInt16(0, v, Endian.little);
        out.add(bd.buffer.asUint8List());
      }
    }

    return out.toBytes();
  }

  // =============================
  // UI (SIMPLE, DEBUG)
  // =============================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Modo Maestro')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Estado: $_status'),
            const SizedBox(height: 20),

            Row(
              children: [
                ElevatedButton(
                  onPressed: _broadcasting ? _stopBroadcast : _startBroadcast,
                  child: Text(
                    _broadcasting ? 'Detener anuncio' : 'Iniciar anuncio',
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _capturing ? _stopCapture : _startCapture,
                  child: Text(_capturing ? 'Detener audio' : 'Iniciar audio'),
                ),
              ],
            ),

            const SizedBox(height: 30),
            const Text(
              'Dependientes conectados:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            Expanded(
              child:
                  _devices.isEmpty
                      ? const Text('Ninguno')
                      : ListView.builder(
                        itemCount: _devices.length,
                        itemBuilder: (context, index) {
                          final d = _devices[index];
                          return ListTile(
                            leading: const Icon(Icons.mic),
                            title: Text(d.address),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
