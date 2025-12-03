import 'package:flutter/material.dart';
import '../models/quiz_models.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

class QuizService extends ChangeNotifier {
  static final QuizService _instance = QuizService._internal();

  factory QuizService() {
    return _instance;
  }

  StreamSubscription<QuerySnapshot>? _questionsSubscription;
  StreamSubscription<QuerySnapshot>? _chaptersSubscription;

  QuizService._internal() {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        _fetchChapters();
        _fetchQuestions();
      } else {
        _questionsSubscription?.cancel();
        _chaptersSubscription?.cancel();
        _questionsSubscription = null;
        _chaptersSubscription = null;
      }
    });
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Hardcoded structure for Courses, Groups, and Subjects
  // Questions will be loaded from Firestore
  final List<CourseLevel> _caCourses = [
    CourseLevel(
      id: 'foundation',
      name: 'CA Foundation',
      color: Colors.blue,
      icon: Icons.foundation,
      groups: [
        CourseGroup(
          name: 'All Papers',
          subjects: [
            Subject(
              id: 'f_acc',
              name: 'Accounting',
              color: Colors.blueAccent,
              icon: Icons.account_balance,
              questions: [],
              chapters: [],
            ),
            Subject(
              id: 'f_law',
              name: 'Business Laws',
              color: Colors.indigo,
              icon: Icons.gavel,
              questions: [],
              chapters: [],
            ),
            Subject(
              id: 'f_math',
              name: 'Quantitative Aptitude',
              color: Colors.teal,
              icon: Icons.calculate,
              questions: [],
              chapters: [],
            ),
            Subject(
              id: 'f_eco',
              name: 'Business Economics',
              color: Colors.cyan,
              icon: Icons.trending_up,
              questions: [],
              chapters: [],
            ),
          ],
        ),
      ],
    ),
    CourseLevel(
      id: 'inter',
      name: 'CA Intermediate',
      color: Colors.orange,
      icon: Icons.layers,
      groups: [
        CourseGroup(
          name: 'Group 1',
          subjects: [
            Subject(
              id: 'i_adv_acc',
              name: 'Advanced Accounting',
              color: Colors.deepOrange,
              icon: Icons.account_balance_wallet,
              questions: [],
              chapters: [],
            ),
            Subject(
              id: 'i_law',
              name: 'Corporate & Other Laws',
              color: Colors.redAccent,
              icon: Icons.balance,
              questions: [],
              chapters: [],
            ),
            Subject(
              id: 'i_tax_dt',
              name: 'Taxation (Income Tax)',
              color: Colors.green,
              icon: Icons.currency_rupee,
              questions: [],
              chapters: [],
            ),
            Subject(
              id: 'i_tax_idt',
              name: 'Taxation (GST)',
              color: Colors.lightGreen,
              icon: Icons.percent,
              questions: [],
              chapters: [],
            ),
          ],
        ),
        CourseGroup(
          name: 'Group 2',
          subjects: [
            Subject(
              id: 'i_cost',
              name: 'Cost & Mgmt Accounting',
              color: Colors.amber,
              icon: Icons.pie_chart,
              questions: [],
              chapters: [],
            ),
            Subject(
              id: 'i_audit',
              name: 'Auditing & Ethics',
              color: Colors.purple,
              icon: Icons.find_in_page,
              questions: [],
              chapters: [],
            ),
            Subject(
              id: 'i_fm',
              name: 'FM & SM',
              color: Colors.lightGreen,
              icon: Icons.bar_chart,
              questions: [],
              chapters: [],
            ),
          ],
        ),
      ],
    ),
    CourseLevel(
      id: 'final',
      name: 'CA Final',
      color: Colors.red,
      icon: Icons.school,
      groups: [
        CourseGroup(
          name: 'Group 1',
          subjects: [
            Subject(
              id: 'fi_fr',
              name: 'Financial Reporting',
              color: Colors.indigoAccent,
              icon: Icons.description,
              questions: [],
              chapters: [],
            ),
            Subject(
              id: 'fi_afm',
              name: 'Adv. Financial Mgmt',
              color: Colors.blueGrey,
              icon: Icons.analytics,
              questions: [],
              chapters: [],
            ),
            Subject(
              id: 'fi_audit',
              name: 'Adv. Auditing',
              color: Colors.deepPurple,
              icon: Icons.verified,
              questions: [],
              chapters: [],
            ),
          ],
        ),
        CourseGroup(
          name: 'Group 2',
          subjects: [
            Subject(
              id: 'fi_dt',
              name: 'Direct Tax Laws',
              color: Colors.greenAccent,
              icon: Icons.money,
              questions: [],
              chapters: [],
            ),
            Subject(
              id: 'fi_idt',
              name: 'Indirect Tax Laws',
              color: Colors.tealAccent,
              icon: Icons.shopping_cart,
              questions: [],
              chapters: [],
            ),
            Subject(
              id: 'fi_ibs',
              name: 'IBS',
              color: Colors.brown,
              icon: Icons.integration_instructions,
              questions: [],
              chapters: [],
            ),
          ],
        ),
      ],
    ),
  ];

  List<CourseLevel> get caCourses => _caCourses;

  void _fetchChapters() {
    _chaptersSubscription?.cancel();
    _chaptersSubscription = _firestore
        .collection('chapters')
        .snapshots()
        .listen(
          (snapshot) {
            // Clear existing chapters
            for (var course in _caCourses) {
              for (var group in course.groups) {
                for (var subject in group.subjects) {
                  subject.chapters.clear();
                }
              }
            }

            for (var doc in snapshot.docs) {
              final data = doc.data();
              final chapter = Chapter(
                id: doc.id,
                name: data['name'],
                questions: [],
              );
              final subjectId = data['subjectId'];

              // Add chapter to subject
              for (var course in _caCourses) {
                for (var group in course.groups) {
                  for (var subject in group.subjects) {
                    if (subject.id == subjectId) {
                      subject.chapters.add(chapter);
                    }
                  }
                }
              }
            }
            notifyListeners();
          },
          onError: (error) {
            debugPrint('Error fetching chapters: $error');
          },
        );
  }

  void _fetchQuestions() {
    _questionsSubscription?.cancel();
    _questionsSubscription = _firestore
        .collection('questions')
        .snapshots()
        .listen(
          (snapshot) {
            // Clear existing questions to avoid duplicates when updating
            for (var course in _caCourses) {
              for (var group in course.groups) {
                for (var subject in group.subjects) {
                  subject.questions.clear();
                  for (var chapter in subject.chapters) {
                    chapter.questions.clear();
                  }
                }
              }
            }

            for (var doc in snapshot.docs) {
              final data = doc.data();
              final question = Question(
                id: doc.id,
                questionText: data['questionText'],
                options: List<String>.from(data['options']),
                correctOptionIndex: data['correctOptionIndex'],
                chapterId: data['chapterId'],
              );

              final subjectId = data['subjectId'];
              final chapterId = data['chapterId'];

              // Find the subject and add the question
              for (var course in _caCourses) {
                for (var group in course.groups) {
                  for (var subject in group.subjects) {
                    if (subject.id == subjectId) {
                      subject.questions.add(question);
                      if (chapterId != null) {
                        for (var chapter in subject.chapters) {
                          if (chapter.id == chapterId) {
                            chapter.questions.add(question);
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
            notifyListeners();
          },
          onError: (error) {
            debugPrint('Error fetching questions: $error');
          },
        );
  }

  Future<void> addQuestion(
    String courseId,
    String groupName,
    String subjectId,
    Question question, {
    String? chapterId,
  }) async {
    await _firestore.collection('questions').add({
      'courseId': courseId,
      'groupName': groupName,
      'subjectId': subjectId,
      'chapterId': chapterId,
      'questionText': question.questionText,
      'options': question.options,
      'correctOptionIndex': question.correctOptionIndex,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateQuestion(Question question) async {
    if (question.id == null) return;
    await _firestore.collection('questions').doc(question.id).update({
      'questionText': question.questionText,
      'options': question.options,
      'correctOptionIndex': question.correctOptionIndex,
      'chapterId': question.chapterId,
    });
  }

  Future<void> deleteQuestion(String questionId) async {
    await _firestore.collection('questions').doc(questionId).delete();
  }

  Future<void> addChapter(
    String courseId,
    String groupName,
    String subjectId,
    String chapterName,
  ) async {
    await _firestore.collection('chapters').add({
      'courseId': courseId,
      'groupName': groupName,
      'subjectId': subjectId,
      'name': chapterName,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
