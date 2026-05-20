double asDouble(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value.trim()) ?? 0;
  return 0;
}

double? asNullableDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value.trim());
  return null;
}

double? numFromPath(Map<String, dynamic>? map, List<String> path) {
  dynamic current = map;
  for (final key in path) {
    if (current is! Map) return null;
    current = current[key];
  }
  if (current is num) return current.toDouble();
  return null;
}
