import 'dart:async';
import 'dart:io';

import 'package:app/record_web_service.dart';
import 'package:cross_file/cross_file.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:record/record.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'AI grocery sorter'),
    );
  }
}

enum ViewState {
  idle,
  loading,
  recording;

  String getMessage() {
    switch (this) {
      case ViewState.idle:
        return "Not recording";
      case ViewState.loading:
        return "Loading...";
      case ViewState.recording:
        return "Recording...";
    } 
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final record = AudioRecorder();
  final webService = RecordWebService("https://ai-grocery-sorter.fly.dev/upload-audio");
  var state = ViewState.idle;
  String? fetchedProducts = null;

  void _startRecording() async {
    if (!await record.hasPermission()) {
      // TODO: Show an error
      return;
    }
    var config = const RecordConfig(encoder: AudioEncoder.wav);
    await record.start(config, path: "test.m4a");    
    setState(() {
      state = ViewState.recording;
    });
  }

  void _stopRecording() async {
      var path = await record.stop();
      if (path == null) {
        // TODO: Show an error
        print("No path present!");
        setState(() {
          state = ViewState.idle;
        });
        return;
      }
      var buffer = await XFile(path).readAsBytes();
      setState(() {
        state = ViewState.loading;
      });
      var products = await webService.uploadAudioFile(buffer, "recording.wav");
      await record.dispose();
      setState(() {
        state = ViewState.idle;
        fetchedProducts = products;
      });
  }

  void _toggleRecording() async {
    if (state == ViewState.idle) {
      _startRecording();
    } else {
      _stopRecording();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(state.getMessage()),
            fetchedProducts != null ? Text(fetchedProducts!) : Container()
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _toggleRecording,
        tooltip: 'Start recording',
        child: const Icon(Icons.record_voice_over_sharp),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
