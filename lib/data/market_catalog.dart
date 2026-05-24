import '../models/market_option.dart';

/// Local fallback catalog for market search.
///
/// This is intentionally small: realtime/search still uses the aggregation API
/// when configured. The local catalog only keeps common items so suggestions are
/// useful while offline and symbols can be normalized before saving.
const List<MarketOption> kMarketCatalog = [
  // Precious metals
  MarketOption(assetType: 'metal', name: '黄金', symbol: 'XAU', displayCode: 'XAU', quoteCurrency: 'USD', unit: 'gram', aliases: ['gold', 'au', '黄金现货']),
  MarketOption(assetType: 'metal', name: '白银', symbol: 'XAG', displayCode: 'XAG', quoteCurrency: 'USD', unit: 'gram', aliases: ['silver', 'ag', '白银现货']),
  MarketOption(assetType: 'metal', name: '铂金', symbol: 'XPT', displayCode: 'XPT', quoteCurrency: 'USD', unit: 'gram', aliases: ['platinum', 'pt']),
  MarketOption(assetType: 'metal', name: '钯金', symbol: 'XPD', displayCode: 'XPD', quoteCurrency: 'USD', unit: 'gram', aliases: ['palladium', 'pd']),

  // Crypto. symbol uses CoinGecko ID because the aggregation API expects ids like solana/bitcoin/tether.
  MarketOption(assetType: 'crypto', name: 'Bitcoin', symbol: 'bitcoin', displayCode: 'BTC', quoteCurrency: 'USD', aliases: ['btc', 'xbt', '比特币']),
  MarketOption(assetType: 'crypto', name: 'Ethereum', symbol: 'ethereum', displayCode: 'ETH', quoteCurrency: 'USD', aliases: ['eth', '以太坊']),
  MarketOption(assetType: 'crypto', name: 'Tether USDt', symbol: 'tether', displayCode: 'USDT', quoteCurrency: 'USD', aliases: ['usdt', 'tether', '泰达币']),
  MarketOption(assetType: 'crypto', name: 'USD Coin', symbol: 'usd-coin', displayCode: 'USDC', quoteCurrency: 'USD', aliases: ['usdc']),
  MarketOption(assetType: 'crypto', name: 'Solana', symbol: 'solana', displayCode: 'SOL', quoteCurrency: 'USD', aliases: ['sol']),
  MarketOption(assetType: 'crypto', name: 'BNB', symbol: 'binancecoin', displayCode: 'BNB', quoteCurrency: 'USD', aliases: ['bnb', 'binance coin', '币安币']),
  MarketOption(assetType: 'crypto', name: 'XRP', symbol: 'ripple', displayCode: 'XRP', quoteCurrency: 'USD', aliases: ['ripple']),
  MarketOption(assetType: 'crypto', name: 'TRON', symbol: 'tron', displayCode: 'TRX', quoteCurrency: 'USD', aliases: ['trx', '波场']),
  MarketOption(assetType: 'crypto', name: 'Dogecoin', symbol: 'dogecoin', displayCode: 'DOGE', quoteCurrency: 'USD', aliases: ['doge', '狗狗币']),
  MarketOption(assetType: 'crypto', name: 'Cardano', symbol: 'cardano', displayCode: 'ADA', quoteCurrency: 'USD', aliases: ['ada']),
  MarketOption(assetType: 'crypto', name: 'Chainlink', symbol: 'chainlink', displayCode: 'LINK', quoteCurrency: 'USD', aliases: ['link']),
  MarketOption(assetType: 'crypto', name: 'Litecoin', symbol: 'litecoin', displayCode: 'LTC', quoteCurrency: 'USD', aliases: ['ltc', '莱特币']),

  // US stocks
  MarketOption(assetType: 'stock', name: 'Apple Inc.', symbol: 'AAPL', displayCode: 'AAPL', quoteCurrency: 'USD', aliases: ['apple', '苹果']),
  MarketOption(assetType: 'stock', name: 'Tesla Inc.', symbol: 'TSLA', displayCode: 'TSLA', quoteCurrency: 'USD', aliases: ['tesla', '特斯拉']),
  MarketOption(assetType: 'stock', name: 'NVIDIA Corp.', symbol: 'NVDA', displayCode: 'NVDA', quoteCurrency: 'USD', aliases: ['nvidia', '英伟达']),
  MarketOption(assetType: 'stock', name: 'Microsoft Corp.', symbol: 'MSFT', displayCode: 'MSFT', quoteCurrency: 'USD', aliases: ['microsoft', '微软']),
  MarketOption(assetType: 'stock', name: 'Amazon.com Inc.', symbol: 'AMZN', displayCode: 'AMZN', quoteCurrency: 'USD', aliases: ['amazon', '亚马逊']),
  MarketOption(assetType: 'stock', name: 'Meta Platforms Inc.', symbol: 'META', displayCode: 'META', quoteCurrency: 'USD', aliases: ['meta', 'facebook', '脸书']),
  MarketOption(assetType: 'stock', name: 'Alphabet Inc. Class A', symbol: 'GOOGL', displayCode: 'GOOGL', quoteCurrency: 'USD', aliases: ['google', 'alphabet', '谷歌']),
  MarketOption(assetType: 'stock', name: 'Interactive Brokers Group Inc.', symbol: 'IBKR', displayCode: 'IBKR', quoteCurrency: 'USD', aliases: ['interactive brokers', '盈透证券', '盈透']),
  MarketOption(assetType: 'stock', name: 'SanDisk Corp.', symbol: 'SNDK', displayCode: 'SNDK', quoteCurrency: 'USD', aliases: ['sandisk', '闪迪']),
  MarketOption(assetType: 'stock', name: 'Micron Technology Inc.', symbol: 'MU', displayCode: 'MU', quoteCurrency: 'USD', aliases: ['micron', '美光']),
  MarketOption(assetType: 'stock', name: 'Western Digital Corp.', symbol: 'WDC', displayCode: 'WDC', quoteCurrency: 'USD', aliases: ['western digital', '西部数据']),

  // US ETFs
  MarketOption(assetType: 'etf', name: 'Invesco QQQ Trust', symbol: 'QQQ', displayCode: 'QQQ', quoteCurrency: 'USD', aliases: ['nasdaq 100', '纳指100', '纳斯达克100']),
  MarketOption(assetType: 'etf', name: 'Invesco NASDAQ 100 ETF', symbol: 'QQQM', displayCode: 'QQQM', quoteCurrency: 'USD', aliases: ['qqq mini', 'nasdaq 100']),
  MarketOption(assetType: 'etf', name: 'SPDR S&P 500 ETF Trust', symbol: 'SPY', displayCode: 'SPY', quoteCurrency: 'USD', aliases: ['s&p 500', 'sp500', '标普500']),
  MarketOption(assetType: 'etf', name: 'Vanguard S&P 500 ETF', symbol: 'VOO', displayCode: 'VOO', quoteCurrency: 'USD', aliases: ['vanguard sp500']),
  MarketOption(assetType: 'etf', name: 'iShares Core S&P 500 ETF', symbol: 'IVV', displayCode: 'IVV', quoteCurrency: 'USD', aliases: ['ishares sp500']),
  MarketOption(assetType: 'etf', name: 'Schwab U.S. Dividend Equity ETF', symbol: 'SCHD', displayCode: 'SCHD', quoteCurrency: 'USD', aliases: ['dividend', '股息']),
  MarketOption(assetType: 'etf', name: 'iShares 0-3 Month Treasury Bond ETF', symbol: 'SGOV', displayCode: 'SGOV', quoteCurrency: 'USD', aliases: ['treasury', '短债', '国债']),
  MarketOption(assetType: 'etf', name: 'Vanguard Total International Stock ETF', symbol: 'VXUS', displayCode: 'VXUS', quoteCurrency: 'USD', aliases: ['international stock', '海外股票']),

  // A shares
  MarketOption(assetType: 'cn_stock', name: '贵州茅台', symbol: '600519', displayCode: '600519', quoteCurrency: 'CNY', aliases: ['茅台', '贵州茅台', 'moutai']),
  MarketOption(assetType: 'cn_stock', name: '平安银行', symbol: '000001', displayCode: '000001', quoteCurrency: 'CNY', aliases: ['平安', '平安银行']),
  MarketOption(assetType: 'cn_stock', name: '宁德时代', symbol: '300750', displayCode: '300750', quoteCurrency: 'CNY', aliases: ['宁德', '宁德时代', 'catl']),
  MarketOption(assetType: 'cn_stock', name: '中国平安', symbol: '601318', displayCode: '601318', quoteCurrency: 'CNY', aliases: ['中国平安', '平安保险']),
  MarketOption(assetType: 'cn_stock', name: '招商银行', symbol: '600036', displayCode: '600036', quoteCurrency: 'CNY', aliases: ['招行', '招商银行']),
  MarketOption(assetType: 'cn_stock', name: '五粮液', symbol: '000858', displayCode: '000858', quoteCurrency: 'CNY', aliases: ['五粮液']),
  MarketOption(assetType: 'cn_stock', name: '比亚迪', symbol: '002594', displayCode: '002594', quoteCurrency: 'CNY', aliases: ['比亚迪', 'byd']),
  MarketOption(assetType: 'cn_stock', name: '迈瑞医疗', symbol: '300760', displayCode: '300760', quoteCurrency: 'CNY', aliases: ['迈瑞', '迈瑞医疗']),

  // A-share ETFs
  MarketOption(assetType: 'cn_etf', name: '沪深300ETF', symbol: '510300', displayCode: '510300', quoteCurrency: 'CNY', aliases: ['沪深300', '300etf']),
  MarketOption(assetType: 'cn_etf', name: '上证50ETF', symbol: '510050', displayCode: '510050', quoteCurrency: 'CNY', aliases: ['上证50', '50etf']),
  MarketOption(assetType: 'cn_etf', name: '中证500ETF', symbol: '510500', displayCode: '510500', quoteCurrency: 'CNY', aliases: ['中证500', '500etf']),
  MarketOption(assetType: 'cn_etf', name: '科创50ETF', symbol: '588000', displayCode: '588000', quoteCurrency: 'CNY', aliases: ['科创50', '科创板50']),
  MarketOption(assetType: 'cn_etf', name: '创业板ETF', symbol: '159915', displayCode: '159915', quoteCurrency: 'CNY', aliases: ['创业板', '创业板etf']),
  MarketOption(assetType: 'cn_etf', name: '证券ETF', symbol: '512880', displayCode: '512880', quoteCurrency: 'CNY', aliases: ['证券etf', '券商etf']),
  MarketOption(assetType: 'cn_etf', name: '中概互联网ETF', symbol: '513050', displayCode: '513050', quoteCurrency: 'CNY', aliases: ['中概互联网', '中概互联']),
  MarketOption(assetType: 'cn_etf', name: '纳指ETF', symbol: '513100', displayCode: '513100', quoteCurrency: 'CNY', aliases: ['纳指etf', '纳斯达克etf']),
];

List<MarketOption> marketSuggestionsFor(String assetType, String query, {int limit = 3}) {
  final matches = kMarketCatalog.where((item) => item.assetType == assetType && item.matches(query)).toList();

  matches.sort((a, b) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return a.displayCode.compareTo(b.displayCode);

    int score(MarketOption item) {
      final values = [item.displayCode, item.symbol, item.name, ...item.aliases].map((e) => e.toLowerCase());
      if (values.any((v) => v == q)) return 0;
      if (values.any((v) => v.startsWith(q))) return 1;
      return 2;
    }

    final result = score(a).compareTo(score(b));
    if (result != 0) return result;
    return a.displayCode.compareTo(b.displayCode);
  });

  return matches.take(limit).toList();
}

MarketOption? exactMarketOption(String assetType, String query) {
  final q = query.trim();
  if (q.isEmpty) return null;

  for (final option in kMarketCatalog.where((item) => item.assetType == assetType)) {
    if (option.exactMatches(q)) return option;
  }
  return null;
}

List<MarketOption> mergeMarketSuggestions(List<MarketOption> local, List<MarketOption> remote, {int limit = 3}) {
  final map = <String, MarketOption>{};
  for (final item in [...local, ...remote]) {
    if (item.symbol.trim().isEmpty) continue;
    map.putIfAbsent(item.key, () => item);
  }
  return map.values.take(limit).toList();
}
