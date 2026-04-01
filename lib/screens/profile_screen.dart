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
import 'package:excel/excel.dart';

import '../providers/auth_provider.dart';
import '../providers/habit_provider.dart';
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
      final d = now.subtract(Duration(days: 6 - i));
      data[i] = habits.where((h) => h.completionDates.any((cd) =>
          cd.year == d.year && cd.month == d.month && cd.day == d.day)).length;
    }
    return data;
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
    final habits = habitProvider.habits;

    final chartData = _getLast7DaysData(habits);
    final double maxY = chartData.isEmpty ? 5.0 : (chartData.reduce((a, b) => a > b ? a : b) + 2).toDouble();

    return Scaffold(
      backgroundColor: const Color(0xFF131318),
      appBar: AppBar(
        title: Text('Profile & Analytics', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Profile Section
              CircleAvatar(
                radius: 50,
                backgroundColor: const Color(0xFF1D9E75).withOpacity(0.2),
                child: Text(
                  user?.displayName?.isNotEmpty == true ? user!.displayName![0].toUpperCase() : 'U',
                  style: GoogleFonts.outfit(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1D9E75),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              Text(
                user?.displayName ?? 'User Name',
                style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 5),
              Text(
                user?.email ?? 'user@example.com',
                style: GoogleFonts.outfit(fontSize: 14, color: Colors.white60),
              ),
              const SizedBox(height: 30),

              // Chart Section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F1F25),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Last 7 Days',
                      style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 200,
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: maxY,
                          barTouchData: BarTouchData(enabled: false),
                          titlesData: FlTitlesData(
                            show: true,
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  final d = DateTime.now().subtract(Duration(days: 6 - value.toInt()));
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      DateFormat('E').format(d)[0],
                                      style: GoogleFonts.outfit(color: Colors.white60, fontSize: 12),
                                    ),
                                  );
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          ),
                          gridData: FlGridData(show: false),
                          borderData: FlBorderData(show: false),
                          barGroups: List.generate(7, (index) {
                            return BarChartGroupData(
                              x: index,
                              barRods: [
                                BarChartRodData(
                                  toY: chartData[index].toDouble(),
                                  color: const Color(0xFF1D9E75),
                                  width: 16,
                                  borderRadius: BorderRadius.circular(4),
                                  backDrawRodData: BackgroundBarChartRodData(
                                    show: true,
                                    toY: maxY,
                                    color: Colors.white10,
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

              // Export Actions
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isExporting ? null : () => _exportPdf(habits, chartData),
                      icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
                      label: Text('Export PDF', style: GoogleFonts.outfit(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isExporting ? null : () => _exportExcel(habits, chartData),
                      icon: const Icon(Icons.table_chart, color: Colors.white),
                      label: Text('Export Excel', style: GoogleFonts.outfit(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // Logout Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: const Color(0xFF1F1F25),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        title: Text('Log Out', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                        content: Text('Are you sure you want to log out?', style: GoogleFonts.outfit(color: Colors.white60)),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: Text('Cancel', style: GoogleFonts.outfit(color: Colors.white38)),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text('Log Out', style: GoogleFonts.outfit(color: Colors.white)),
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
                  icon: const Icon(Icons.logout, color: Colors.redAccent),
                  label: Text('Log Out', style: GoogleFonts.outfit(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.redAccent),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
