import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/habit_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HabitProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Habit> _habits = [];

  List<Habit> get habits => _habits;

  Future<void> fetchHabits() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snapshot = await _firestore
        .collection('habits')
        .where('userId', isEqualTo: user.uid)
        .get();

    _habits = snapshot.docs.map((doc) => Habit.fromFirestore(doc)).toList();
    notifyListeners();
  }

  Future<void> addHabit(
    String name,
    String emoji, {
    String color = 'FF7C3AED',
    String category = 'General',
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final habitMap = {
      'userId': user.uid,
      'name': name,
      'emoji': emoji,
      'streak': 0,
      'lastCompleted': Timestamp.fromDate(DateTime(2000)),
      'completionDates': [],
      'color': color,
      'category': category,
      if (startDate != null) 'startDate': Timestamp.fromDate(startDate),
      if (endDate != null) 'endDate': Timestamp.fromDate(endDate),
    };

    final docRef = _firestore.collection('habits').doc();
    final newHabit = Habit(
      id: docRef.id,
      userId: user.uid,
      name: name,
      emoji: emoji,
      streak: 0,
      lastCompleted: DateTime(2000),
      completionDates: [],
      color: color,
      category: category,
      startDate: startDate,
      endDate: endDate,
    );
    _habits.insert(0, newHabit);
    notifyListeners();

    try {
      await docRef.set(habitMap);
    } catch (e) {
      _habits.remove(newHabit);
      notifyListeners();
    }
  }

  Future<void> updateHabit(Habit habit,
      {String? name,
      String? emoji,
      String? color,
      DateTime? startDate,
      DateTime? endDate}) async {
    final index = _habits.indexWhere((h) => h.id == habit.id);
    if (index == -1) return;

    final updated = Habit(
      id: habit.id,
      userId: habit.userId,
      name: name ?? habit.name,
      emoji: emoji ?? habit.emoji,
      streak: habit.streak,
      lastCompleted: habit.lastCompleted,
      completionDates: habit.completionDates,
      color: color ?? habit.color,
      category: habit.category,
      startDate: startDate ?? habit.startDate,
      endDate: endDate ?? habit.endDate,
    );

    _habits[index] = updated;
    notifyListeners();

    final updateMap = <String, dynamic>{
      'name': updated.name,
      'emoji': updated.emoji,
      'color': updated.color,
    };
    if (updated.startDate != null)
      updateMap['startDate'] = Timestamp.fromDate(updated.startDate!);
    if (updated.endDate != null)
      updateMap['endDate'] = Timestamp.fromDate(updated.endDate!);

    await _firestore.collection('habits').doc(habit.id).update(updateMap);
  }

  /// Toggle completion for today: tick → untick, untick → tick
  Future<void> toggleHabitCompletion(Habit habit) async {
    if (habit.isCompletedToday) {
      await _uncompleteHabit(habit);
    } else {
      await _completeHabit(habit);
    }
  }

  Future<void> _completeHabit(Habit habit) async {
    final now = DateTime.now();

    List<DateTime> updatedDates = List.from(habit.completionDates);
    updatedDates.add(now);

    int newStreak = habit.streak;
    final yesterday = now.subtract(const Duration(days: 1));
    bool wasCompletedYesterday = habit.lastCompleted.year == yesterday.year &&
        habit.lastCompleted.month == yesterday.month &&
        habit.lastCompleted.day == yesterday.day;

    if (wasCompletedYesterday || habit.streak == 0) {
      newStreak++;
    } else {
      newStreak = 1;
    }

    final index = _habits.indexWhere((h) => h.id == habit.id);
    if (index != -1) {
      _habits[index] = Habit(
        id: habit.id,
        userId: habit.userId,
        name: habit.name,
        emoji: habit.emoji,
        streak: newStreak,
        lastCompleted: now,
        completionDates: updatedDates,
        color: habit.color,
        category: habit.category,
        startDate: habit.startDate,
        endDate: habit.endDate,
      );
      notifyListeners();
    }

    await _firestore.collection('habits').doc(habit.id).update({
      'lastCompleted': Timestamp.fromDate(now),
      'streak': newStreak,
      'completionDates':
          updatedDates.map((e) => Timestamp.fromDate(e)).toList(),
    });
  }

  Future<void> _uncompleteHabit(Habit habit) async {
    final now = DateTime.now();

    // Remove today's completion entries
    final updatedDates = habit.completionDates.where((d) {
      return !(d.year == now.year && d.month == now.month && d.day == now.day);
    }).toList();

    // Recalculate streak: go back to previous lastCompleted
    DateTime newLastCompleted = DateTime(2000);
    int newStreak = 0;

    if (updatedDates.isNotEmpty) {
      final sorted = List<DateTime>.from(updatedDates)
        ..sort((a, b) => b.compareTo(a));
      newLastCompleted = sorted.first;

      // Recalculate streak from sorted dates
      newStreak = 1;
      for (int i = 0; i < sorted.length - 1; i++) {
        final diff = sorted[i]
            .difference(DateTime(
                sorted[i + 1].year, sorted[i + 1].month, sorted[i + 1].day))
            .inDays;
        if (diff == 1) {
          newStreak++;
        } else {
          break;
        }
      }
    }

    final index = _habits.indexWhere((h) => h.id == habit.id);
    if (index != -1) {
      _habits[index] = Habit(
        id: habit.id,
        userId: habit.userId,
        name: habit.name,
        emoji: habit.emoji,
        streak: newStreak,
        lastCompleted: newLastCompleted,
        completionDates: updatedDates,
        color: habit.color,
        category: habit.category,
        startDate: habit.startDate,
        endDate: habit.endDate,
      );
      notifyListeners();
    }

    await _firestore.collection('habits').doc(habit.id).update({
      'lastCompleted': Timestamp.fromDate(newLastCompleted),
      'streak': newStreak,
      'completionDates':
          updatedDates.map((e) => Timestamp.fromDate(e)).toList(),
    });
  }

  // Keep for backward compat
  Future<void> completeHabit(Habit habit) => toggleHabitCompletion(habit);

  Future<void> deleteHabit(String id) async {
    _habits.removeWhere((h) => h.id == id);
    notifyListeners();
    await _firestore.collection('habits').doc(id).delete();
  }
}
