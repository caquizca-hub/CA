import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../models/quiz_models.dart';

class ResultScreen extends StatefulWidget {
  final int score;
  final int totalQuestions;
  final String subjectName;
  final List<Question> questions;
  final Map<int, int> userAnswers;

  const ResultScreen({
    super.key,
    required this.score,
    required this.totalQuestions,
    required this.subjectName,
    required this.questions,
    required this.userAnswers,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authService = Provider.of<AuthService>(context, listen: false);
      authService.updateUserScore(widget.score);
      authService.saveQuizResult(
        score: widget.score,
        totalQuestions: widget.totalQuestions,
        subjectName: widget.subjectName,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final percentage = (widget.score / widget.totalQuestions) * 100;
    Color resultColor;
    String message;
    IconData icon;

    if (percentage >= 80) {
      resultColor = Colors.green;
      message = 'Excellent!';
      icon = Icons.emoji_events;
    } else if (percentage >= 50) {
      resultColor = Colors.orange;
      message = 'Good Job!';
      icon = Icons.thumb_up;
    } else {
      resultColor = Colors.red;
      message = 'Keep Practicing!';
      icon = Icons.refresh;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz Analysis'),
        centerTitle: true,
        backgroundColor: resultColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Summary Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Icon(icon, size: 80, color: resultColor),
                    const SizedBox(height: 16),
                    Text(
                      message,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: resultColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'You scored ${widget.score} / ${widget.totalQuestions}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${percentage.toStringAsFixed(1)}%',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Detailed Analysis',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // Questions List
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.questions.length,
              itemBuilder: (context, index) {
                final question = widget.questions[index];
                final userAnswerIndex = widget.userAnswers[index];
                final isCorrect =
                    userAnswerIndex == question.correctOptionIndex;
                final isSkipped = userAnswerIndex == null;

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isCorrect
                          ? Colors.green.withOpacity(0.5)
                          : Colors.red.withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isCorrect
                                    ? Colors.green.withOpacity(0.1)
                                    : Colors.red.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isCorrect
                                    ? Icons.check
                                    : (isSkipped ? Icons.remove : Icons.close),
                                color: isCorrect ? Colors.green : Colors.red,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Question ${index + 1}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          question.questionText,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        // Options
                        ...List.generate(question.options.length, (optIndex) {
                          final isSelected = userAnswerIndex == optIndex;
                          final isCorrectOption =
                              question.correctOptionIndex == optIndex;

                          Color? backgroundColor;
                          Color textColor = Colors.black87;
                          FontWeight fontWeight = FontWeight.normal;

                          if (isCorrectOption) {
                            backgroundColor = Colors.green.withOpacity(0.1);
                            textColor = Colors.green.shade900;
                            fontWeight = FontWeight.bold;
                          } else if (isSelected && !isCorrectOption) {
                            backgroundColor = Colors.red.withOpacity(0.1);
                            textColor = Colors.red.shade900;
                          }

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: backgroundColor,
                              borderRadius: BorderRadius.circular(8),
                              border: isSelected || isCorrectOption
                                  ? Border.all(
                                      color: isCorrectOption
                                          ? Colors.green
                                          : Colors.red,
                                    )
                                  : Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    question.options[optIndex],
                                    style: TextStyle(
                                      color: textColor,
                                      fontWeight: fontWeight,
                                    ),
                                  ),
                                ),
                                if (isCorrectOption)
                                  const Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                    size: 18,
                                  ),
                                if (isSelected && !isCorrectOption)
                                  const Icon(
                                    Icons.cancel,
                                    color: Colors.red,
                                    size: 18,
                                  ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Theme.of(context).primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Back to Home',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
