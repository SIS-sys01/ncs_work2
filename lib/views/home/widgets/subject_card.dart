import 'package:flutter/material.dart';

/// 메인 홈 화면의 개별 과목 카드 위젯 (Stateless)
class SubjectCard extends StatelessWidget {
  final int subjectId;
  final String subjectName;
  final VoidCallback onTap;

  const SubjectCard({
    super.key,
    required this.subjectId,
    required this.subjectName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAvailable = (subjectId == 1 || subjectId == 3);

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isAvailable
            ? BorderSide(color: theme.colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isAvailable
                          ? theme.colorScheme.primary
                          : theme.colorScheme.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '제$subjectId과목',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isAvailable
                            ? Colors.white
                            : theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  if (isAvailable)
                    const Icon(
                      Icons.star_rounded,
                      color: Colors.amber,
                      size: 20,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Center(
                  child: Text(
                    subjectName.replaceAll(RegExp(r'^\d+'), ''),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                (subjectId == 1 || subjectId == 3)
                    ? '내부/외부평가 탑재'
                    : '추후 확장 예정',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isAvailable ? Colors.greenAccent : theme.hintColor,
                  fontWeight: isAvailable ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
