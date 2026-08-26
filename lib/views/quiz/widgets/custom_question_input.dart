import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ncs_work/core/constants/app_colors.dart';
import 'package:ncs_work/data/models/question_model.dart';
import 'package:ncs_work/viewmodels/quiz_viewmodel.dart';

class CustomQuestionInput extends ConsumerStatefulWidget {
  final QuestionModel question;
  final bool isDark;
  final bool isSubmitted;

  const CustomQuestionInput({
    super.key,
    required this.question,
    required this.isDark,
    required this.isSubmitted,
  });

  @override
  ConsumerState<CustomQuestionInput> createState() => _CustomQuestionInputState();
}

class _CustomQuestionInputState extends ConsumerState<CustomQuestionInput> {
  late List<TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  @override
  void didUpdateWidget(covariant CustomQuestionInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.question.id != widget.question.id) {
      _initControllers();
    }
  }

  void _initControllers() {
    int count = 1;
    if (widget.question.questionType == 'dynamic_match') {
      count = widget.question.dynamicOptions?.length ?? 1;
    } else if (widget.question.questionType == 'cloze') {
      count = 5; // 빈칸 5개
    }
    
    _controllers = List.generate(count, (index) => TextEditingController());
    
    // 만약 기존 userAnswer가 있으면 세팅
    final ans = widget.question.userAnswer;
    if (ans != null && ans.isNotEmpty && ans.startsWith('[')) {
      try {
        final List<dynamic> parsed = json.decode(ans);
        for (int i = 0; i < parsed.length && i < _controllers.length; i++) {
          _controllers[i].text = parsed[i].toString();
        }
      } catch (_) {}
    } else if (ans != null && ans.isNotEmpty) {
       _controllers[0].text = ans;
    }
  }

  @override
  void dispose() {
    for (var c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _onChanged() {
    // 모든 텍스트를 리스트로 묶어 JSON string으로 전달
    final list = _controllers.map((c) => c.text).toList();
    ref.read(quizProvider.notifier).updateInputText(json.encode(list));
  }

  Widget _buildTextField(int index, String hint) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextField(
        controller: _controllers[index],
        enabled: !widget.isSubmitted,
        maxLines: 2,
        onChanged: (_) => _onChanged(),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: widget.isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
          ),
          filled: true,
          fillColor: widget.isDark ? AppColors.darkCard : AppColors.lightCard,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.question.questionType == 'dynamic_match') {
      final opts = widget.question.dynamicOptions ?? [];
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: List.generate(opts.length, (index) {
          final opt = opts[index];
          final prompt = opt['prompt'] ?? '';
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '예시 ${index + 1}: $prompt',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildTextField(index, '위 예시에 해당하는 문제 유형을 입력하세요...'),
            ],
          );
        }),
      );
    } else if (widget.question.questionType == 'cloze') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: List.generate(5, (index) {
          return Row(
            children: [
              Text('${index + 1}번 괄호: ', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Expanded(
                child: _buildTextField(index, '괄호 안 단어 입력...'),
              ),
            ],
          );
        }),
      );
    }

    // 기본 서술형
    return TextField(
      controller: _controllers[0],
      maxLines: 5,
      enabled: !widget.isSubmitted,
      onChanged: (_) => _onChanged(),
      decoration: InputDecoration(
        hintText: '문제에 대한 서술/기술형 답안을 직접 타이핑하여 작성하세요...',
        hintStyle: TextStyle(
          color: widget.isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
        ),
        filled: true,
        fillColor: widget.isDark ? AppColors.darkCard : AppColors.lightCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }
}
