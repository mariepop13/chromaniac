import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:uuid/uuid.dart';

class ColorPalette {
  final String id;
  final String name;
  final List<Color> colors;
  final String? userId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSync;
  final String? aiOutput;
  final String? description;

  ColorPalette({
    required this.id,
    required this.name,
    required this.colors,
    this.userId,
    required this.createdAt,
    required this.updatedAt,
    this.isSync = false,
    this.aiOutput,
    this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'colors': colors.map((c) => c.value.toRadixString(16).padLeft(8, '0')).toList(),
      'user_id': userId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_sync': isSync ? 1 : 0,
      'ai_output': aiOutput,
      'description': description,
    };
  }

  factory ColorPalette.fromMap(Map<String, dynamic> map) {
    final colorsList = map['colors'] as List;
    return ColorPalette(
      id: map['id'] ?? const Uuid().v4(),
      name: map['name'] ?? '',
      colors: colorsList.map((c) {
        if (c is String) {
          // Ensure we have 8 digits for ARGB
          final colorStr = c.padLeft(8, '0');
          return Color(int.parse(colorStr, radix: 16));
        } else if (c is int) {
          // Add full opacity if alpha is 0
          return Color(c | 0xFF000000);
        } else {
          throw FormatException('Invalid color format: $c');
        }
      }).toList(),
      userId: map['user_id'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
      isSync: map['is_sync'] == 1,
      aiOutput: map['ai_output'],
      description: map['description'],
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
    String? aiOutput,
    String? description,
  }) {
    return ColorPalette(
      id: id ?? this.id,
      name: name ?? this.name,
      colors: colors ?? this.colors,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSync: isSync ?? this.isSync,
      aiOutput: aiOutput ?? this.aiOutput,
      description: description ?? this.description,
    );
  }
}
