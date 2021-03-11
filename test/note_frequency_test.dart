import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rhythm/rhythm.dart';

void main() {
  test('getPlatformVersion', () async {
    var a4 = Note.A(4);
    var b3 = Note.B(3);
    var c4 = Note.C(4);
    var reference = 440.0;

    print(a4.frequency(reference));
    print(b3.frequency(reference));
    print(c4.frequency(reference));
  });
}
