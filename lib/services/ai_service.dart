import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/quiz_models.dart';

class AIService {
  static const String _textApiKey =
      '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';
  static const String _imageApiKey =
      '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';
  static const String _baseUrl =
      'https://openrouter.ai/api/v1/chat/completions';
  static const String _textModel = 'x-ai/grok-4.1-fast:free';
  static const String _imageModel = 'amazon/nova-2-lite-v1:free';

  Future<List<Question>> generateQuestionsFromText(
    String text, {
    int count = 5,
  }) async {
    final prompt =
        '''
    Generate $count multiple-choice questions based on the following text:
    "$text"

    Return the response ONLY as a raw JSON array. Do not include markdown formatting like ```json ... ```.
    Each object in the array should have:
    - "questionText": String
    - "options": List<String> (exactly 4 options)
    - "correctOptionIndex": int (0-3)
    ''';

    return _fetchQuestions(prompt, model: _textModel);
  }

  Future<List<Question>> generateQuestionsFromTopic(
    String topic, {
    int count = 5,
  }) async {
    final prompt =
        '''
    Generate $count multiple-choice questions for the CA (Chartered Accountant) exam subject topic: "$topic".

    Return the response ONLY as a raw JSON array. Do not include markdown formatting like ```json ... ```.
    Each object in the array should have:
    - "questionText": String
    - "options": List<String> (exactly 4 options)
    - "correctOptionIndex": int (0-3)
    ''';

    return _fetchQuestions(prompt, model: _textModel);
  }

  Future<Question> generateQuestionFromImage(String base64Image) async {
    final prompt = '''
    Analyze the image and extract the multiple-choice question from it.
    If the image contains a question, extract it. If it contains text/topic, generate a question based on it.
    
    Return the response ONLY as a raw JSON object. Do not include markdown formatting like ```json ... ```.
    The object should have:
    - "questionText": String
    - "options": List<String> (exactly 4 options)
    - "correctOptionIndex": int (0-3)
    ''';

    final messages = [
      {
        'role': 'user',
        'content': [
          {'type': 'text', 'text': prompt},
          {
            'type': 'image_url',
            'image_url': {'url': 'data:image/jpeg;base64,$base64Image'},
          },
        ],
      },
    ];

    final response = await _sendRequest(
      messages,
      model: _imageModel,
      apiKey: _imageApiKey,
    );
    final json = jsonDecode(response);
    return Question(
      questionText: json['questionText'],
      options: List<String>.from(json['options']),
      correctOptionIndex: json['correctOptionIndex'],
    );
  }

  Future<List<Question>> _fetchQuestions(
    String prompt, {
    required String model,
  }) async {
    final messages = [
      {'role': 'user', 'content': prompt},
    ];
    final content = await _sendRequest(
      messages,
      model: model,
      apiKey: _textApiKey,
    );
    final List<dynamic> jsonList = jsonDecode(content);

    return jsonList
        .map(
          (json) => Question(
            questionText: json['questionText'],
            options: List<String>.from(json['options']),
            correctOptionIndex: json['correctOptionIndex'],
          ),
        )
        .toList();
  }

  Future<String> _sendRequest(
    List<Map<String, dynamic>> messages, {
    required String model,
    required String apiKey,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
          'HTTP-Referer': 'https://ca-quiz-app.com',
          'X-Title': 'CA Quiz App',
        },
        body: jsonEncode({'model': model, 'messages': messages}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];

        // Clean up content if it contains markdown code blocks
        String jsonString = content;
        if (content.contains('```json')) {
          jsonString = content.replaceAll('```json', '').replaceAll('```', '');
        } else if (content.contains('```')) {
          jsonString = content.replaceAll('```', '');
        }

        return jsonString;
      } else {
        throw Exception(
          'Failed to generate questions: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e) {
      print('Error generating questions: $e');
      throw Exception('Error generating questions: $e');
    }
  }
}
