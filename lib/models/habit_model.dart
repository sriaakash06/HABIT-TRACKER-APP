import 'package:cloud_firestore/cloud_firestore.dart';

class Habit {
  final String id;
  final String userId;
  final String name;
  final String emoji;
  final int streak;
  final DateTime lastCompleted;
  final List<DateTime> completionDates;
  final String color;
  final String category;
  final DateTime? startDate;
  final DateTime? endDate;

  Habit({
    required this.id,
    required this.userId,
    required this.name,
    required this.emoji,
    required this.streak,
    required this.lastCompleted,
    required this.completionDates,
    this.color = 'FF7C3AED',
    this.category = 'General',
    this.startDate,
    this.endDate,
  });

  factory Habit.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Habit(
      id: doc.id,
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      emoji: data['emoji'] ?? '🔥',
      streak: data['streak'] ?? 0,
      lastCompleted: (data['lastCompleted'] as Timestamp?)?.toDate() ?? DateTime(2000),
      completionDates: (data['completionDates'] as List<dynamic>?)
              ?.map((e) => (e as Timestamp).toDate())
              .toList() ??
          [],
      color: data['color'] ?? 'FF7C3AED',
      category: data['category'] ?? 'General',
      startDate: (data['startDate'] as Timestamp?)?.toDate(),
      endDate: (data['endDate'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'emoji': emoji,
      'streak': streak,
      'lastCompleted': Timestamp.fromDate(lastCompleted),
      'completionDates': completionDates.map((e) => Timestamp.fromDate(e)).toList(),
      'color': color,
      'category': category,
      if (startDate != null) 'startDate': Timestamp.fromDate(startDate!),
      if (endDate != null) 'endDate': Timestamp.fromDate(endDate!),
    };
  }

  bool get isCompletedToday {
    final now = DateTime.now();
    return lastCompleted.year == now.year &&
        lastCompleted.month == now.month &&
        lastCompleted.day == now.day;
  }

  double get completionRate {
    if (completionDates.isEmpty) return 0.0;
    final now = DateTime.now();

    // If a date range is set, calculate based on that range
    if (startDate != null && endDate != null) {
      final rangeStart = startDate!;
      final rangeEnd = endDate!.isAfter(now) ? now : endDate!;

      // Total days in the range up to today
      final totalDays = rangeEnd.difference(rangeStart).inDays + 1;
      if (totalDays <= 0) return 0.0;

      // Count completions within the range
      final completed = completionDates.where((date) {
        final d = DateTime(date.year, date.month, date.day);
        final s = DateTime(rangeStart.year, rangeStart.month, rangeStart.day);
        final e = DateTime(rangeEnd.year, rangeEnd.month, rangeEnd.day);
        return !d.isBefore(s) && !d.isAfter(e);
      }).length;

      return (completed / totalDays).clamp(0.0, 1.0);
    }

    // Fallback: last 30 days
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    final relevantCompletions = completionDates.where((date) => date.isAfter(thirtyDaysAgo)).length;
    return (relevantCompletions / 30).clamp(0.0, 1.0);
  }
}
