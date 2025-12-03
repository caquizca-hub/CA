import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/quiz_data.dart';
import '../models/quiz_models.dart';
import '../services/ai_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';
import 'manage_questions_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  CourseLevel? _selectedCourse;
  CourseGroup? _selectedGroup;
  Subject? _selectedSubject;
  Chapter? _selectedChapter;

  final _questionController = TextEditingController();
  final _option1Controller = TextEditingController();
  final _option2Controller = TextEditingController();
  final _option3Controller = TextEditingController();
  final _option4Controller = TextEditingController();
  final _chapterNameController = TextEditingController();
  int _correctOptionIndex = 0;

  final AIService _aiService = AIService();
  bool _isLoading = false;

  @override
  void dispose() {
    _questionController.dispose();
    _option1Controller.dispose();
    _option2Controller.dispose();
    _option3Controller.dispose();
    _option4Controller.dispose();
    _chapterNameController.dispose();
    super.dispose();
  }

  Future<void> _addChapter() async {
    if (_selectedSubject == null || _chapterNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a subject and enter chapter name'),
        ),
      );
      return;
    }

    try {
      await Provider.of<QuizService>(context, listen: false).addChapter(
        _selectedCourse!.id,
        _selectedGroup!.name,
        _selectedSubject!.id,
        _chapterNameController.text,
      );
      _chapterNameController.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chapter Added Successfully!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error adding chapter: $e')));
    }
  }

  Future<void> _addQuestion() async {
    if (_selectedSubject == null ||
        _questionController.text.isEmpty ||
        _option1Controller.text.isEmpty ||
        _option2Controller.text.isEmpty ||
        _option3Controller.text.isEmpty ||
        _option4Controller.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    final newQuestion = Question(
      questionText: _questionController.text,
      options: [
        _option1Controller.text,
        _option2Controller.text,
        _option3Controller.text,
        _option4Controller.text,
      ],
      correctOptionIndex: _correctOptionIndex,
      chapterId: _selectedChapter?.id,
    );

    await _saveQuestion(newQuestion);

    // Clear fields
    _questionController.clear();
    _option1Controller.clear();
    _option2Controller.clear();
    _option3Controller.clear();
    _option4Controller.clear();
    setState(() {
      _correctOptionIndex = 0;
    });
  }

  Future<void> _saveQuestion(Question question) async {
    try {
      await Provider.of<QuizService>(context, listen: false).addQuestion(
        _selectedCourse!.id,
        _selectedGroup!.name,
        _selectedSubject!.id,
        question,
        chapterId: _selectedChapter?.id,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Question Added Successfully!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error adding question: $e')));
    }
  }

  Future<void> _generateFromImage() async {
    if (_selectedSubject == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a subject first')),
      );
      return;
    }

    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;

    setState(() => _isLoading = true);

    try {
      final bytes = await File(image.path).readAsBytes();
      final base64Image = base64Encode(bytes);

      final question = await _aiService.generateQuestionFromImage(base64Image);

      if (!mounted) return;
      await _showReviewDialog([question]);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating from image: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showReviewDialog(List<Question> questions) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _ReviewDialog(
        questions: questions,
        onSave: (question) => _saveQuestion(question),
      ),
    );
  }

  Future<void> _showAIGenerationDialog({required bool isFromText}) async {
    if (_selectedSubject == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a subject first')),
      );
      return;
    }

    final textController = TextEditingController();
    final countController = TextEditingController(text: '5');

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isFromText ? 'Generate from Text' : 'Generate from Topic'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: textController,
              decoration: InputDecoration(
                labelText: isFromText ? 'Paste Text Here' : 'Enter Topic',
                hintText: isFromText
                    ? 'Paste a paragraph from your study material...'
                    : 'e.g., Accounting Standards, GST Basics...',
              ),
              maxLines: isFromText ? 5 : 1,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: countController,
              decoration: const InputDecoration(
                labelText: 'Number of Questions',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _handleAIGeneration(
              countController,
              textController,
              isFromText,
            ),
            child: const Text('Generate'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleAIGeneration(
    TextEditingController countController,
    TextEditingController textController,
    bool isFromText,
  ) async {
    Navigator.pop(context);
    setState(() => _isLoading = true);
    try {
      final count = int.tryParse(countController.text) ?? 5;
      final text = textController.text;

      List<Question> questions;
      if (isFromText) {
        questions = await _aiService.generateQuestionsFromText(
          text,
          count: count,
        );
      } else {
        questions = await _aiService.generateQuestionsFromTopic(
          text,
          count: count,
        );
      }

      if (!mounted) return;
      await _showReviewDialog(questions);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('AI Generation Failed: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildSelectionCard(List<CourseLevel> courses) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '1. Select Context',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<CourseLevel>(
              decoration: const InputDecoration(
                labelText: 'Select Course Level',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.school),
              ),
              value: _selectedCourse,
              items: courses.map((course) {
                return DropdownMenuItem(
                  value: course,
                  child: Text(course.name),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCourse = value;
                  _selectedGroup = null;
                  _selectedSubject = null;
                  _selectedChapter = null;
                });
              },
            ),
            const SizedBox(height: 16),
            if (_selectedCourse != null)
              DropdownButtonFormField<CourseGroup>(
                decoration: const InputDecoration(
                  labelText: 'Select Group',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.group_work),
                ),
                value: _selectedGroup,
                items: _selectedCourse!.groups.map((group) {
                  return DropdownMenuItem(
                    value: group,
                    child: Text(group.name),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedGroup = value;
                    _selectedSubject = null;
                    _selectedChapter = null;
                  });
                },
              ),
            if (_selectedCourse != null) const SizedBox(height: 16),
            if (_selectedGroup != null)
              DropdownButtonFormField<Subject>(
                decoration: const InputDecoration(
                  labelText: 'Select Subject',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.subject),
                ),
                value: _selectedSubject,
                items: _selectedGroup!.subjects.map((subject) {
                  return DropdownMenuItem(
                    value: subject,
                    child: Text(subject.name),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedSubject = value;
                    _selectedChapter = null;
                  });
                },
              ),
            if (_selectedGroup != null) const SizedBox(height: 16),
            if (_selectedSubject != null)
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<Chapter>(
                      decoration: const InputDecoration(
                        labelText: 'Select Chapter (Optional)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.bookmark),
                      ),
                      value: _selectedChapter,
                      items: [
                        const DropdownMenuItem<Chapter>(
                          value: null,
                          child: Text('None (Subject Level)'),
                        ),
                        ..._selectedSubject!.chapters.map((chapter) {
                          return DropdownMenuItem(
                            value: chapter,
                            child: Text(chapter.name),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedChapter = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(
                      Icons.add_circle,
                      size: 32,
                      color: Colors.blue,
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Add New Chapter'),
                          content: TextField(
                            controller: _chapterNameController,
                            decoration: const InputDecoration(
                              labelText: 'Chapter Name',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                _addChapter();
                              },
                              child: const Text('Add'),
                            ),
                          ],
                        ),
                      );
                    },
                    tooltip: 'Add New Chapter',
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAIActionCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '2. AI Generation',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showAIGenerationDialog(isFromText: false),
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('From Topic'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: Colors.purple.shade50,
                      foregroundColor: Colors.purple.shade900,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showAIGenerationDialog(isFromText: true),
                    icon: const Icon(Icons.description),
                    label: const Text('From Text'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: Colors.blue.shade50,
                      foregroundColor: Colors.blue.shade900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _generateFromImage,
                icon: const Icon(Icons.image),
                label: const Text('Generate from Image'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: Colors.orange.shade50,
                  foregroundColor: Colors.orange.shade900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManualEntryCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '3. Manual Entry',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _questionController,
              decoration: const InputDecoration(
                labelText: 'Question Text',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.help_outline),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            ...List.generate(4, (index) {
              TextEditingController controller;
              switch (index) {
                case 0:
                  controller = _option1Controller;
                  break;
                case 1:
                  controller = _option2Controller;
                  break;
                case 2:
                  controller = _option3Controller;
                  break;
                case 3:
                  controller = _option4Controller;
                  break;
                default:
                  controller = _option1Controller;
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    labelText: 'Option ${index + 1}',
                    border: const OutlineInputBorder(),
                    prefixIcon: Icon(Icons.list),
                  ),
                ),
              );
            }),
            const SizedBox(height: 4),
            DropdownButtonFormField<int>(
              decoration: const InputDecoration(
                labelText: 'Correct Option',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.check_circle),
              ),
              value: _correctOptionIndex,
              items: const [
                DropdownMenuItem(value: 0, child: Text('Option 1')),
                DropdownMenuItem(value: 1, child: Text('Option 2')),
                DropdownMenuItem(value: 2, child: Text('Option 3')),
                DropdownMenuItem(value: 3, child: Text('Option 4')),
              ],
              onChanged: (value) {
                setState(() {
                  _correctOptionIndex = value!;
                });
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _addQuestion,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Add Question',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final quizService = Provider.of<QuizService>(context);
    final courses = quizService.caCourses;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ManageQuestionsScreen(),
                ),
              );
            },
            tooltip: 'Manage Questions',
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSelectionCard(courses),
                if (_selectedSubject != null) ...[
                  const SizedBox(height: 24),
                  _buildAIActionCard(),
                  const SizedBox(height: 24),
                  _buildManualEntryCard(),
                ],
                const SizedBox(height: 32),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}

class _ReviewDialog extends StatefulWidget {
  final List<Question> questions;
  final Function(Question) onSave;

  const _ReviewDialog({required this.questions, required this.onSave});

  @override
  State<_ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<_ReviewDialog> {
  late List<Question> _questions;
  int _currentIndex = 0;
  late TextEditingController _questionController;
  late List<TextEditingController> _optionControllers;
  late int _correctOptionIndex;

  @override
  void initState() {
    super.initState();
    _questions = List.from(widget.questions);
    _initializeControllers();
  }

  void _initializeControllers() {
    final q = _questions[_currentIndex];
    _questionController = TextEditingController(text: q.questionText);
    _optionControllers = List.generate(
      4,
      (i) => TextEditingController(text: q.options[i]),
    );
    _correctOptionIndex = q.correctOptionIndex;
  }

  @override
  void dispose() {
    _questionController.dispose();
    for (var c in _optionControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _saveCurrent() {
    final updatedQuestion = Question(
      questionText: _questionController.text,
      options: _optionControllers.map((c) => c.text).toList(),
      correctOptionIndex: _correctOptionIndex,
      chapterId: _questions[_currentIndex].chapterId,
    );

    widget.onSave(updatedQuestion);
    _removeCurrent();
  }

  void _removeCurrent() {
    setState(() {
      _questions.removeAt(_currentIndex);
      if (_questions.isEmpty) {
        Navigator.pop(context);
      } else {
        if (_currentIndex >= _questions.length) {
          _currentIndex = _questions.length - 1;
        }
        _initializeControllers();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_questions.isEmpty) return const SizedBox.shrink();

    return AlertDialog(
      title: Text(
        'Review Question (${_currentIndex + 1}/${_questions.length})',
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _questionController,
              decoration: const InputDecoration(labelText: 'Question'),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            ...List.generate(4, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    Radio<int>(
                      value: index,
                      groupValue: _correctOptionIndex,
                      onChanged: (val) {
                        setState(() => _correctOptionIndex = val!);
                      },
                    ),
                    Expanded(
                      child: TextField(
                        controller: _optionControllers[index],
                        decoration: InputDecoration(
                          labelText: 'Option ${index + 1}',
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _removeCurrent,
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: const Text('Discard'),
        ),
        ElevatedButton(
          onPressed: _saveCurrent,
          child: const Text('Save & Next'),
        ),
      ],
    );
  }
}
