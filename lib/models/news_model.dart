class NewsArticle {
  final String title;
  final String description;
  final String url;
  final String? urlToImage;
  final String publishedAt;
  final String source;

  NewsArticle({
    required this.title,
    required this.description,
    required this.url,
    this.urlToImage,
    required this.publishedAt,
    required this.source,
  });

  factory NewsArticle.fromJson(Map<String, dynamic> json) {
    return NewsArticle(
      title: json['title']?.toString() ?? 'No Title',
      description: json['description']?.toString() ?? 'No description available',
      url: json['url']?.toString() ?? '',
      urlToImage: json['urlToImage']?.toString(),
      publishedAt: json['publishedAt']?.toString() ?? DateTime.now().toIso8601String(),
      source: json['source']?['name']?.toString() ?? 'Unknown Source',
    );
  }
}
