import 'package:flutter/material.dart';
import 'dart:convert';

class ColorPalette {
  final String id;
  final String name;
  final List<Color> colors;
  final String? userId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSync;

  ColorPalette({
    required this.id,
    required this.name,
    required this.colors,
    this.userId,
    required this.createdAt,
    required this.updatedAt,
    this.isSync = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'colors': colors.map((c) => c.value.toRadixString(16)).toList(),
      'user_id': userId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_sync': isSync ? 1 : 0,
    };
  }

  factory ColorPalette.fromMap(Map<String, dynamic> map) {
    return ColorPalette(
      id: map['id'],
      name: map['name'],
      colors: (map['colors'] as List)
          .map((c) => Color(int.parse(c, radix: 16)))
          .toList(),
      userId: map['user_id'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
      isSync: map['is_sync'] == 1,
    );
  }

  String toJson() => json.encode(toMap());

  factory ColorPalette.fromJson(String source) => 
      ColorPalette.fromMap(json.decode(source));

  ColorPalette copyWith({
    String? id,
    String? name,
    List<Color>? colors,
    String? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSync,
  }) {
    return ColorPalette(
      id: id ?? this.id,
      name: name ?? this.name,
      colors: colors ?? this.colors,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSync: isSync ?? this.isSync,
    );
  }
}
