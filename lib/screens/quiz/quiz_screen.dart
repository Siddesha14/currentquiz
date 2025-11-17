import 'package:flutter/material.dart';
import '../../services/news_api_service.dart';
import '../../services/openai_service.dart';
import '../../models/quiz_model.dart';
import 'result_screen.dart';

class QuizScreen extends StatefulWidget {
  final String topic;
  final List<QuizQuestion>? questions;

  const QuizScreen({
    super.key,
    required this.topic,
    this.questions,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final NewsApiService _newsService = NewsApiService();
  final OpenAIService _openAIService = OpenAIService();

  List<QuizQuestion> _questions = [];
  int _currentQuestionIndex = 0;
  int _score = 0;
  int? _selectedAnswerIndex;
  bool _isLoading = true;
  bool _hasAnswered = false;
  List<int> _userAnswers = [];

  @override
  void initState() {
    super.initState();
    if (widget.questions != null && widget.questions!.isNotEmpty) {
      setState(() {
        _questions = widget.questions!;
        _isLoading = false;
        _userAnswers = List.filled(widget.questions!.length, -1);
      });
      print('Using ${widget.questions!.length} pre-generated questions');
    } else {
      print('No pre-generated questions, generating now...');
      _generateQuiz();
    }
  }

  Future<void> _generateQuiz() async {
    try {
      final articles = await _newsService.searchNews(widget.topic);

      if (articles.isEmpty) {
        throw Exception('No news found for this topic');
      }

      final newsContext = articles
          .take(5)
          .map((article) => '${article.title}. ${article.description}')
          .join('\n\n');

      final questions = await _openAIService.generateQuiz(widget.topic, newsContext);

      setState(() {
        _questions = questions;
        _isLoading = false;
        _userAnswers = List.filled(questions.length, -1);
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating quiz: $e')),
        );
        Navigator.pop(context);
      }
    }
  }

  void _selectAnswer(int index) {
    if (_hasAnswered) return;

    setState(() {
      _selectedAnswerIndex = index;
      _hasAnswered = true;
      _userAnswers[_currentQuestionIndex] = index;

      if (index == _questions[_currentQuestionIndex].correctAnswerIndex) {
        _score += 10;
      }
    });
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _selectedAnswerIndex = null;
        _hasAnswered = false;
      });
    } else {
      _finishQuiz();
    }
  }

  void _finishQuiz() {
    final result = QuizResult(
      score: _score,
      totalQuestions: _questions.length,
      correctAnswers: _score ~/ 10,
      topic: widget.topic,
      completedAt: DateTime.now(),
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ResultScreen(result: result),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('${widget.topic} Quiz')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Generating quiz questions...'),
              SizedBox(height: 8),
              Text(
                'This may take a moment',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text('${widget.topic} Quiz')),
        body: const Center(child: Text('No questions available')),
      );
    }

    final question = _questions[_currentQuestionIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.topic} Quiz'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Score: $_score',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: (_currentQuestionIndex + 1) / _questions.length,
            minHeight: 8,
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Question ${_currentQuestionIndex + 1} of ${_questions.length}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        question.question,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ...List.generate(question.options.length, (index) {
                    return _buildOptionButton(index, question);
                  }),
                  if (_hasAnswered) ...[
                    const SizedBox(height: 24),
                    Card(
                      color: _selectedAnswerIndex == question.correctAnswerIndex
                          ? Colors.green[50]
                          : Colors.red[50],
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _selectedAnswerIndex == question.correctAnswerIndex
                                      ? Icons.check_circle
                                      : Icons.cancel,
                                  color: _selectedAnswerIndex == question.correctAnswerIndex
                                      ? Colors.green
                                      : Colors.red,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _selectedAnswerIndex == question.correctAnswerIndex
                                      ? 'Correct!'
                                      : 'Incorrect',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: _selectedAnswerIndex == question.correctAnswerIndex
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              question.explanation,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (_hasAnswered)
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _nextQuestion,
                  child: Text(
                    _currentQuestionIndex < _questions.length - 1
                        ? 'Next Question'
                        : 'Finish Quiz',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOptionButton(int index, QuizQuestion question) {
    final isSelected = _selectedAnswerIndex == index;
    final isCorrect = index == question.correctAnswerIndex;

    Color? backgroundColor;
    Color? borderColor;

    if (_hasAnswered) {
      if (isCorrect) {
        backgroundColor = Colors.green[100];
        borderColor = Colors.green;
      } else if (isSelected && !isCorrect) {
        backgroundColor = Colors.red[100];
        borderColor = Colors.red;
      }
    } else if (isSelected) {
      backgroundColor = Theme.of(context).colorScheme.primary.withOpacity(0.1);
      borderColor = Theme.of(context).colorScheme.primary;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(12),
        elevation: isSelected ? 4 : 1,
        child: InkWell(
          onTap: () => _selectAnswer(index),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: borderColor ?? Colors.grey[300]!,
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: borderColor ?? Colors.grey[300],
                  ),
                  child: Center(
                    child: Text(
                      String.fromCharCode(65 + index),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    question.options[index],
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                if (_hasAnswered && isCorrect)
                  const Icon(Icons.check_circle, color: Colors.green),
                if (_hasAnswered && isSelected && !isCorrect)
                  const Icon(Icons.cancel, color: Colors.red),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
