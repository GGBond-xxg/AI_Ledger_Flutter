import '../models/market_option.dart';

const List<MarketOption> kMarketCatalog = [
  // Metals
  MarketOption(assetType: 'metal', name: '黄金', symbol: 'XAU', displayCode: 'XAU', quoteCurrency: 'USD', unit: 'gram', aliases: ['gold', 'au', '黄金现货']),
  MarketOption(assetType: 'metal', name: '白银', symbol: 'XAG', displayCode: 'XAG', quoteCurrency: 'USD', unit: 'gram', aliases: ['silver', 'ag', '白银现货']),
  MarketOption(assetType: 'metal', name: '铂金', symbol: 'XPT', displayCode: 'XPT', quoteCurrency: 'USD', unit: 'gram', aliases: ['platinum', 'pt']),
  MarketOption(assetType: 'metal', name: '钯金', symbol: 'XPD', displayCode: 'XPD', quoteCurrency: 'USD', unit: 'gram', aliases: ['palladium', 'pd']),

  // Crypto fallback list. symbol uses CoinGecko ID because the aggregation API expects ids like solana/bitcoin/tether.
  MarketOption(assetType: 'crypto', name: 'Bitcoin', symbol: 'bitcoin', displayCode: 'BTC', quoteCurrency: 'USD', aliases: ['btc', 'xbt', '比特币']),
  MarketOption(assetType: 'crypto', name: 'Ethereum', symbol: 'ethereum', displayCode: 'ETH', quoteCurrency: 'USD', aliases: ['eth', '以太坊']),
  MarketOption(assetType: 'crypto', name: 'Tether USDt', symbol: 'tether', displayCode: 'USDT', quoteCurrency: 'USD', aliases: ['usdt', 'tether', '泰达币']),
  MarketOption(assetType: 'crypto', name: 'XRP', symbol: 'ripple', displayCode: 'XRP', quoteCurrency: 'USD', aliases: ['ripple']),
  MarketOption(assetType: 'crypto', name: 'BNB', symbol: 'binancecoin', displayCode: 'BNB', quoteCurrency: 'USD', aliases: ['bnb', 'binance coin', '币安币']),
  MarketOption(assetType: 'crypto', name: 'Solana', symbol: 'solana', displayCode: 'SOL', quoteCurrency: 'USD', aliases: ['sol']),
  MarketOption(assetType: 'crypto', name: 'USD Coin', symbol: 'usd-coin', displayCode: 'USDC', quoteCurrency: 'USD', aliases: ['usdc']),
  MarketOption(assetType: 'crypto', name: 'TRON', symbol: 'tron', displayCode: 'TRX', quoteCurrency: 'USD', aliases: ['trx', '波场']),
  MarketOption(assetType: 'crypto', name: 'Dogecoin', symbol: 'dogecoin', displayCode: 'DOGE', quoteCurrency: 'USD', aliases: ['doge', '狗狗币']),
  MarketOption(assetType: 'crypto', name: 'Cardano', symbol: 'cardano', displayCode: 'ADA', quoteCurrency: 'USD', aliases: ['ada']),
  MarketOption(assetType: 'crypto', name: 'Hyperliquid', symbol: 'hyperliquid', displayCode: 'HYPE', quoteCurrency: 'USD', aliases: ['hype']),
  MarketOption(assetType: 'crypto', name: 'Chainlink', symbol: 'chainlink', displayCode: 'LINK', quoteCurrency: 'USD', aliases: ['link']),
  MarketOption(assetType: 'crypto', name: 'Bitcoin Cash', symbol: 'bitcoin-cash', displayCode: 'BCH', quoteCurrency: 'USD', aliases: ['bch']),
  MarketOption(assetType: 'crypto', name: 'Stellar', symbol: 'stellar', displayCode: 'XLM', quoteCurrency: 'USD', aliases: ['xlm']),
  MarketOption(assetType: 'crypto', name: 'Sui', symbol: 'sui', displayCode: 'SUI', quoteCurrency: 'USD', aliases: ['sui']),
  MarketOption(assetType: 'crypto', name: 'Avalanche', symbol: 'avalanche-2', displayCode: 'AVAX', quoteCurrency: 'USD', aliases: ['avax']),
  MarketOption(assetType: 'crypto', name: 'Litecoin', symbol: 'litecoin', displayCode: 'LTC', quoteCurrency: 'USD', aliases: ['ltc', '莱特币']),
  MarketOption(assetType: 'crypto', name: 'Toncoin', symbol: 'the-open-network', displayCode: 'TON', quoteCurrency: 'USD', aliases: ['ton', 'toncoin']),
  MarketOption(assetType: 'crypto', name: 'Shiba Inu', symbol: 'shiba-inu', displayCode: 'SHIB', quoteCurrency: 'USD', aliases: ['shib']),
  MarketOption(assetType: 'crypto', name: 'Polkadot', symbol: 'polkadot', displayCode: 'DOT', quoteCurrency: 'USD', aliases: ['dot']),
  MarketOption(assetType: 'crypto', name: 'Uniswap', symbol: 'uniswap', displayCode: 'UNI', quoteCurrency: 'USD', aliases: ['uni']),
  MarketOption(assetType: 'crypto', name: 'Pepe', symbol: 'pepe', displayCode: 'PEPE', quoteCurrency: 'USD', aliases: ['pepe']),

  // Stocks
  MarketOption(assetType: 'stock', name: 'Apple Inc.', symbol: 'AAPL', displayCode: 'AAPL', quoteCurrency: 'USD', aliases: ['apple', '苹果']),
  MarketOption(assetType: 'stock', name: 'Tesla Inc.', symbol: 'TSLA', displayCode: 'TSLA', quoteCurrency: 'USD', aliases: ['tesla', '特斯拉']),
  MarketOption(assetType: 'stock', name: 'Microsoft Corp.', symbol: 'MSFT', displayCode: 'MSFT', quoteCurrency: 'USD', aliases: ['microsoft', '微软']),
  MarketOption(assetType: 'stock', name: 'NVIDIA Corp.', symbol: 'NVDA', displayCode: 'NVDA', quoteCurrency: 'USD', aliases: ['nvidia', '英伟达']),
  MarketOption(assetType: 'stock', name: 'Amazon.com Inc.', symbol: 'AMZN', displayCode: 'AMZN', quoteCurrency: 'USD', aliases: ['amazon', '亚马逊']),
  MarketOption(assetType: 'stock', name: 'Alphabet Inc. Class A', symbol: 'GOOGL', displayCode: 'GOOGL', quoteCurrency: 'USD', aliases: ['google', 'alphabet', '谷歌']),
  MarketOption(assetType: 'stock', name: 'Alphabet Inc. Class C', symbol: 'GOOG', displayCode: 'GOOG', quoteCurrency: 'USD', aliases: ['google c', 'alphabet c']),
  MarketOption(assetType: 'stock', name: 'Meta Platforms Inc.', symbol: 'META', displayCode: 'META', quoteCurrency: 'USD', aliases: ['meta', 'facebook', '脸书']),
  MarketOption(assetType: 'stock', name: 'Netflix Inc.', symbol: 'NFLX', displayCode: 'NFLX', quoteCurrency: 'USD', aliases: ['netflix', '奈飞']),
  MarketOption(assetType: 'stock', name: 'Coinbase Global Inc.', symbol: 'COIN', displayCode: 'COIN', quoteCurrency: 'USD', aliases: ['coinbase']),
  MarketOption(assetType: 'stock', name: 'Nasdaq Inc.', symbol: 'NDAQ', displayCode: 'NDAQ', quoteCurrency: 'USD', aliases: ['nasdaq stock', '纳斯达克公司']),
  MarketOption(assetType: 'stock', name: 'Berkshire Hathaway Class B', symbol: 'BRK.B', displayCode: 'BRK.B', quoteCurrency: 'USD', aliases: ['berkshire', '巴菲特']),
  MarketOption(assetType: 'stock', name: 'JPMorgan Chase & Co.', symbol: 'JPM', displayCode: 'JPM', quoteCurrency: 'USD', aliases: ['jpmorgan', '摩根大通']),
  MarketOption(assetType: 'stock', name: 'Visa Inc.', symbol: 'V', displayCode: 'V', quoteCurrency: 'USD', aliases: ['visa']),
  MarketOption(assetType: 'stock', name: 'Walmart Inc.', symbol: 'WMT', displayCode: 'WMT', quoteCurrency: 'USD', aliases: ['walmart', '沃尔玛']),
  MarketOption(assetType: 'stock', name: 'Interactive Brokers Group Inc.', symbol: 'IBKR', displayCode: 'IBKR', quoteCurrency: 'USD', aliases: ['interactive brokers', '盈透证券', '盈透']),
  MarketOption(assetType: 'stock', name: 'SanDisk Corp.', symbol: 'SNDK', displayCode: 'SNDK', quoteCurrency: 'USD', aliases: ['sandisk', '闪迪']),
  MarketOption(assetType: 'stock', name: 'Micron Technology Inc.', symbol: 'MU', displayCode: 'MU', quoteCurrency: 'USD', aliases: ['micron', '美光']),
  MarketOption(assetType: 'stock', name: 'Western Digital Corp.', symbol: 'WDC', displayCode: 'WDC', quoteCurrency: 'USD', aliases: ['western digital', '西部数据']),
  MarketOption(assetType: 'stock', name: 'Advanced Micro Devices Inc.', symbol: 'AMD', displayCode: 'AMD', quoteCurrency: 'USD', aliases: ['amd', '超威']),
  MarketOption(assetType: 'stock', name: 'Palantir Technologies Inc.', symbol: 'PLTR', displayCode: 'PLTR', quoteCurrency: 'USD', aliases: ['palantir']),
  MarketOption(assetType: 'stock', name: 'Robinhood Markets Inc.', symbol: 'HOOD', displayCode: 'HOOD', quoteCurrency: 'USD', aliases: ['robinhood']),
  MarketOption(assetType: 'stock', name: 'PayPal Holdings Inc.', symbol: 'PYPL', displayCode: 'PYPL', quoteCurrency: 'USD', aliases: ['paypal']),
  MarketOption(assetType: 'stock', name: 'Block Inc.', symbol: 'SQ', displayCode: 'SQ', quoteCurrency: 'USD', aliases: ['block', 'square']),

  // ETFs
  MarketOption(assetType: 'etf', name: 'Invesco QQQ Trust', symbol: 'QQQ', displayCode: 'QQQ', quoteCurrency: 'USD', aliases: ['nasdaq 100', '纳指100', '纳斯达克100']),
  MarketOption(assetType: 'etf', name: 'Invesco NASDAQ 100 ETF', symbol: 'QQQM', displayCode: 'QQQM', quoteCurrency: 'USD', aliases: ['qqq mini', 'nasdaq 100']),
  MarketOption(assetType: 'etf', name: 'NEOS Nasdaq-100 High Income ETF', symbol: 'QQQI', displayCode: 'QQQI', quoteCurrency: 'USD', aliases: ['nasdaq income', '高股息纳指']),
  MarketOption(assetType: 'etf', name: 'SPDR S&P 500 ETF Trust', symbol: 'SPY', displayCode: 'SPY', quoteCurrency: 'USD', aliases: ['s&p 500', 'sp500', '标普500']),
  MarketOption(assetType: 'etf', name: 'SPDR Portfolio S&P 500 ETF', symbol: 'SPLG', displayCode: 'SPLG', quoteCurrency: 'USD', aliases: ['spdr portfolio sp500']),
  MarketOption(assetType: 'etf', name: 'SPDR Portfolio S&P 1500 Composite Stock Market ETF', symbol: 'SPTM', displayCode: 'SPTM', quoteCurrency: 'USD', aliases: ['spdr total market']),
  MarketOption(assetType: 'etf', name: 'SPDR Portfolio S&P 500 ETF', symbol: 'SPYM', displayCode: 'SPYM', quoteCurrency: 'USD', aliases: ['spym', 'spdr sp500']),
  MarketOption(assetType: 'etf', name: 'NEOS S&P 500 High Income ETF', symbol: 'SPYI', displayCode: 'SPYI', quoteCurrency: 'USD', aliases: ['s&p income', '标普收益']),
  MarketOption(assetType: 'etf', name: 'Vanguard S&P 500 ETF', symbol: 'VOO', displayCode: 'VOO', quoteCurrency: 'USD', aliases: ['vanguard sp500']),
  MarketOption(assetType: 'etf', name: 'iShares Core S&P 500 ETF', symbol: 'IVV', displayCode: 'IVV', quoteCurrency: 'USD', aliases: ['ishares sp500']),
  MarketOption(assetType: 'etf', name: 'Vanguard Total Stock Market ETF', symbol: 'VTI', displayCode: 'VTI', quoteCurrency: 'USD', aliases: ['total stock market']),
  MarketOption(assetType: 'etf', name: 'Vanguard Total International Stock ETF', symbol: 'VXUS', displayCode: 'VXUS', quoteCurrency: 'USD', aliases: ['international stock', '海外股票']),
  MarketOption(assetType: 'etf', name: 'Schwab U.S. Dividend Equity ETF', symbol: 'SCHD', displayCode: 'SCHD', quoteCurrency: 'USD', aliases: ['dividend', '股息']),
  MarketOption(assetType: 'etf', name: 'iShares 0-3 Month Treasury Bond ETF', symbol: 'SGOV', displayCode: 'SGOV', quoteCurrency: 'USD', aliases: ['treasury', '短债', '国债']),
  MarketOption(assetType: 'etf', name: 'iShares Russell 2000 ETF', symbol: 'IWM', displayCode: 'IWM', quoteCurrency: 'USD', aliases: ['russell 2000', '罗素2000']),
  MarketOption(assetType: 'etf', name: 'SPDR Gold Shares', symbol: 'GLD', displayCode: 'GLD', quoteCurrency: 'USD', aliases: ['gold etf', '黄金etf']),
  MarketOption(assetType: 'etf', name: 'iShares Silver Trust', symbol: 'SLV', displayCode: 'SLV', quoteCurrency: 'USD', aliases: ['silver etf', '白银etf']),
  MarketOption(assetType: 'etf', name: 'ARK Innovation ETF', symbol: 'ARKK', displayCode: 'ARKK', quoteCurrency: 'USD', aliases: ['ark innovation']),
];

List<MarketOption> marketSuggestionsFor(String assetType, String query, {int limit = 8}) {
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

List<MarketOption> mergeMarketSuggestions(List<MarketOption> local, List<MarketOption> remote, {int limit = 10}) {
  final map = <String, MarketOption>{};
  for (final item in [...local, ...remote]) {
    if (item.symbol.trim().isEmpty) continue;
    map.putIfAbsent(item.key, () => item);
  }
  return map.values.take(limit).toList();
}
