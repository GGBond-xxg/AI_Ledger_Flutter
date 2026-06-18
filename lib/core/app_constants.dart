const List<String> kCurrencies = [
  'CNY',
  'USD',
  'HKD',
  'SGD',
  'EUR',
  'JPY',
  'USDT',
];

const List<String> kMetalUnits = [
  'gram',
  'troy_ounce',
];

const String kDefaultApiBaseUrl = String.fromEnvironment('LEDGER_API_BASE_URL', defaultValue: '');
const String kDefaultApiToken = String.fromEnvironment('LEDGER_API_TOKEN', defaultValue: '');
const String kApiBaseUrlHint = '请填写你的行情 API 地址';
