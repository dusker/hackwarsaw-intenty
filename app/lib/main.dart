import 'dart:convert';

import 'package:app/product.dart';
import 'package:app/products_list.dart';
import 'package:app/record_web_service.dart';
import 'package:cross_file/cross_file.dart';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:shared_preferences/shared_preferences.dart';

const KEY_PRODUCTS = "products";
const emptyListMessage =
    "Welcome to AI grocery sorter! Press the record button and tell me what products you purchased. Be sure to mention the expiration date!";
const appName = "Kitchen Copilot";

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: appName,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple, brightness: Brightness.dark),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system, // Use system theme mode (light/dark)
      home: const MyHomePage(title: appName),
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

  Icon getFabIcon() {
    switch (this) {
      case ViewState.idle:
        return const Icon(Icons.record_voice_over_rounded);
      case ViewState.loading:
        return const Icon(Icons.record_voice_over_rounded);
      case ViewState.recording:
        return const Icon(Icons.stop);
    }
  }

  bool fabEnabled() {
    return this == ViewState.idle || this == ViewState.recording;
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
  final webService =
      RecordWebService("https://ai-grocery-sorter.fly.dev/upload-audio");
  var state = ViewState.idle;
  List<Product>? fetchedProducts;

  @override
  void initState() {
    super.initState();
    _loadStoredProducts();
  }

  void _loadStoredProducts() async {
    final prefs = await SharedPreferences.getInstance();
    final productsJson = prefs.getString(KEY_PRODUCTS);
    if (productsJson != null) {
      setState(() {
        fetchedProducts = (jsonDecode(productsJson) as List<dynamic>)
            .map((productJson) => Product.fromJson(productJson))
            .toList();
      });
    }
  }

  void _startRecording() async {
    if (!await record.hasPermission()) {
      // TODO: Show an error
      return;
    }
    var config = const RecordConfig(encoder: AudioEncoder.aacLc);
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
    try {
      var products = await webService.uploadAudioFile(buffer, "recording.wav");
      print("did fetch products: $products");
      setState(() async {
        if (fetchedProducts != null) {
          fetchedProducts!.addAll(products);
        } else {
          fetchedProducts = products;
        }

        if (fetchedProducts != null && fetchedProducts!.isNotEmpty) {
          final prefs = await SharedPreferences.getInstance();
          var productsJson = jsonEncode(fetchedProducts);
          prefs.setString(KEY_PRODUCTS, productsJson);
        }
      });
    } catch (error) {
      print(error);
    }
    setState(() {
      state = ViewState.idle;
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
              Expanded(
                  child: Row(
                children: [
                  Expanded(
                    flex: 5,
                    child:
                        fetchedProducts != null && fetchedProducts!.isNotEmpty
                            ? ProductsList(products: fetchedProducts!)
                            : const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('🤖',
                                      style: TextStyle(
                                          fontSize: 40,
                                          fontFamily: "EmojiOne")),
                                  Text(emptyListMessage,
                                      style: TextStyle(fontSize: 18))
                                ],
                              ),
                  ),
                  Container(
                    width: 1,
                    color: Colors.grey,
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                  Expanded(
                    flex: 5,
                    child: Container(
                      alignment: Alignment.center,
                      child: const Text(
                        'Additional Information',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                ],
              ))
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
            onPressed: state.fabEnabled() ? _toggleRecording : null,
            tooltip: 'Toggle recording',
            child: state == ViewState.loading
                ? const CircularProgressIndicator()
                : state.getFabIcon()));
  }
}
