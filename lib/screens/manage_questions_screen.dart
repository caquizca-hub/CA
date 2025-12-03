import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/quiz_data.dart';
import '../models/quiz_models.dart';

class ManageQuestionsScreen extends StatefulWidget {
  const ManageQuestionsScreen({super.key});

  @override
  State<ManageQuestionsScreen> createState() => _ManageQuestionsScreenState();
}

class _ManageQuestionsScreenState extends State<ManageQuestionsScreen> {
  CourseLevel? _selectedCourse;
  CourseGroup? _selectedGroup;
  Subject? _selectedSubject;
  Chapter? _selectedChapter;

  @override
  Widget build(BuildContext context) {
    final quizService = Provider.of<QuizService>(context);
    final courses = quizService.caCourses;

    List<Question> questionsToShow = [];
    if (_selectedSubject != null) {
      if (_selectedChapter != null) {
        questionsToShow = _selectedChapter!.questions;
      } else {
        questionsToShow = _selectedSubject!.questions;
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Questions')),
      body: Column(
        children: [
          // Filters Card
          Card(
            margin: const EdgeInsets.all(16.0),
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Filter Questions',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<CourseLevel>(
                    decoration: const InputDecoration(
                      labelText: 'Select Course',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.school),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    value: _selectedCourse,
                    items: courses
                        .map(
                          (c) =>
                              DropdownMenuItem(value: c, child: Text(c.name)),
                        )
                        .toList(),
                    onChanged: (val) => setState(() {
                      _selectedCourse = val;
                      _selectedGroup = null;
                      _selectedSubject = null;
                      _selectedChapter = null;
                    }),
                  ),
                  if (_selectedCourse != null) ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<CourseGroup>(
                      decoration: const InputDecoration(
                        labelText: 'Select Group',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.group_work),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      value: _selectedGroup,
                      items: _selectedCourse!.groups
                          .map(
                            (g) =>
                                DropdownMenuItem(value: g, child: Text(g.name)),
                          )
                          .toList(),
                      onChanged: (val) => setState(() {
                        _selectedGroup = val;
                        _selectedSubject = null;
                        _selectedChapter = null;
                      }),
                    ),
                  ],
                  if (_selectedGroup != null) ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<Subject>(
                      decoration: const InputDecoration(
                        labelText: 'Select Subject',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.subject),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      value: _selectedSubject,
                      items: _selectedGroup!.subjects
                          .map(
                            (s) =>
                                DropdownMenuItem(value: s, child: Text(s.name)),
                          )
                          .toList(),
                      onChanged: (val) => setState(() {
                        _selectedSubject = val;
                        _selectedChapter = null;
                      }),
                    ),
                  ],
                  if (_selectedSubject != null) ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<Chapter>(
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Select Chapter (Optional)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.bookmark),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      value: _selectedChapter,
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('All Subject Questions'),
                        ),
                        ..._selectedSubject!.chapters.map(
                          (c) =>
                              DropdownMenuItem(value: c, child: Text(c.name)),
                        ),
                      ],
                      onChanged: (val) =>
                          setState(() => _selectedChapter = val),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Question List
          Expanded(
            child: questionsToShow.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _selectedSubject == null
                              ? 'Please select a subject to view questions.'
                              : 'No questions found for this selection.',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8.0,
                        ),
                        child: Row(
                          children: [
                            Text(
                              'Found ${questionsToShow.length} Questions',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          itemCount: questionsToShow.length,
                          itemBuilder: (context, index) {
                            final question = questionsToShow[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                title: Text(
                                  question.questionText,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    'Correct Answer: ${question.options[question.correctOptionIndex]}',
                                    style: TextStyle(
                                      color: Colors.green.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.edit,
                                        color: Colors.blue,
                                      ),
                                      onPressed: () =>
                                          _showEditDialog(context, question),
                                      tooltip: 'Edit',
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      onPressed: () =>
                                          _confirmDelete(context, question),
                                      tooltip: 'Delete',
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, Question question) {
    final questionController = TextEditingController(
      text: question.questionText,
    );
    final optionControllers = List.generate(
      4,
      (i) => TextEditingController(text: question.options[i]),
    );
    int correctOptionIndex = question.correctOptionIndex;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Question'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: questionController,
                  decoration: const InputDecoration(labelText: 'Question'),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                ...List.generate(4, (index) {
                  return Row(
                    children: [
                      Radio<int>(
                        value: index,
                        groupValue: correctOptionIndex,
                        onChanged: (val) =>
                            setState(() => correctOptionIndex = val!),
                      ),
                      Expanded(
                        child: TextField(
                          controller: optionControllers[index],
                          decoration: InputDecoration(
                            labelText: 'Option ${index + 1}',
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  final updatedQuestion = Question(
                    id: question.id,
                    questionText: questionController.text,
                    options: optionControllers.map((c) => c.text).toList(),
                    correctOptionIndex: correctOptionIndex,
                    chapterId: question.chapterId,
                  );

                  await Provider.of<QuizService>(
                    context,
                    listen: false,
                  ).updateQuestion(updatedQuestion);

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Question updated successfully'),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error updating question: $e')),
                    );
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Question question) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Question'),
        content: const Text('Are you sure you want to delete this question?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                if (question.id != null) {
                  await Provider.of<QuizService>(
                    context,
                    listen: false,
                  ).deleteQuestion(question.id!);

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Question deleted successfully'),
                      ),
                    );
                  }
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting question: $e')),
                  );
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
