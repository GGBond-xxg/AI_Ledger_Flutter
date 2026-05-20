# Ledger / 记账

一个本地优先的个人资产记账 App，支持现金、股票、ETF、黄金白银、虚拟币、借款、应收款统计。

## 功能

- 本地保存资产数据
- 支持 API 聚合行情估值
- 支持 CNY / USD / HKD 等估值货币
- 支持密码锁、6 位 PIN、生物识别
- 支持中英文
- 支持深色 / 浅色 / 跟随系统
- 支持导出 JSON 备份
- 支持借款凭证图片

## 技术栈

- Flutter
- GetX
- Cloudflare Worker
- Twelve Data
- CoinGecko
- Frankfurter
- Gold API
- ChatGPT 辅助开发

## 隐私说明

所有资产、借款、API Token、密码锁配置默认只保存在本地设备，不上传服务器。

## License

MIT