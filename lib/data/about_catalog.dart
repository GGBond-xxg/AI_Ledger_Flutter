class AboutLinkItem {
  const AboutLinkItem({
    required this.title,
    required this.url,
    this.descriptionKey,
  });

  final String title;
  final String url;
  final String? descriptionKey;
}

class DonationAddress {
  const DonationAddress({
    required this.chain,
    required this.address,
    this.description,
  });

  final String chain;
  final String address;
  final String? description;
}

const List<AboutLinkItem> kAboutLinks = [
  AboutLinkItem(
    title: 'ChatGPT',
    url: 'https://chatgpt.com',
    descriptionKey: 'aboutChatGptDesc',
  ),
  AboutLinkItem(
    title: 'Flutter',
    url: 'https://flutter.dev',
    descriptionKey: 'aboutFlutterDesc',
  ),
  AboutLinkItem(
    title: 'GetX',
    url: 'https://pub.dev/packages/get',
    descriptionKey: 'aboutGetXDesc',
  ),
  AboutLinkItem(
    title: 'http',
    url: 'https://pub.dev/packages/http',
    descriptionKey: 'aboutHttpDesc',
  ),
  AboutLinkItem(
    title: 'shared_preferences',
    url: 'https://pub.dev/packages/shared_preferences',
    descriptionKey: 'aboutSharedPrefsDesc',
  ),
  AboutLinkItem(
    title: 'image_picker',
    url: 'https://pub.dev/packages/image_picker',
    descriptionKey: 'aboutImagePickerDesc',
  ),
  AboutLinkItem(
    title: 'image',
    url: 'https://pub.dev/packages/image',
    descriptionKey: 'aboutImageDesc',
  ),
  AboutLinkItem(
    title: 'flutter_launcher_icons',
    url: 'https://pub.dev/packages/flutter_launcher_icons',
    descriptionKey: 'aboutLauncherIconsDesc',
  ),
  AboutLinkItem(
    title: 'Cloudflare Workers',
    url: 'https://workers.cloudflare.com',
    descriptionKey: 'aboutCloudflareDesc',
  ),
];

// 开源前建议把下面的地址改成你自己的赞助地址。
// 如果 address 为空，App 会显示“未配置”，复制按钮会禁用。
const List<DonationAddress> kDonationAddresses = [
  DonationAddress(
      chain: 'BTC', address: 'bc1q3v73dxmd805t0x4nkr4mswhvrk4ragt7e0f5g5'),
  DonationAddress(
      chain: 'ETH/EVM', address: '0x3732e8155cEd9Bd9C89a5bb8b197DC063570952B'),
  DonationAddress(
      chain: 'TRC20', address: 'TXnGST3Qa1qGeFGcEivbdwtUBrWgNKeHdz'),
  DonationAddress(
      chain: 'SOL', address: '4YB3SxN4j7ADm6ZxdCXbrsQq5HJbCewwBTYXN2rEXGYp'),
];
