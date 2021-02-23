import 'dart:async';
import 'dart:convert';

import 'package:client/plan.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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
        actions: _nickname == 'schlumpfmeister'
            ? [
                IconButton(
                  icon: const Icon(Icons.cached),
                  onPressed: () async {
                    await http.get(
                        '${_httpScheme()}://${widget.url.replaceAll("-ws", "")}/reboot');
                  },
                ),
              ]
            : null,
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
                      autofocus: true,
                      onChanged: (v) => _nickname = v,
                      onSubmitted: (v) {
                        if (_nickname.isNotEmpty) {
                          _connect();
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  RaisedButton(
                    padding: const EdgeInsets.all(24),
                    color: Theme.of(context).primaryColor,
                    textColor: Theme.of(context).colorScheme.onPrimary,
                    child: const Text('Spielen'),
                    onPressed: () {
                      _connect();
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
              Scrollbar(
                child: SingleChildScrollView(
                  child: Column(
                    children: _game.players.keys.map<Widget>((key) {
                      return PlayerPreview(
                        player: _game.players[key],
                        currentNickname: _nickname,
                      );
                    }).toList(),
                  ),
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
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

                              return Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8),
                                child: Draggable(
                                  data: asset[1],
                                  child: child,
                                  childWhenDragging: child,
                                  feedback: SizedBox(
                                    width: size * 0.8,
                                    height: size * 0.8,
                                    child: img,
                                  ),
                                  onDragStarted: () {
                                    FocusScope.of(context).unfocus();
                                  },
                                ),
                              );
                            },
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 36),
                  Row(
                    children: [
                      RatingBox(
                        title: 'Frühling',
                        rating: _game.players[_nickname].plan.ratings[0],
                        onChanged: (r) {
                          setState(() {
                            _game.players[_nickname].plan.ratings[0] = r;
                          });
                        },
                      ),
                      const SizedBox(width: 36),
                      RatingBox(
                        title: 'Sommer',
                        rating: _game.players[_nickname].plan.ratings[1],
                        onChanged: (r) {
                          setState(() {
                            _game.players[_nickname].plan.ratings[1] = r;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 36),
                  Row(
                    children: [
                      RatingBox(
                        title: 'Herbst',
                        rating: _game.players[_nickname].plan.ratings[2],
                        onChanged: (r) {
                          setState(() {
                            _game.players[_nickname].plan.ratings[2] = r;
                          });
                        },
                      ),
                      const SizedBox(width: 36),
                      RatingBox(
                        title: 'Winter',
                        rating: _game.players[_nickname].plan.ratings[3],
                        onChanged: (r) {
                          setState(() {
                            _game.players[_nickname].plan.ratings[3] = r;
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.all(16),
                child: PlayField(
                  player: _game.players[_nickname],
                  onChanged: (plan) {
                    _channel.sink.add(jsonEncode(plan.toJson()));
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

  void _connect() {
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
  }
}

class RatingBox extends StatefulWidget {
  RatingBox({
    @required this.rating,
    @required this.title,
    this.onChanged,
  })  : assert(rating != null),
        assert(title != null);

  final Rating rating;
  final String title;
  final ValueChanged<Rating> onChanged;

  @override
  _RatingBoxState createState() => _RatingBoxState();
}

class _RatingBoxState extends State<RatingBox> {
  Rating _rating;

  TextEditingController _firstController;
  TextEditingController _secondController;
  TextEditingController _goldController;
  TextEditingController _monsterController;

  @override
  void initState() {
    super.initState();

    _rating = widget.rating;
    _firstController = TextEditingController(
      text: _rating.first?.toString(),
    );
    _secondController = TextEditingController(
      text: _rating.second?.toString(),
    );
    _goldController = TextEditingController(
      text: _rating.gold?.toString(),
    );
    _monsterController = TextEditingController(
      text: _rating.monster?.toString(),
    );
  }

  @override
  void dispose() {
    _firstController.dispose();
    _secondController.dispose();
    _goldController.dispose();
    _monsterController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(),
      ),
      child: Column(
        children: [
          Text(
            widget.title,
            style: Theme.of(context).textTheme.headline5,
          ),
          Table(
            defaultColumnWidth: FixedColumnWidth(50),
            children: [
              TableRow(
                children: [
                  TextField(
                    controller: _firstController,
                    onChanged: (v) {
                      final value = int.tryParse(v);
                      if (value != null && value != _rating.first) {
                        _rating.first = value;
                        widget.onChanged?.call(_rating);
                      }
                    },
                  ),
                  TextField(
                    controller: _secondController,
                    onChanged: (v) {
                      final value = int.tryParse(v);
                      if (value != null && value != _rating.second) {
                        _rating.second = value;
                        widget.onChanged?.call(_rating);
                      }
                    },
                  ),
                ],
              ),
              TableRow(
                children: [
                  TextField(
                    controller: _goldController,
                    onChanged: (v) {
                      final value = int.tryParse(v);
                      if (value != null && value != _rating.gold) {
                        _rating.gold = value;
                        widget.onChanged?.call(_rating);
                      }
                    },
                  ),
                  TextField(
                    controller: _monsterController,
                    onChanged: (v) {
                      final value = int.tryParse(v);
                      if (value != null && value != _rating.monster) {
                        _rating.monster = value;
                        widget.onChanged?.call(_rating);
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class PlayField extends StatefulWidget {
  PlayField({@required this.player, this.onChanged})
      : assert(player != null),
        super(key: ValueKey(player.nickname));

  final Player player;
  final ValueSetter<Plan> onChanged;

  @override
  _PlayFieldState createState() => _PlayFieldState();
}

class _PlayFieldState extends State<PlayField> {
  List<_Terrain> _tiles;
  int _gold;

  int _size;
  int _length;

  @override
  void initState() {
    super.initState();

    _gold = widget.player.plan.gold;
    _tiles = widget.player.plan.tiles.map((t) => _Terrain(t)).toList();
    _size = widget.player.plan.size;
    _length = _tiles.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.player.nickname} (${widget.player.plan.score} Punkte)',
              style: Theme.of(context).textTheme.headline3.copyWith(
                    color: Theme.of(context).primaryColor,
                  ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
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

                              if (_tiles[j].terrain == Terrain.blank &&
                                  widget.player.plan.ruins.contains(
                                    Pos.fromIndex(
                                      length: _size,
                                      index: j,
                                    ),
                                  )) {
                                return SizedBox(
                                  height: height,
                                  child: Center(
                                    child: Image.asset('images/ruinen.png'),
                                  ),
                                );
                              } else {
                                Widget icon = SizedBox(
                                  height: height,
                                  child: TerrainIcon(_tiles[j].terrain),
                                );

                                if (_tiles[j].terrain == Terrain.mountains) {
                                  icon = GestureDetector(
                                    onDoubleTap: () {
                                      setState(() {
                                        _tiles[j].terrain =
                                            Terrain.mountainsGoldStrike;
                                      });
                                    },
                                    child: icon,
                                  );
                                } else if (_tiles[j].terrain ==
                                    Terrain.mountainsGoldStrike) {
                                  icon = GestureDetector(
                                    onDoubleTap: () {
                                      setState(() {
                                        _tiles[j].terrain = Terrain.mountains;
                                      });
                                    },
                                    child: icon,
                                  );
                                } else if (!_tiles[j].fixed) {
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
                              }
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
                Column(
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: List<Widget>.generate(
                              7,
                              (index) => Coin(
                                    gold: index < _gold,
                                    onTap: () {
                                      setState(() {
                                        _gold =
                                            _gold + (index < _gold ? -1 : 1);
                                      });
                                    },
                                  )),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: List<Widget>.generate(
                              7,
                              (index) => Coin(
                                    gold: index + 7 < _gold,
                                    onTap: () {
                                      setState(() {
                                        _gold = _gold +
                                            (index + 7 < _gold ? -1 : 1);
                                      });
                                      _onChanged();
                                    },
                                  )),
                        ),
                      ],
                    ),
                    const SizedBox(height: 36),
                    IconButton(
                      color: Theme.of(context).primaryColor,
                      icon: const Icon(Icons.send),
                      iconSize: 64,
                      onPressed: () {
                        FocusScope.of(context).unfocus();
                        setState(() {
                          _tiles.forEach((tile) {
                            tile.fixed = tile.terrain != Terrain.blank;
                          });
                        });
                        _onChanged();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _onChanged() {
    if (widget.onChanged != null) {
      final plan = widget.player.plan;
      plan.tiles = _tiles.map((t) => t.terrain).toList();
      plan.gold = _gold;
      widget.onChanged(plan);
    }
  }
}

class Coin extends StatelessWidget {
  Coin({
    @required this.gold,
    this.onTap,
    this.dense = false,
  }) : assert(gold != null);

  final bool gold;
  final bool dense;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        onTap?.call();
      },
      child: Image.asset(
        gold ? 'images/golden_coin.png' : 'images/black_coin.png',
        width: dense ? 18 : 40,
      ),
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
        asset += 'acker.png';
        break;
      case Terrain.forrest:
        asset += 'wald.png';
        break;
      case Terrain.monster:
        asset += 'monster.png';
        break;
      case Terrain.mountains:
        asset += 'gebirge.png';
        break;
      case Terrain.mountainsGoldStrike:
        asset += 'gebirge_coin.jpg';
        break;
      case Terrain.village:
        asset += 'dorf.png';
        break;
      case Terrain.water:
        asset += 'wasser.png';
        break;
      default:
        return const SizedBox.shrink();
    }

    return Image.asset('$asset');
  }
}

class PlayerPreview extends StatelessWidget {
  PlayerPreview({
    @required this.player,
    @required this.currentNickname,
  })  : assert(player != null),
        assert(currentNickname != null && currentNickname != "");

  final Player player;
  final String currentNickname;

  @override
  Widget build(BuildContext context) {
    final size = player.plan.size;
    final rows = <TableRow>[];

    final height = (sideSize - 20) / player.plan.size;

    for (int i = 0; i < player.plan.tiles.length; i += size) {
      final cells = <Widget>[];

      for (int j = i; j < i + size; j++) {
        if (player.plan.tiles[j] == Terrain.blank &&
            player.plan.ruins.contains(
              Pos.fromIndex(
                length: size,
                index: j,
              ),
            )) {
          cells.add(SizedBox(
            height: height,
            child: Center(child: Image.asset('images/ruinen.png')),
          ));
        } else {
          cells.add(SizedBox(
            height: height,
            child: Center(child: TerrainIcon(player.plan.tiles[j])),
          ));
        }
      }

      rows.add(TableRow(children: cells));
    }

    return Container(
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
          Text(
            '${player.nickname} (${player.plan.score} Punkte)',
            style: Theme.of(context).textTheme.subtitle1,
          ),
          Table(
            border: TableBorder.all(width: 0.5),
            defaultColumnWidth: FixedColumnWidth(height),
            children: rows,
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              14,
              (index) => Coin(gold: index < player.plan.gold, dense: true),
            ),
          ),
        ],
      ),
    );
  }
}

class _Terrain {
  _Terrain(this.terrain) : fixed = terrain != Terrain.blank;

  bool fixed;
  Terrain terrain;
}
