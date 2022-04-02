# Mediarithmics Dart SDK

An SDK provided to mediarithmics clients to help track their mobile apps written
with Dart and Flutter

## Examples


### Basic tracking

```dart
import 'package:mediarithmics_sdk:mediarithmics_sdk.dart';
import 'package:flutter/material.dart';

void main() => runApp(new MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => new _MyAppState();
}

class _MyAppState extends State<MyApp> {
    @override
    Widget build(BuildContext context) {
        MicsSdk sdk = MicsSdk({secretKey: 'abc', keyId: 'def', appId: '1234', datamartId: '5678'});
        sdk.postActivity('page_view', properties:{'page_name': 'homepage'});

        return new MaterialApp(
            home: Scaffold(
                appBar: AppBar(
                    title: Text('Plugin example app'),
                ),
                body: Center(
                    child: Text('Hello, world!'),
                ),
            ),
        );
    }
}

```