import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart' hide Border;

import '../providers/auth_provider.dart';
import '../providers/habit_provider.dart';
import '../providers/theme_provider.dart';
import '../models/habit_model.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isExporting = false;

  List<int> _getLast7DaysData(List<Habit> habits) {
    final now = DateTime.now();
    List<int> data = List.filled(7, 0);
    for (int i = 0; i < 7; i++) {
      final d = DateTime(now.year, now.month, now.day).subtract(Duration(days: 6 - i));
      data[i] = habits.where((h) => h.completionDates.any((cd) =>
          cd.year == d.year && cd.month == d.month && cd.day == d.day)).length;
    }
    return data;
  }

  Map<String, double> _getTodayStats(List<Habit> habits) {
    if (habits.isEmpty) return {"Done": 0, "Pending": 1};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    int done = habits.where((h) => h.completionDates.any((d) => 
      d.year == today.year && d.month == today.month && d.day == today.day
    )).length;
    int pending = habits.length - done;
    return {"Done": done.toDouble(), "Pending": pending.toDouble()};
  }

  Future<void> _exportPdf(List<Habit> habits, List<int> chartData) async {
    setState(() => _isExporting = true);
    try {
      final pdf = pw.Document();
      final now = DateTime.now();

      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Habit Tracker Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 10),
                pw.Text('Generated on: ${DateFormat('yyyy-MM-dd').format(now)}'),
                pw.SizedBox(height: 20),
                pw.Text('Last 7 Days Completions:', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 10),
                ...List.generate(7, (index) {
                  final d = now.subtract(Duration(days: 6 - index));
                  return pw.Text('${DateFormat('EEE, MMM d').format(d)}: ${chartData[index]} habits completed');
                }),
                pw.SizedBox(height: 20),
                pw.Text('All Habits:', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 10),
                ...habits.map((h) => pw.Text('- ${h.name}: ${h.streak} day streak')),
              ],
            );
          },
        ),
      );

      if (kIsWeb) {
        throw Exception('PDF Export not supported in this web demo yet. Use a real device for PDF generation.');
      }
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/habit_report.pdf');
      await file.writeAsBytes(await pdf.save());

      await Share.shareXFiles([XFile(file.path)], text: 'My Habit Report (PDF)');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error exporting PDF: $e')));
      }
    } finally {
      if (context.mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _exportExcel(List<Habit> habits, List<int> chartData) async {
    setState(() => _isExporting = true);
    try {
      var excel = Excel.createExcel();
      Sheet sheetObject = excel['Sheet1'];

      // Write basic header
      sheetObject.appendRow([
        TextCellValue('Date'),
        TextCellValue('Habits Completed'),
      ]);

      final now = DateTime.now();
      for (int i = 0; i < 7; i++) {
        final d = now.subtract(Duration(days: 6 - i));
        sheetObject.appendRow([
          TextCellValue(DateFormat('yyyy-MM-dd').format(d)),
          IntCellValue(chartData[i]),
        ]);
      }

      sheetObject.appendRow([TextCellValue(''), TextCellValue('')]);
      sheetObject.appendRow([TextCellValue('Habit Name'), TextCellValue('Streak')]);
      for (var h in habits) {
        sheetObject.appendRow([
          TextCellValue(h.name),
          IntCellValue(h.streak),
        ]);
      }

      var fileBytes = excel.save();
      if (fileBytes != null) {
        if (kIsWeb) {
        throw Exception('Excel Export not supported in this web demo yet. Use a real device for Excel generation.');
      }
      final output = await getTemporaryDirectory();
        final file = File('${output.path}/habit_report.xlsx');
        await file.writeAsBytes(fileBytes);
        await Share.shareXFiles([XFile(file.path)], text: 'My Habit Report (Excel)');
      }
    } catch (e) {
      if (context.mounted) {
        if (kIsWeb) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Export not supported on Web.')));
          return;
        }
        // Fallback to CSV if Excel package API is strictly different in this version
        final output = await getTemporaryDirectory();
        final file = File('${output.path}/habit_report.csv');
        
        String csv = "Date,Habits Completed\n";
        final now = DateTime.now();
        for (int i = 0; i < 7; i++) {
          final d = now.subtract(Duration(days: 6 - i));
          csv += "${DateFormat('yyyy-MM-dd').format(d)},${chartData[i]}\n";
        }
        await file.writeAsString(csv);
        await Share.shareXFiles([XFile(file.path)], text: 'My Habit Report (CSV fallback)');
      }
    } finally {
      if (context.mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final habitProvider = Provider.of<HabitProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = Theme.of(context);
    final habits = habitProvider.habits;

    final chartData = _getLast7DaysData(habits);
    final double maxY = chartData.isEmpty ? 5.0 : (chartData.reduce((a, b) => a > b ? a : b) + 2).toDouble();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Profile & Analytics', 
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: theme.colorScheme.onSurface),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Profile Section
              CircleAvatar(
                radius: 54,
                backgroundColor: theme.primaryColor.withOpacity(0.1),
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: theme.primaryColor.withOpacity(0.2),
                  child: Text(
                    user?.displayName?.isNotEmpty == true ? user!.displayName![0].toUpperCase() : 'U',
                    style: GoogleFonts.outfit(
                      fontSize: 44,
                      fontWeight: FontWeight.bold,
                      color: theme.primaryColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                user?.displayName ?? 'User Name',
                style: GoogleFonts.outfit(fontSize: 26, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
              ),
              const SizedBox(height: 4),
              Text(
                user?.email ?? 'user@example.com',
                style: GoogleFonts.outfit(fontSize: 14, color: theme.colorScheme.onSurface.withOpacity(0.5)),
              ),
              const SizedBox(height: 35),

              // Theme Toggle
              Container(
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: theme.dividerColor, width: 0.5),
                ),
                child: SwitchListTile(
                  title: Text(
                    'Dark Mode',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface),
                  ),
                  subtitle: Text(
                    themeProvider.isDarkMode ? "On" : "Off",
                    style: GoogleFonts.outfit(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.4)),
                  ),
                  secondary: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      themeProvider.isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                      color: theme.primaryColor,
                      size: 20,
                    ),
                  ),
                  value: themeProvider.isDarkMode,
                  onChanged: (value) => themeProvider.toggleTheme(),
                  activeColor: theme.primaryColor,
                ),
              ),

              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: theme.dividerColor, width: 0.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Last 7 Days',
                          style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                        ),
                        Icon(Icons.bar_chart_rounded, color: theme.primaryColor, size: 24),
                      ],
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      height: 200,
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: maxY,
                          barTouchData: BarTouchData(
                            enabled: true,
                            touchTooltipData: BarTouchTooltipData(
                              getTooltipColor: (_) => theme.primaryColor,
                              tooltipRoundedRadius: 8,
                              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                return BarTooltipItem(
                                  rod.toY.toInt().toString(),
                                  GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
                                );
                              },
                            ),
                          ),
                          titlesData: FlTitlesData(
                            show: true,
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  final d = DateTime.now().subtract(Duration(days: 6 - value.toInt()));
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 10.0),
                                    child: Text(
                                      DateFormat('E').format(d)[0],
                                      style: GoogleFonts.outfit(
                                        color: theme.colorScheme.onSurface.withOpacity(0.4), 
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold),
                                    ),
                                  );
                                },
                              ),
                            ),
                            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          ),
                          gridData: const FlGridData(show: false),
                          borderData: FlBorderData(show: false),
                          barGroups: List.generate(7, (index) {
                            return BarChartGroupData(
                              x: index,
                              barRods: [
                                BarChartRodData(
                                  toY: chartData[index].toDouble(),
                                  color: theme.primaryColor,
                                  width: 14,
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                                  backDrawRodData: BackgroundBarChartRodData(
                                    show: true,
                                    toY: maxY,
                                    color: theme.colorScheme.onSurface.withOpacity(0.05),
                                  ),
                                ),
                              ],
                            );
                          }),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Pie Chart Section
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: theme.dividerColor, width: 0.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Daily Distribution',
                          style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                        ),
                        Icon(Icons.pie_chart_rounded, color: const Color(0xFF1D9E75), size: 24),
                      ],
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      height: 200,
                      child: Row(
                        children: [
                          Expanded(
                            child: PieChart(
                              PieChartData(
                                sectionsSpace: 4,
                                centerSpaceRadius: 40,
                                sections: [
                                  PieChartSectionData(
                                    value: _getTodayStats(habits)["Done"]!,
                                    title: '${(_getTodayStats(habits)["Done"]! / (habits.isEmpty ? 1 : habits.length) * 100).toInt()}%',
                                    color: const Color(0xFF1D9E75),
                                    radius: 50,
                                    titleStyle: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                  PieChartSectionData(
                                    value: _getTodayStats(habits)["Pending"]!,
                                    title: '${(_getTodayStats(habits)["Pending"]! / (habits.isEmpty ? 1 : habits.length) * 100).toInt()}%',
                                    color: theme.primaryColor.withOpacity(0.2),
                                    radius: 40,
                                    titleStyle: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface.withOpacity(0.5)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLegendItem(const Color(0xFF1D9E75), "Done", theme),
                              const SizedBox(height: 8),
                              _buildLegendItem(theme.primaryColor.withOpacity(0.2), "Pending", theme),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Monthly Report Section
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: theme.dividerColor.withOpacity(0.1), width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Monthly Progress',
                          style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                        ),
                        Text(
                          DateFormat('MMMM').format(DateTime.now()),
                          style: GoogleFonts.outfit(color: theme.primaryColor, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 25),
                    _buildMonthlyHeatmap(habits, theme),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text("Less", style: GoogleFonts.outfit(fontSize: 10, color: theme.colorScheme.onSurface.withOpacity(0.3))),
                        const SizedBox(width: 4),
                        ...List.generate(5, (index) => Container(
                          width: 10,
                          height: 10,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            color: theme.primaryColor.withOpacity(0.1 + (index * 0.225)),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        )),
                        const SizedBox(width: 4),
                        Text("More", style: GoogleFonts.outfit(fontSize: 10, color: theme.colorScheme.onSurface.withOpacity(0.3))),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Export Actions
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isExporting ? null : () => _exportPdf(habits, chartData),
                      icon: const Icon(Icons.picture_as_pdf, color: Colors.white, size: 20),
                      label: Text('PDF', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isExporting ? null : () => _exportExcel(habits, chartData),
                      icon: const Icon(Icons.table_chart_rounded, color: Colors.white, size: 20),
                      label: Text('EXCEL', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 35),

              // Logout Button
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: theme.cardColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                        title: Text('Log Out', style: GoogleFonts.outfit(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold)),
                        content: Text('Are you sure da? You\'ll be signed out.', 
                          style: GoogleFonts.outfit(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: Text('Cancel', style: GoogleFonts.outfit(color: theme.colorScheme.onSurface.withOpacity(0.4))),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent.withOpacity(0.1),
                              foregroundColor: Colors.redAccent,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: Text('Log Out', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true && mounted) {
                      await authProvider.logout();
                      if (mounted) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                          (route) => false,
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                  label: Text('LOG OUT', style: GoogleFonts.outfit(color: Colors.redAccent, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMonthlyHeatmap(List<Habit> habits, ThemeData theme) {
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;
    final weekOffset = (firstDayOfMonth.weekday % 7); // Sunday = 0? (In Dart Mon=1, Sun=7)
    // Actually DateTime.weekday: 1 (Mon) to 7 (Sun). 
    // If we want Sun as start, then Sun(7)%7 = 0.
    final startOffset = firstDayOfMonth.weekday == 7 ? 0 : firstDayOfMonth.weekday;

    return Column(
      children: [
        // Weekday labels
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: ['S', 'M', 'T', 'W', 'T', 'F', 'S'].map((day) => Text(
            day, 
            style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface.withOpacity(0.3)),
          )).toList(),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            crossAxisSpacing: 6,
            mainAxisSpacing: 6,
            childAspectRatio: 1,
          ),
          itemCount: daysInMonth + startOffset,
          itemBuilder: (context, index) {
            if (index < startOffset) return const SizedBox();
            
            final day = index - startOffset + 1;
            final date = DateTime(now.year, now.month, day);
            
            // Count completed habits for this day
            int totalHabits = habits.length;
            int completedCount = habits.where((h) => 
              h.completionDates.any((d) => 
                d.year == date.year && d.month == date.month && d.day == date.day
              )
            ).length;
            
            double intensity = totalHabits > 0 ? (completedCount / totalHabits) : 0;
            bool isToday = day == now.day;
            bool isPast = date.isBefore(DateTime(now.year, now.month, now.day));
            bool isFuture = date.isAfter(DateTime(now.year, now.month, now.day));

            Color cellColor;
            if (completedCount > 0) {
              cellColor = theme.primaryColor.withOpacity(0.2 + (intensity * 0.8));
            } else {
              cellColor = theme.colorScheme.onSurface.withOpacity(0.05);
            }

            return Container(
              decoration: BoxDecoration(
                color: cellColor,
                borderRadius: BorderRadius.circular(6),
                border: isToday ? Border.all(color: theme.primaryColor, width: 1.5) : null,
              ),
              child: Center(
                child: Text(
                  day.toString(),
                  style: GoogleFonts.outfit(
                    fontSize: 9,
                    fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                    color: intensity > 0.6 
                      ? Colors.white 
                      : theme.colorScheme.onSurface.withOpacity(isFuture ? 0.2 : 0.6),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label, ThemeData theme) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.outfit(fontSize: 14, color: theme.colorScheme.onSurface.withOpacity(0.6)),
        ),
      ],
    );
  }
}
