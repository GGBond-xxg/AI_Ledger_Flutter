class MarketOption {
  const MarketOption({
    required this.assetType,
    required this.name,
    required this.symbol,
    required this.displayCode,
    required this.quoteCurrency,
    this.unit = '',
    this.aliases = const [],
    this.provider = 'local',
    this.subtitle = '',
  });

  final String assetType;
  final String name;
  final String symbol;
  final String displayCode;
  final String quoteCurrency;
  final String unit;
  final List<String> aliases;
  final String provider;
  final String subtitle;

  factory MarketOption.fromJson(Map<String, dynamic> json) {
    return MarketOption(
      assetType: json['assetType'] as String? ?? json['type'] as String? ?? 'stock',
      name: json['name'] as String? ?? '',
      symbol: json['symbol'] as String? ?? '',
      displayCode: json['displayCode'] as String? ?? json['display_code'] as String? ?? json['symbol'] as String? ?? '',
      quoteCurrency: (json['quoteCurrency'] as String? ?? json['currency'] as String? ?? 'USD').toUpperCase(),
      unit: json['unit'] as String? ?? '',
      aliases: ((json['aliases'] as List?) ?? []).whereType<String>().toList(),
      provider: json['provider'] as String? ?? 'remote',
      subtitle: json['subtitle'] as String? ?? '',
    );
  }

  bool matches(String query) {
    final q = _n(query);
    if (q.isEmpty) return true;
    return _n(name).contains(q) ||
        _n(symbol).contains(q) ||
        _n(displayCode).contains(q) ||
        aliases.any((e) => _n(e).contains(q));
  }

  bool exactMatches(String query) {
    final q = _n(query);
    if (q.isEmpty) return false;
    return _n(name) == q ||
        _n(symbol) == q ||
        _n(displayCode) == q ||
        aliases.any((e) => _n(e) == q);
  }

  String get key => '$assetType:${symbol.toUpperCase()}';
}

String _n(String value) => value.trim().toLowerCase();
