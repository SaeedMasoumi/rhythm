library rhythm;

import 'dart:async';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rhythm/src/note_detector.dart';

class Rhythm {
  static const MethodChannel _channel = const MethodChannel('rhythm');

  StreamController<PitchResult>? _rhythmController;
  NoteDetector? _noteDetector;
  bool _isStarted = false;

  StreamSubscription<PitchResult>? _noteSubscription;

  Stream<PitchResult> pitchDetection({
    Tuning tuning = const Tuning.standard(),
    AudioSource audioSource = AudioSource.mic,
    int sampleRate = 22050,
    int audioBufferSize = 1024,
    int bufferOverlap = 0,
    double referencePitch = 440,
  }) async* {
    if (_rhythmController == null) {
      _rhythmController = StreamController.broadcast();
    }
    if (_noteDetector == null) {
      _noteDetector = NoteDetector(tuning, referencePitch);
      _noteSubscription?.cancel();
      _noteSubscription = _noteDetector?.onNoteDetected.listen((result) {
        _rhythmController?.add(result);
      });
    }
    _listenToUpdates();

    bool granted = await _getOrRequestPermission();
    if (granted && !_isStarted) {
      _channel.invokeMethod('startPitchDetection', <String, dynamic>{
        'tuning': tuning.toPitchNotation(),
        'audioSource': audioSource.index,
        'sampleRate': sampleRate,
        'audioBufferSize': audioBufferSize,
        'bufferOverlap': bufferOverlap,
      });
      _isStarted = true;
    }
    yield* _rhythmController!.stream;
  }

  void _listenToUpdates() {
    _channel.setMethodCallHandler((MethodCall call) async {
      switch (call.method) {
        case "onPitchUpdatesReceived":
          _noteDetector?.addPitchSample(call.arguments[0]);
          break;
        default:
          throw new ArgumentError("Unknown method: ${call.method}");
      }
    });
  }

  Future<void> dispose() async {
    _channel.invokeMethod('disposePitchDetection');
    _rhythmController?.close();
    _rhythmController = null;
    _noteDetector?.dispose();
    _noteSubscription?.cancel();
    _isStarted = false;
  }

  Future<bool> _getOrRequestPermission() async {
    bool granted = await Permission.microphone.request().isGranted;
    if (granted) {
      return true;
    }
    PermissionStatus status = await Permission.microphone.request();
    return status == PermissionStatus.granted;
  }
}

class Note {
  const Note._(this.sign, this.sol, this.octave);

  const Note.C(int octave) : this._("C", "Do", octave);

  const Note.D(int octave) : this._("D", "Re", octave);

  const Note.E(int octave) : this._("E", "Mi", octave);

  const Note.F(int octave) : this._("F", "Fa", octave);

  const Note.G(int octave) : this._("G", "Sol", octave);

  const Note.A(int octave) : this._("A", "La", octave);

  const Note.B(int octave) : this._("B", "Si", octave);

  final String sign;
  final String sol;
  final int octave;

  final List<String> _notes = const [
    "C",
    "C#",
    "D",
    "D#",
    "E",
    "F",
    "F#",
    "G",
    "G#",
    "A",
    "A#",
    "B",
  ];

  double frequency(double referenceFrequency) {
    int semitonesPerOctave = 12;
    int referenceOctave = 4;
    double distance =
        (semitonesPerOctave * (octave - referenceOctave)).toDouble();

    distance += _notes.indexOf(sign) - _notes.indexOf("A");

    return referenceFrequency * pow(2, distance / 12);
  }

  @override
  String toString() {
    return '$sign$octave';
  }
}

class Tuning {
  const Tuning._(this.notes);

  const Tuning.standard()
      : this._(const [
          Note.E(4),
          Note.B(3),
          Note.G(3),
          Note.D(3),
          Note.A(2),
          Note.E(2),
        ]);

  final List<Note> notes;

  List<String> toPitchNotation() =>
      notes.map((e) => "${e.sign}${e.octave}").toList();
}

class PitchResult {
  PitchResult(this.note, this.pitch, this.deviation);

  Note note;
  double pitch;
  double deviation;

  @override
  String toString() {
    return 'Note: ${note.toString()}, Pitch: $pitch, Deviation: $deviation';
  }
}

enum AudioSource {
  defaultSource,
  mic,
  voiceUplink,
  voiceDownlink,
  voiceCall,
  camcorder,
  voiceRecognition,
  voiceCommunication,
  remoteSubmix,
  unprocessed,
  voicePerformance,
}
