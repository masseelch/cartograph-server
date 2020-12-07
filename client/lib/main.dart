import 'dart:convert';

import 'package:client/plan.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/html.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

void main() {
  runApp(MyApp());
}

const sideSize = 300.0;

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(
        title: 'Flutter Demo Home Page',
        channel: kIsWeb
            ? HtmlWebSocketChannel.connect('ws://localhost:8888/ws1')
            : IOWebSocketChannel.connect('ws://10.0.2.2:8888/ws1'),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title, this.channel}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;
  final WebSocketChannel channel;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  void dispose() {
    widget.channel.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: StreamBuilder(
        stream: widget.channel.stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: const CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Text(snapshot.error);
          }

          final game = Game.fromJson(jsonDecode(snapshot.data));

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              SingleChildScrollView(
                child: Column(
                  children: game.players.keys.map((key) {
                    return PlanPreview(plan: game.players[key]);
                  }).toList(),
                ),
              ),
              Container(
                padding: EdgeInsets.all(16),
                child: PlayField(plan: game.players["ws1"]),
              ),
            ],
          );
        },
      ),
    );
  }
}

class PlayField extends StatelessWidget {
  PlayField({@required this.plan}) : assert(plan != null);

  final Plan plan;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 800),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = plan.size;
          final rows = <TableRow>[];

          final height = constraints.maxWidth / plan.size;

          for (int i = 0; i < plan.tiles.length; i += size) {
            final cells = <Widget>[];

            for (int j = i; j < i + size; j++) {
              cells.add(SizedBox(
                height: height,
                child: Center(child: Text(plan.tiles[j].value())),
              ));
            }

            rows.add(TableRow(children: cells));
          }

          return Table(
            border: TableBorder.all(width: 0.5),
            defaultColumnWidth: FixedColumnWidth(height),
            children: rows,
          );
        },
      ),
    );
  }
}

class PlanPreview extends StatelessWidget {
  PlanPreview({@required this.plan}) : assert(plan != null);

  final Plan plan;

  @override
  Widget build(BuildContext context) {
    final size = plan.size;
    final rows = <TableRow>[];

    final height = sideSize / plan.size;

    for (int i = 0; i < plan.tiles.length; i += size) {
      final cells = <Widget>[];

      for (int j = i; j < i + size; j++) {
        cells.add(SizedBox(
          height: height,
          child: Center(child: Text(plan.tiles[j].value())),
        ));
      }

      rows.add(TableRow(children: cells));
    }

    return ConstrainedBox(
      constraints: BoxConstraints.tightFor(width: sideSize),
      child: Table(
        border: TableBorder.all(width: 0.5),
        defaultColumnWidth: FixedColumnWidth(height),
        children: rows,
      ),
    );
  }
}
