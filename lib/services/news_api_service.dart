import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/news_model.dart';

class NewsApiService {
  // Get your FREE API key from: https://newsdata.io/
  // Free tier: 200 requests/day, no removed articles
  static const String _apiKey = 'pub_b192b7a1416b45578cc889f7bae3d7fa'; // YOUR KEY
  static const String _baseUrl = 'https://newsdata.io/api/1/news';

  Future<List<NewsArticle>> getTopHeadlines({String category = 'general'}) async {
    print('=== NEWS DATA API REQUEST ===');
    print('Category: $category');

    try {
      // NewsData.io uses 'top' for general news categories
      final categoryMap = {
        'general': 'top',
        'business': 'business',
        'technology': 'technology',
        'sports': 'sports',
        'entertainment': 'entertainment',
        'health': 'health',
        'science': 'science',
      };

      final mappedCategory = categoryMap[category] ?? 'top';
      final url = '$_baseUrl?apikey=$_apiKey&country=in&category=$mappedCategory&language=en';

      print('Request URL: $url');

      final response = await http.get(Uri.parse(url));

      print('API Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        print('API Response status: ${data['status']}');

        if (data['status'] == 'success' && data['results'] != null) {
          final articles = (data['results'] as List)
              .where((article) =>
          article != null &&
              article['title'] != null &&
              article['description'] != null &&
              article['link'] != null
          )
              .map((article) {
            try {
              return NewsArticle(
                title: article['title'] ?? 'No Title',
                description: article['description'] ?? article['content'] ?? 'No description',
                url: article['link'] ?? '',
                urlToImage: article['image_url'],
                publishedAt: article['pubDate'] ?? DateTime.now().toIso8601String(),
                source: article['source_id'] ?? 'Unknown',
              );
            } catch (e) {
              print('Error parsing article: $e');
              return null;
            }
          })
              .where((article) => article != null)
              .cast<NewsArticle>()
              .toList();

          print('SUCCESS: Got ${articles.length} real articles');
          return articles;
        } else {
          print('API error: ${data['message'] ?? 'Unknown error'}');
        }
      } else {
        print('HTTP ERROR: ${response.statusCode}');
        print('Response: ${response.body}');
      }
    } catch (e) {
      print('EXCEPTION: $e');
    }

    return [];
  }

  Future<List<NewsArticle>> searchNews(String query) async {
    try {
      final url = '$_baseUrl?apikey=$_apiKey&q=$query&language=en';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'success' && data['results'] != null) {
          final articles = (data['results'] as List)
              .map((article) => NewsArticle(
            title: article['title'] ?? 'No Title',
            description: article['description'] ?? article['content'] ?? 'No description',
            url: article['link'] ?? '',
            urlToImage: article['image_url'],
            publishedAt: article['pubDate'] ?? DateTime.now().toIso8601String(),
            source: article['source_id'] ?? 'Unknown',
          ))
              .take(5)
              .toList();

          return articles;
        }
      }
    } catch (e) {
      print('Search error: $e');
    }

    return [];
  }
}
