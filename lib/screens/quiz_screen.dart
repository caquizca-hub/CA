import 'package:flutter/material.dart';
import '../models/quiz_models.dart';
import 'result_screen.dart';

class QuizScreen extends StatefulWidget {
  final String title;
  final List<Question> questions;
  final Color color;

  const QuizScreen({
    super.key,
    required this.title,
    required this.questions,
    required this.color,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _currentQuestionIndex = 0;
  int _score = 0;
  int? _selectedOptionIndex;
  bool _isAnswered = false;
  final Map<int, int> _userAnswers = {};

  void _answerQuestion(int selectedIndex) {
    if (_isAnswered) return;

    setState(() {
      _selectedOptionIndex = selectedIndex;
      _isAnswered = true;
      _userAnswers[_currentQuestionIndex] = selectedIndex;
      if (selectedIndex ==
          widget.questions[_currentQuestionIndex].correctOptionIndex) {
        _score++;
      }
    });

    Future.delayed(const Duration(seconds: 1), () {
      if (_currentQuestionIndex < widget.questions.length - 1) {
        setState(() {
          _currentQuestionIndex++;
          _selectedOptionIndex = null;
          _isAnswered = false;
        });
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ResultScreen(
              score: _score,
              totalQuestions: widget.questions.length,
              subjectName: widget.title,
              questions: widget.questions,
              userAnswers: _userAnswers,
            ),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final question = widget.questions[_currentQuestionIndex];

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: widget.color,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress Section
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Question ${_currentQuestionIndex + 1}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: widget.color,
                        ),
                      ),
                      Text(
                        '${widget.questions.length}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value:
                          (_currentQuestionIndex + 1) / widget.questions.length,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(widget.color),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            ),

            // Question Section
            Expanded(
              child: Scrollbar(
                thumbVisibility: true,
                radius: const Radius.circular(8),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 10),
                      Text(
                        question.questionText,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          height: 1.5,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 30),
                      ...List.generate(question.options.length, (index) {
                        bool isSelected = _selectedOptionIndex == index;
                        bool isCorrect = index == question.correctOptionIndex;

                        Color borderColor = Colors.grey.shade300;
                        Color backgroundColor = Colors.white;
                        Color textColor = Colors.black87;
                        IconData? icon;

                        if (_isAnswered) {
                          if (isCorrect) {
                            borderColor = Colors.green;
                            backgroundColor = Colors.green.shade50;
                            textColor = Colors.green.shade900;
                            icon = Icons.check_circle;
                          } else if (isSelected) {
                            borderColor = Colors.red;
                            backgroundColor = Colors.red.shade50;
                            textColor = Colors.red.shade900;
                            icon = Icons.cancel;
                          }
                        } else if (isSelected) {
                          borderColor = widget.color;
                          backgroundColor = widget.color.withOpacity(0.05);
                        }

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: InkWell(
                            onTap: () => _answerQuestion(index),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: backgroundColor,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: borderColor,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      question.options[index],
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: textColor,
                                      ),
                                    ),
                                  ),
                                  if (icon != null) ...[
                                    const SizedBox(width: 12),
                                    Icon(icon, color: textColor),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
