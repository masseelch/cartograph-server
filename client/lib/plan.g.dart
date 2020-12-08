// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plan.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Game _$GameFromJson(Map<String, dynamic> json) {
  return Game()
    ..id = json['id'] as String
    ..players = (json['players'] as Map<String, dynamic>)?.map(
      (k, e) => MapEntry(
          k, e == null ? null : Player.fromJson(e as Map<String, dynamic>)),
    );
}

Player _$PlayerFromJson(Map<String, dynamic> json) {
  return Player()
    ..nickname = json['nickname'] as String
    ..plan = json['plan'] == null
        ? null
        : Plan.fromJson(json['plan'] as Map<String, dynamic>);
}

Map<String, dynamic> _$PlayerToJson(Player instance) => <String, dynamic>{
      'nickname': instance.nickname,
      'plan': instance.plan?.toJson(),
    };

Plan _$PlanFromJson(Map<String, dynamic> json) {
  return Plan()
    ..ruins = (json['ruins'] as List)
        ?.map((e) => e == null ? null : Pos.fromJson(e as Map<String, dynamic>))
        ?.toList()
    ..tiles = (json['tiles'] as List)
        ?.map((e) => _$enumDecodeNullable(_$TerrainEnumMap, e))
        ?.toList();
}

Map<String, dynamic> _$PlanToJson(Plan instance) => <String, dynamic>{
      'ruins': instance.ruins?.map((e) => e?.toJson())?.toList(),
      'tiles': instance.tiles?.map((e) => _$TerrainEnumMap[e])?.toList(),
    };

T _$enumDecode<T>(
  Map<T, dynamic> enumValues,
  dynamic source, {
  T unknownValue,
}) {
  if (source == null) {
    throw ArgumentError('A value must be provided. Supported values: '
        '${enumValues.values.join(', ')}');
  }

  final value = enumValues.entries
      .singleWhere((e) => e.value == source, orElse: () => null)
      ?.key;

  if (value == null && unknownValue == null) {
    throw ArgumentError('`$source` is not one of the supported values: '
        '${enumValues.values.join(', ')}');
  }
  return value ?? unknownValue;
}

T _$enumDecodeNullable<T>(
  Map<T, dynamic> enumValues,
  dynamic source, {
  T unknownValue,
}) {
  if (source == null) {
    return null;
  }
  return _$enumDecode<T>(enumValues, source, unknownValue: unknownValue);
}

const _$TerrainEnumMap = {
  Terrain.blank: 0,
  Terrain.field: 1,
  Terrain.forrest: 2,
  Terrain.monster: 3,
  Terrain.mountains: 4,
  Terrain.village: 5,
  Terrain.water: 6,
};

Pos _$PosFromJson(Map<String, dynamic> json) {
  return Pos(
    json['x'] as int,
    json['y'] as int,
  );
}

Map<String, dynamic> _$PosToJson(Pos instance) => <String, dynamic>{
      'x': instance.x,
      'y': instance.y,
    };
