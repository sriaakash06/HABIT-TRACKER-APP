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

  /// Toggle completion for a specific date
  Future<void> toggleHabitCompletion(Habit habit, [DateTime? dateOrNull]) async {
    final date = dateOrNull ?? DateTime.now();
    final isCompletedOn = habit.completionDates.any((d) => 
      d.year == date.year && d.month == date.month && d.day == date.day
    );

    if (isCompletedOn) {
      await _uncompleteHabit(habit, date);
    } else {
      await _completeHabit(habit, date);
    }
  }

  Future<void> _completeHabit(Habit habit, DateTime date) async {
    List<DateTime> updatedDates = List.from(habit.completionDates);
    updatedDates.add(date);
    updatedDates.sort((a, b) => b.compareTo(a));

    // Recalculate streak based on latest status
    int newStreak = 0;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (updatedDates.isNotEmpty) {
      final lastDate = DateTime(updatedDates.first.year, updatedDates.first.month, updatedDates.first.day);
      
      // Streak is only active if last completion was today or yesterday
      if (lastDate.isAtSameMomentAs(today) || lastDate.isAtSameMomentAs(yesterday)) {
        newStreak = 1;
        for (int i = 0; i < updatedDates.length - 1; i++) {
          final d1 = DateTime(updatedDates[i].year, updatedDates[i].month, updatedDates[i].day);
          final d2 = DateTime(updatedDates[i+1].year, updatedDates[i+1].month, updatedDates[i+1].day);
          if (d1.difference(d2).inDays == 1) {
            newStreak++;
          } else if (d1.difference(d2).inDays == 0) {
            continue; // Duplicate date entry, ignore for streak
          } else {
            break;
          }
        }
      } else {
        newStreak = 0; // Streak broken
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
        lastCompleted: updatedDates.first,
        completionDates: updatedDates,
        color: habit.color,
        category: habit.category,
        startDate: habit.startDate,
        endDate: habit.endDate,
      );
      notifyListeners();
    }

    await _firestore.collection('habits').doc(habit.id).update({
      'lastCompleted': Timestamp.fromDate(updatedDates.first),
      'streak': newStreak,
      'completionDates':
          updatedDates.map((e) => Timestamp.fromDate(e)).toList(),
    });
  }

  Future<void> _uncompleteHabit(Habit habit, DateTime date) async {
    // Remove completion entry for specified date
    final updatedDates = habit.completionDates.where((d) {
      return !(d.year == date.year && d.month == date.month && d.day == date.day);
    }).toList();
    updatedDates.sort((a, b) => b.compareTo(a));

    // Recalculate streak
    int newStreak = 0;
    DateTime newLastCompleted = DateTime(2000);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (updatedDates.isNotEmpty) {
      newLastCompleted = updatedDates.first;
      final lastDate = DateTime(newLastCompleted.year, newLastCompleted.month, newLastCompleted.day);
      
      if (lastDate.isAtSameMomentAs(today) || lastDate.isAtSameMomentAs(yesterday)) {
        newStreak = 1;
        for (int i = 0; i < updatedDates.length - 1; i++) {
          final d1 = DateTime(updatedDates[i].year, updatedDates[i].month, updatedDates[i].day);
          final d2 = DateTime(updatedDates[i+1].year, updatedDates[i+1].month, updatedDates[i+1].day);
          if (d1.difference(d2).inDays == 1) {
            newStreak++;
          } else if (d1.difference(d2).inDays == 0) {
            continue;
          } else {
            break;
          }
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
  Future<void> completeHabit(Habit habit) => toggleHabitCompletion(habit, DateTime.now());

  Future<void> deleteHabit(String id) async {
    _habits.removeWhere((h) => h.id == id);
    notifyListeners();
    await _firestore.collection('habits').doc(id).delete();
  }
}
