import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../providers/habit_provider.dart';
import '../models/habit_model.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  // Heatmap month offset: 0 = current month, -1 = last month, etc.
  int _monthOffset = 0;

  @override
  Widget build(BuildContext context) {
    final habitProvider = Provider.of<HabitProvider>(context);
    final habits = habitProvider.habits;

    return Scaffold(
      appBar: AppBar(
        title: Text("My Progress", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProgressSummary(habits),
            const SizedBox(height: 30),
            Text(
              "Contribution Grid 👋",
              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildGitHubHeatmap(habits),
            const SizedBox(height: 30),
            Text(
              "Habit Breakdowns",
              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            ...habits.map((habit) => _buildHabitBreakdown(habit)),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressSummary(List<Habit> habits) {
    if (habits.isEmpty) return const SizedBox.shrink();
    final double avgRate = habits.isEmpty ? 0.0 : (habits.fold(0.0, (sum, h) => sum + h.completionRate) / habits.length);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1F1F25),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLargeProgressRing(avgRate),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildInfoStat("Best Streak", "${habits.fold(0, (max, h) => h.streak > max ? h.streak : max)} days", Colors.orange),
              _buildInfoStat("Total Done", habits.fold(0, (sum, h) => sum + h.completionDates.length).toString(), Colors.blue),
              _buildInfoStat("Active", habits.length.toString(), Colors.green),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLargeProgressRing(double percent) {
    return SizedBox(
      height: 160,
      width: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            height: 140,
            width: 140,
            child: CircularProgressIndicator(
              value: percent,
              strokeWidth: 12,
              backgroundColor: Colors.white10,
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1D9E75)),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "${(percent * 100).toInt()}%",
                style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              Text(
                "AVERAGE",
                style: GoogleFonts.outfit(fontSize: 12, color: Colors.white38, letterSpacing: 1.2),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: GoogleFonts.outfit(fontSize: 12, color: Colors.white38)),
      ],
    );
  }

  Widget _buildGitHubHeatmap(List<Habit> habits) {
    final now = DateTime.now();
    // Calculate the displayed month based on offset
    final displayedMonth = DateTime(now.year, now.month + _monthOffset, 1);
    final firstDay = DateTime(displayedMonth.year, displayedMonth.month, 1);
    final daysInMonth = DateTime(displayedMonth.year, displayedMonth.month + 1, 0).day;

    // Count completions per day for intensity
    final Map<String, int> dailyCounts = {};
    for (final h in habits) {
      for (final d in h.completionDates) {
        final dateKey = DateFormat('yyyy-MM-dd').format(d);
        dailyCounts[dateKey] = (dailyCounts[dateKey] ?? 0) + 1;
      }
    }

    final monthLabel = DateFormat('M/yyyy').format(displayedMonth);
    final isCurrentMonth = _monthOffset == 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1F1F25),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "ACTIVITY HEATMAP",
                style: GoogleFonts.outfit(fontSize: 12, color: Colors.white38, fontWeight: FontWeight.bold, letterSpacing: 1.2),
              ),
              // Month navigation
              Row(
                children: [
                  // Previous month button
                  GestureDetector(
                    onTap: () => setState(() => _monthOffset--),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.chevron_left, color: Colors.white54, size: 18),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      monthLabel,
                      style: GoogleFonts.outfit(fontSize: 12, color: Colors.white60, fontWeight: FontWeight.w600),
                    ),
                  ),
                  // Next month button (disabled if current month)
                  GestureDetector(
                    onTap: isCurrentMonth ? null : () => setState(() => _monthOffset++),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isCurrentMonth ? Colors.transparent : Colors.white10,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.chevron_right,
                        color: isCurrentMonth ? Colors.white24 : Colors.white54,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
            ),
            itemCount: daysInMonth,
            itemBuilder: (context, index) {
              final date = firstDay.add(Duration(days: index));
              final dateStr = DateFormat('yyyy-MM-dd').format(date);
              final count = dailyCounts[dateStr] ?? 0;
              final isFuture = date.isAfter(now);

              // Calculate opacity based on count relative to total habits
              double opacity = 0.05;
              if (count > 0) {
                opacity = 0.2 + (count / (habits.isEmpty ? 1 : habits.length)) * 0.8;
                if (opacity > 1.0) opacity = 1.0;
              }

              return Container(
                decoration: BoxDecoration(
                  color: isFuture
                      ? Colors.transparent
                      : const Color(0xFF1D9E75).withOpacity(opacity),
                  borderRadius: BorderRadius.circular(4),
                  border: isFuture
                      ? Border.all(color: Colors.white.withOpacity(0.05))
                      : (count == 0 ? Border.all(color: Colors.white.withOpacity(0.05)) : null),
                ),
                child: Center(
                  child: Text(
                    "${date.day}",
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      color: isFuture || count == 0 ? Colors.white10 : Colors.white70,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHabitBreakdown(Habit habit) {
    final color = Color(int.parse(habit.color, radix: 16));
    final completionRate = habit.completionRate;
    final now = DateTime.now();
    
    String progressText = "${(completionRate * 100).toInt()}% consistency";
    int totalDaysInRange = -1;
    int completedInRange = 0;

    if (habit.startDate != null && habit.endDate != null) {
      totalDaysInRange = habit.endDate!.difference(habit.startDate!).inDays + 1;
      completedInRange = habit.completionDates.where((d) => 
        !d.isBefore(habit.startDate!) && !d.isAfter(habit.endDate!)
      ).length;
      progressText = "$completedInRange / $totalDaysInRange days";
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1F1F25),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(habit.emoji, style: const TextStyle(fontSize: 18)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(habit.name, 
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 15)),
                    if (habit.startDate != null && habit.endDate != null)
                      Text(
                        '${DateFormat('d/M/yy').format(habit.startDate!)} → ${DateFormat('d/M/yy').format(habit.endDate!)}',
                        style: GoogleFonts.outfit(fontSize: 11, color: Colors.white38),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(progressText, 
                    style: GoogleFonts.outfit(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                  if (totalDaysInRange != -1)
                    Text("${(completionRate * 100).toInt()}% efficiency",
                      style: GoogleFonts.outfit(color: Colors.white24, fontSize: 10)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Stack(
            children: [
              LinearProgressIndicator(
                value: totalDaysInRange != -1 ? (completedInRange / totalDaysInRange) : completionRate,
                backgroundColor: Colors.white10,
                valueColor: AlwaysStoppedAnimation<Color>(color),
                borderRadius: BorderRadius.circular(10),
                minHeight: 10,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
