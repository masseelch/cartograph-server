import 'dart:async';
import 'dart:convert';


import 'package:http/http.dart' as http;
import 'package:client/plan.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/html.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

const sideSize = 300.0;

class MyApp extends StatelessWidget {
  MyApp({this.url, this.ssl});

  final String url;
  final bool ssl;

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Der Kartograph',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        inputDecorationTheme: const InputDecorationTheme(
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.zero,
          ),
        ),
      ),
      home: MyHomePage(
        url: url,
        ssl: ssl,
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.url, this.ssl}) : super(key: key);

  final String url;
  final bool ssl;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  WebSocketChannel _channel;
  StreamController _broadcast;

  String _nickname;

  Game _game;

  @override
  void dispose() {
    _broadcast?.close();
    _channel?.sink?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Der Kartograph - Ein Online Hilfswerkzeug'),
        actions: _nickname == 'schlumpfmeister' ? [
          IconButton(
            icon: const Icon(Icons.cached),
            onPressed: () async {
              await http.get('${_httpScheme()}://${widget.url}/reboot');
            },
          ),
        ] : null,
      ),
      body: Builder(
        builder: (context) {
          if (_channel == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 200),
                    child: TextField(
                      decoration: const InputDecoration(labelText: 'Nickname'),
                      onChanged: (v) => _nickname = v,
                    ),
                  ),
                  const SizedBox(height: 24),
                  RaisedButton(
                    padding: const EdgeInsets.all(24),
                    color: Theme.of(context).primaryColor,
                    textColor: Theme.of(context).colorScheme.onPrimary,
                    child: const Text('Spielen'),
                    onPressed: () {
                      final url = '${_socketScheme()}://${widget.url}/$_nickname';

                      setState(() {
                        _channel = kIsWeb
                            ? HtmlWebSocketChannel.connect(url)
                            : IOWebSocketChannel.connect(url);
                      });

                      _broadcast = StreamController.broadcast();
                      _broadcast.addStream(_channel.stream);

                      // The first event received after registering is the whole game.
                      _broadcast.stream.first.then((event) {
                        setState(() {
                          _game = Game.fromJson(jsonDecode(event));
                        });
                      });

                      // All events except the first do only contain a player.
                      _broadcast.stream.skip(1).listen((event) {
                        final player = Player.fromJson(jsonDecode(event));

                        setState(() {
                          _game.players[player.nickname] = player;
                        });
                      });
                    },
                  ),
                ],
              ),
            );
          }

          if (_game == null) {
            return const Center(
              child: const CircularProgressIndicator(),
            );
          }

          final size = 800 / _game.players[_nickname].plan.size;

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              SingleChildScrollView(
                child: Column(
                  children: _game.players.keys.map<Widget>((key) {
                    return PlayerPreview(
                      player: _game.players[key],
                      currentNickname: _nickname,
                      onTap: () {
                        // setState(() {
                        //   _nickname = null;
                        // });
                      },
                    );
                  }).toList(),
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ['images/wald.png', Terrain.forrest],
                  ['images/dorf.png', Terrain.village],
                  ['images/acker.png', Terrain.field],
                  ['images/wasser.png', Terrain.water],
                  ['images/monster.png', Terrain.monster],
                ]
                    .map(
                      (asset) => Builder(
                        builder: (context) {
                          final img = Image.asset(asset[0]);
                          final child = SizedBox(
                            width: size,
                            height: size,
                            child: img,
                          );

                          return Draggable(
                            data: asset[1],
                            child: child,
                            childWhenDragging: child,
                            feedback: SizedBox(
                              width: size * 0.8,
                              height: size * 0.8,
                              child: img,
                            ),
                          );
                        },
                      ),
                    )
                    .toList(),
              ),
              Container(
                padding: EdgeInsets.all(16),
                child: PlayField(
                  player: _game.players[_nickname],
                  onChanged: (tiles) {
                    _channel.sink.add(jsonEncode(Terrains(tiles).toJson()));
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _socketScheme() => widget.ssl ? "wss" : "ws";
  String _httpScheme() => widget.ssl ? "https" : "http";
}

class PlayField extends StatefulWidget {
  PlayField({@required this.player, this.onChanged})
      : assert(player != null),
        super(key: ValueKey(player.nickname));

  final Player player;
  final ValueSetter<List<Terrain>> onChanged;

  @override
  _PlayFieldState createState() => _PlayFieldState();
}

class _PlayFieldState extends State<PlayField> {
  List<_Terrain> _tiles;

  int _size;
  int _length;

  @override
  void initState() {
    super.initState();

    _tiles = widget.player.plan.tiles.map((t) => _Terrain(t)).toList();
    _size = widget.player.plan.size;
    _length = _tiles.length;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.player.nickname,
          style: Theme.of(context).textTheme.headline3.copyWith(
                color: Theme.of(context).primaryColor,
              ),
        ),
        Row(
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 800),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final rows = <TableRow>[];

                  final height = constraints.maxWidth / _size;

                  for (int i = 0; i < _length; i += _size) {
                    final cells = <Widget>[];

                    for (int j = i; j < i + _size; j++) {
                      cells.add(DragTarget(
                        key: ValueKey(j),
                        onWillAccept: (_) => !_tiles[j].fixed,
                        onAccept: (terrain) {
                          setState(() {
                            _tiles[j].terrain = terrain;
                          });
                        },
                        builder: (context, candidates, rejected) {
                          if (candidates.length > 0 && !_tiles[j].fixed) {
                            return Opacity(
                              opacity: 0.5,
                              child: TerrainIcon(candidates[0]),
                            );
                          }

                          Widget icon = SizedBox(
                            height: height,
                            child: TerrainIcon(_tiles[j].terrain),
                          );

                          if (!_tiles[j].fixed) {
                            icon = GestureDetector(
                              onDoubleTap: () {
                                setState(() {
                                  _tiles[j].terrain = Terrain.blank;
                                });
                              },
                              child: Opacity(
                                opacity: 0.5,
                                child: icon,
                              ),
                            );
                          }

                          return icon;
                        },
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
            ),
            const SizedBox(width: 36),
            IconButton(
              color: Theme.of(context).primaryColor,
              icon: const Icon(Icons.send),
              iconSize: 64,
              onPressed: () {
                setState(() {
                  _tiles.forEach((tile) {
                    tile.fixed = tile.terrain != Terrain.blank;
                  });
                });
                if (widget.onChanged != null) {
                  widget.onChanged(_tiles.map((t) => t.terrain).toList());
                }
              },
            ),
          ],
        ),
      ],
    );
  }
}

class TerrainIcon extends StatelessWidget {
  TerrainIcon(this.terrain) : assert(terrain != null);

  final Terrain terrain;

  @override
  Widget build(BuildContext context) {
    String asset = 'images/';

    switch (terrain) {
      case Terrain.field:
        asset += 'acker';
        break;
      case Terrain.forrest:
        asset += 'wald';
        break;
      case Terrain.monster:
        asset += 'monster';
        break;
      case Terrain.mountains:
        asset += 'gebirge';
        break;
      case Terrain.village:
        asset += 'dorf';
        break;
      case Terrain.water:
        asset += 'wasser';
        break;
      default:
        return const SizedBox.shrink();
    }

    return Image.asset('$asset.png');
  }
}

class PlayerPreview extends StatelessWidget {
  PlayerPreview({
    @required this.player,
    @required this.currentNickname,
    this.onTap,
  })  : assert(player != null),
        assert(currentNickname != null && currentNickname != "");

  final Player player;
  final String currentNickname;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final size = player.plan.size;
    final rows = <TableRow>[];

    final height = sideSize / player.plan.size;

    for (int i = 0; i < player.plan.tiles.length; i += size) {
      final cells = <Widget>[];

      for (int j = i; j < i + size; j++) {
        cells.add(SizedBox(
          height: height,
          child: Center(child: TerrainIcon(player.plan.tiles[j])),
        ));
      }

      rows.add(TableRow(children: cells));
    }

    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: BoxConstraints.tightFor(width: sideSize),
        padding: EdgeInsets.all(10),
        margin: EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          border: Border.all(
            color: currentNickname == player.nickname
                ? Theme.of(context).primaryColor
                : Colors.black,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(player.nickname, style: Theme.of(context).textTheme.subtitle1),
            Table(
              border: TableBorder.all(width: 0.5),
              defaultColumnWidth: FixedColumnWidth(height),
              children: rows,
            ),
          ],
        ),
      ),
    );
  }
}

class _Terrain {
  _Terrain(this.terrain) : fixed = terrain != Terrain.blank;

  bool fixed;
  Terrain terrain;
}
