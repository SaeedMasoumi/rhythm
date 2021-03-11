import 'dart:async';
import 'dart:math';

import 'package:rhythm/rhythm.dart';

class NoteDetector {
  NoteDetector(Tuning tuning, this._referenceFrequency)
      : _sortedTuningNotes = List.from(tuning.notes)
          ..sort((a, b) => a
              .frequency(_referenceFrequency)
              .compareTo(b.frequency(_referenceFrequency)));

  final int _minSamples = 10;
  double _referenceFrequency;
  List<Note> _sortedTuningNotes;
  StreamController<PitchResult> _controller = StreamController.broadcast();
  List<PitchResult> _samples = [];

  Stream<PitchResult> get onNoteDetected => _controller.stream;

  void addPitchSample(double pitchFrequency) {
    if (pitchFrequency == -1) {
      return;
    }
    _samples.add(_getClosestNote(pitchFrequency));
    if (_samples.length >= _minSamples) {
      PitchResult? average = _calculateAverageDiff();
      if (average != null) {
        _controller.add(average);
      }
      _samples.clear();
    }
  }

  PitchResult _getClosestNote(double pitch) {
    double minCentDifference = double.infinity;
    Note closest = _sortedTuningNotes[0];
    for (var note in _sortedTuningNotes) {
      double frequency = note.frequency(_referenceFrequency);
      double centDifference = 1200 * log2(pitch / frequency);

      if (centDifference.abs() < minCentDifference.abs()) {
        minCentDifference = centDifference;
        closest = note;
      }
    }
    return PitchResult(closest, pitch, minCentDifference);
  }

  PitchResult? _calculateAverageDiff() {
    List<PitchResult> filteredSamples = _findMostFrequentList();
    Note mostFrequentNote = filteredSamples.first.note;
    double deviationSum = 0;
    int sameNoteCount = 0;
    for (var sample in filteredSamples) {
      deviationSum += sample.deviation;
      sameNoteCount++;
    }

    if (sameNoteCount > 0) {
      double averageDeviation = deviationSum / sameNoteCount;

      return PitchResult(mostFrequentNote,
          mostFrequentNote.frequency(_referenceFrequency), averageDeviation);
    }

    return null;
  }

  List<PitchResult> _findMostFrequentList() {
    var occurrenceMap = Map<PitchResult, int>();
    List<PitchResult> mostPopularValues = [];

    _samples.forEach((element) {
      if (!occurrenceMap.containsKey(element)) {
        occurrenceMap[element] = 1;
      } else {
        occurrenceMap[element] = occurrenceMap[element]! + 1;
      }
    });

    List<int> sortedValues = occurrenceMap.values.toList()..sort();
    int popularValue = sortedValues.last;
    occurrenceMap.forEach((k, v) {
      if (v == popularValue) {
        mostPopularValues.add(k);
      }
    });
    PitchResult frequent = mostPopularValues.first;
    return _samples.where((element) => element.note == frequent.note).toList();
  }

  void dispose() {
    _controller.close();
  }
}

double log2(num value) => log(value) / log(2);
