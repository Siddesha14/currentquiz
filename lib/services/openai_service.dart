import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/quiz_model.dart';

class OpenAIService {
  static final String _apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1/models/gemini-2.0-flash:generateContent';

  Future<List<QuizQuestion>> generateQuiz(String topic, String newsContext) async {
    print('=== QUIZ GENERATION START ===');
    print('Topic: $topic');

    try {
      final promptText = 'You are a quiz generator for the category: $topic. Based on these news articles:\n\n' +
          newsContext +
          '\n\nGenerate EXACTLY 10 multiple-choice questions ONLY about $topic. Each question must have 4 options and exactly one correct answer. Return ONLY a valid JSON array in this format:\n' +
          '[{"question": "Question text?", "options": ["A", "B", "C", "D"], "correctAnswerIndex": 0, "explanation": "Why this is correct"}]\n\n' +
          'IMPORTANT: Generate questions ONLY about $topic. Ignore any articles not related to $topic.';

      print('Making API request...');
      final response = await http.post(
        Uri.parse(_baseUrl + '?key=' + _apiKey),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'contents': [{
            'parts': [{'text': promptText}]
          }],
          'generationConfig': {
            'temperature': 0.6,
            'maxOutputTokens': 2500,
          }
        }),
      );

      print('API Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final text = data['candidates'][0]['content']['parts'][0]['text'];

        print('Generated text received');

        String jsonText = text.trim();

        // Remove markdown code blocks
        if (jsonText.indexOf('json') > -1) {
          final startIdx = jsonText.indexOf('[');
          final endIdx = jsonText.lastIndexOf(']');
          if (startIdx > -1 && endIdx > startIdx) {
            jsonText = jsonText.substring(startIdx, endIdx + 1);
          }
        }

        // Extract JSON array
        if (jsonText.contains('[')) {
          int start = jsonText.indexOf('[');
          int end = jsonText.lastIndexOf(']');
          if (end > start) {
            jsonText = jsonText.substring(start, end + 1);
          }
        }

        print('Extracted JSON');

        final questionsJson = json.decode(jsonText) as List;
        final questions = questionsJson.map((q) => QuizQuestion.fromJson(q)).toList();

        print('SUCCESS: Generated ${questions.length} questions');
        return questions.take(10).toList();
      } else {
        print('ERROR: Status ${response.statusCode}');
        throw Exception('API Error ${response.statusCode}');
      }
    } catch (e) {
      print('EXCEPTION: $e');
      throw Exception('Error: $e');
    }
  }
}
