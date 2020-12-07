import 'dart:math';

import 'package:json_annotation/json_annotation.dart';

part 'plan.g.dart';

enum Terrain {
  @JsonValue(0)
  blank,
  @JsonValue(1)
  field,
  @JsonValue(2)
  forrest,
  @JsonValue(3)
  monster,
  @JsonValue(4)
  mountains,
  @JsonValue(5)
  village,
  @JsonValue(6)
  water,
}

extension TerrainExtension on Terrain {
  String value() {
    switch (this) {
      case Terrain.field:
        return "Ack";
      case Terrain.forrest:
        return "Wal";
      case Terrain.monster:
        return "Mon";
      case Terrain.mountains:
        return "Ber";
      case Terrain.village:
        return "Dor";
      case Terrain.water:
        return "Was";
      default:
        return "";
    }
  }
}

@JsonSerializable(createToJson: false)
class Game {
  Game();

  String id;
  Map<String, Plan> players;

  factory Game.fromJson(Map<String, dynamic> json) => _$GameFromJson(json);
}

@JsonSerializable()
class Plan {
  Plan();

  List<Pos> ruins;
  List<Terrain> tiles;

  int get size => sqrt(tiles.length).toInt();

  factory Plan.fromJson(Map<String, dynamic> json) => _$PlanFromJson(json);

  Map<String, dynamic> toJson() => _$PlanToJson(this);
}

@JsonSerializable()
class Pos {
  Pos(this.x, this.y)
      : assert(x != null),
        assert(y != null);

  int x;
  int y;

  @override
  int get hashCode => '$x-$y'.hashCode;

  @override
  bool operator ==(Object other) =>
      other is Pos && x == other.x && y == other.y;

  factory Pos.fromJson(Map<String, dynamic> json) => _$PosFromJson(json);

  Map<String, dynamic> toJson() => _$PosToJson(this);
}
