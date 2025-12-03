import 'package:flutter/material.dart';

class Question {
  final String? id;
  final String questionText;
  final List<String> options;
  final int correctOptionIndex;
  final String? chapterId;

  Question({
    this.id,
    required this.questionText,
    required this.options,
    required this.correctOptionIndex,
    this.chapterId,
  });
}

class Chapter {
  final String id;
  final String name;
  final List<Question> questions;

  Chapter({required this.id, required this.name, required this.questions});
}

class Subject {
  final String name;
  final String id;
  final List<Question> questions;
  final List<Chapter> chapters;
  final Color color;
  final IconData icon;

  Subject({
    required this.name,
    required this.id,
    required this.questions,
    this.chapters = const [],
    required this.color,
    required this.icon,
  });
}

class CourseGroup {
  final String name;
  final List<Subject> subjects;

  CourseGroup({required this.name, required this.subjects});
}

class CourseLevel {
  final String name;
  final String id;
  final List<CourseGroup> groups;
  final Color color;
  final IconData icon;

  CourseLevel({
    required this.name,
    required this.id,
    required this.groups,
    required this.color,
    required this.icon,
  });
}
