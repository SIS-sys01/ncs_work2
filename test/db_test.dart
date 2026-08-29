import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:ncs_work/data/models/question_model.dart';

void main() {
  test('QuizViewModel parsing test', () {
    final file = File('assets/data/subject3_questions.json');
    final data = json.decode(file.readAsStringSync());
    final rawList = data['questions'] as List<dynamic>;
    
    final rawQuestions = rawList.map((q) => QuestionModel.fromMap(q)).toList();
    
    try {
      final freshQuestions = rawQuestions.map((q) {
        if (q.questionType == 'dynamic_match') {
          final options = List<dynamic>.from(q.dynamicOptions ?? []);
          options.shuffle(Random());
          return q.copyWith(userAnswer: '', dynamicOptions: options);
        } else if (q.questionType == 'cloze') {
          final text = q.clozeText ?? '';
          final exp = RegExp(r'\[blank\|([^\]]+)\]');
          final matches = exp.allMatches(text).toList();

          matches.shuffle(Random());
          final selectedMatches = matches.take(5).toList();
          final selectedStarts = selectedMatches.map((e) => e.start).toSet();

          List<String> answers = [];
          final displayText = text.replaceAllMapped(exp, (match) {
            if (selectedStarts.contains(match.start)) {
              answers.add(match.group(1)!);
              return '________';
            } else {
              return match.group(1)!;
            }
          });

          return q.copyWith(
            userAnswer: '',
            clozeDisplayText: displayText,
            clozeAnswers: answers,
          );
        }
        return q.copyWith(userAnswer: '');
      }).toList();
      expect(freshQuestions.isNotEmpty, true);
    } catch(e) {
      fail("Error parsing: \$e\\n\$s");
    }
  });
}
