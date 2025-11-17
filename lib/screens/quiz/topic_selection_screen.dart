import 'package:flutter/material.dart';
import '../quiz/quiz_screen.dart';
import '../../services/news_api_service.dart';
import '../../services/openai_service.dart';

class TopicSelectionScreen extends StatelessWidget {
  const TopicSelectionScreen({super.key});

  final List<Map<String, dynamic>> topics = const [
    {'name': 'Politics', 'icon': Icons.account_balance, 'color': Colors.blue, 'category': 'general'},
    {'name': 'Technology', 'icon': Icons.computer, 'color': Colors.purple, 'category': 'technology'},
    {'name': 'Sports', 'icon': Icons.sports_soccer, 'color': Colors.green, 'category': 'sports'},
    {'name': 'Business', 'icon': Icons.business, 'color': Colors.orange, 'category': 'business'},
    {'name': 'Entertainment', 'icon': Icons.movie, 'color': Colors.red, 'category': 'entertainment'},
    {'name': 'Science', 'icon': Icons.science, 'color': Colors.teal, 'category': 'science'},
    {'name': 'Health', 'icon': Icons.health_and_safety, 'color': Colors.pink, 'category': 'health'},
    {'name': 'World News', 'icon': Icons.public, 'color': Colors.indigo, 'category': 'general'},
  ];

  Future<void> _startQuiz(BuildContext context, Map<String, dynamic> topic) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      print('=== STARTING QUIZ GENERATION ===');
      print('Topic: ${topic['name']}');

      final newsService = NewsApiService();
      final category = topic['category'] ?? 'general';

      print('Fetching news articles for category: $category');
      final newsArticles = await newsService.getTopHeadlines(category: category);

      String newsContext = '';
      if (newsArticles.isNotEmpty) {
        print('Found ${newsArticles.length} news articles');

        final relevantArticles = newsArticles.take(8).map((article) {
          return '''
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
HEADLINE: ${article.title}
CATEGORY: ${topic['name']}
CONTENT: ${article.description}
SOURCE: ${article.source}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━''';
        }).join('\n\n');

        newsContext = '''
TOPIC FOCUS: ${topic['name']}
INSTRUCTIONS: Generate questions ONLY about ${topic['name']}. Ignore any articles not related to ${topic['name']}.

RELEVANT NEWS ARTICLES:
$relevantArticles
''';

        print('Created focused news context for ${topic['name']}');
      } else {
        print('WARNING: No news articles found, using generic context');
        newsContext = 'Generate general knowledge questions ONLY about ${topic['name']} current affairs.';
      }

      print('Generating quiz with Gemini AI...');
      final openAIService = OpenAIService();
      final questions = await openAIService.generateQuiz(topic['name'], newsContext);

      print('Successfully generated ${questions.length} questions');

      if (context.mounted) {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => QuizScreen(
              topic: topic['name'],
              questions: questions,
            ),
          ),
        );
      }
    } catch (e) {
      print('ERROR generating quiz: $e');

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating quiz: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Quiz Topic'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choose a topic',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Test your knowledge on current affairs',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.2,
                ),
                itemCount: topics.length,
                itemBuilder: (context, index) {
                  final topic = topics[index];
                  return _buildTopicCard(context, topic);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopicCard(BuildContext context, Map<String, dynamic> topic) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _startQuiz(context, topic),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                topic['color'].withOpacity(0.7),
                topic['color'],
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(topic['icon'], size: 48, color: Colors.white),
              const SizedBox(height: 12),
              Text(
                topic['name'],
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
