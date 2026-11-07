import 'package:flutter/material.dart';

class SchemaColumn {
  final int no;
  final String name;
  final String description;
  final bool hidden;
  final String? label;

  const SchemaColumn(
    this.no,
    this.name,
    this.description, {
    this.hidden = false,
    this.label,
  });

  /// Display heading: explicit [label] when set, otherwise the column name
  /// converted to Title Case words (e.g. `project_name` → `Project Name`).
  String get heading => label ?? _titleCase(name);
}

const Map<String, String> _headingOverrides = {
  'id': 'ID',
  'ids': 'IDs',
  'url': 'URL',
  'mime': 'MIME',
  'm2': 'm²',
};

String _titleCase(String value) {
  final parts = value.split('_').where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return value;
  final buffer = StringBuffer();
  for (final part in parts) {
    if (buffer.isNotEmpty) buffer.write(' ');
    final override = _headingOverrides[part.toLowerCase()];
    if (override != null) {
      buffer.write(override);
    } else {
      buffer.write(part[0].toUpperCase());
      buffer.write(part.substring(1).toLowerCase());
    }
  }
  return buffer.toString();
}

class SchemaTable {
  final String id;
  final String title;
  final String code;
  final IconData icon;
  final List<SchemaColumn> columns;

  const SchemaTable({
    required this.id,
    required this.title,
    required this.code,
    required this.icon,
    required this.columns,
  });
}
