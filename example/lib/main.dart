import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:rhythm/rhythm.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Rhythm rhythm = Rhythm();
  Map<String, Tuning> tunings = {'standard': Tuning.standard()};
  bool isStarted = false;
  String? tuning;

  @override
  void initState() {
    super.initState();
    tuning = tunings.keys.first;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 36),
                    child: Text('select tuning'),
                  ),
                  DropdownButton<String>(
                    value: tuning,
                    style: TextStyle(color: Colors.deepPurple),
                    underline: Container(
                      height: 2,
                      color: Colors.deepPurpleAccent,
                    ),
                    onChanged: (String? newValue) {
                      setState(() {
                        tuning = newValue!;
                      });
                    },
                    items: tunings.keys
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                ],
              ),
              SizedBox(
                width: 200,
                child: ElevatedButton(
                  child: Text(isStarted ? 'stop' : 'start'),
                  onPressed: () {
                    if (isStarted) {
                      rhythm.dispose();
                    } else {
                      rhythm.pitchDetection(tuning: tunings[tuning]!).listen((event) {
                        print('${event.toString()}');
                      });
                    }
                    setState(() {
                      isStarted = !isStarted;
                    });
                  },
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    rhythm.dispose();
    super.dispose();
  }
}
