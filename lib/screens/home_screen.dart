import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../providers/habit_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../models/habit_model.dart';
import 'add_habit_screen.dart';
import 'analytics_screen.dart';
import 'zara_intro_screen.dart';
import 'login_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  // Selected date for the weekly calendar — default = today
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    Future.delayed(Duration.zero, () {
      Provider.of<HabitProvider>(context, listen: false).fetchHabits();
    });
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  // Check if a habit was completed on a specific date
  bool _isCompletedOn(Habit habit, DateTime date) {
    return habit.completionDates.any((d) => _isSameDay(d, date));
  }

  @override
  Widget build(BuildContext context) {
    final habitProvider = Provider.of<HabitProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final habits = habitProvider.habits;
    final user = authProvider.user;

    final isViewingToday = _isToday(_selectedDate);
    final now2 = DateTime.now();
    final isFutureSelected = _selectedDate.isAfter(
        DateTime(now2.year, now2.month, now2.day));

    // For past/today dates, count completions; for future dates count 0
    final completedOnSelected = isFutureSelected
        ? 0
        : habits.where((h) => _isCompletedOn(h, _selectedDate)).length;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(user?.displayName ?? 'Sri', authProvider),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => habitProvider.fetchHabits(),
                child: ListView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  children: [
                    _buildWeeklyCalendar(),
                    const SizedBox(height: 25),
                    _buildDayStats(habits, completedOnSelected, isViewingToday, isFutureSelected),
                    const SizedBox(height: 25),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isViewingToday
                                  ? "Today's Habits"
                                  : "${DateFormat('EEE, MMM d').format(_selectedDate)}'s Habits",
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            if (!isViewingToday && !isFutureSelected)
                              Text(
                                'Viewing past data',
                                style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    color: const Color(0xFF1D9E75)),
                              ),
                            if (isFutureSelected)
                              Text(
                                '📅 Planned day',
                                style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    color: const Color(0xFF7C3AED)),
                              ),
                          ],
                        ),
                        Text(
                          isFutureSelected
                              ? "${habits.length} Habits"
                              : "$completedOnSelected/${habits.length} Done",
                            style: GoogleFonts.outfit(
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    if (habits.isEmpty)
                      _buildEmptyState()
                    else
                      ...habits.map(
                          (habit) => _buildHabitCard(habit, habitProvider)),
                    const SizedBox(height: 25),
                    _buildWeeklyHighlights(habits),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddHabitScreen()),
        ),
        backgroundColor: const Color(0xFF1D9E75),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHeader(String name, AuthProvider authProvider) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 12, 20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
            child: CircleAvatar(
              radius: 25,
              backgroundColor: Theme.of(context).cardColor,
              child: Text(
                name.isNotEmpty ? name[0] : 'U',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Good morning, $name 👋",
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Text(
                DateFormat('EEEE, MMM d').format(DateTime.now()),
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.38),
                ),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            icon: Icon(
              themeProvider.isDarkMode ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
              color: Theme.of(context).primaryColor,
            ),
            onPressed: () => themeProvider.toggleTheme(),
          ),
          // Direct logout button — no settings icon, no popup
          GestureDetector(
            onTap: () async {
              // Show confirmation
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: Theme.of(context).cardColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  title: Text('Log Out',
                      style: GoogleFonts.outfit(
                          color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold)),
                  content: Text('Are you sure you want to log out?',
                      style: GoogleFonts.outfit(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text('Cancel',
                          style: GoogleFonts.outfit(color: Colors.white38)),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('Log Out',
                          style: GoogleFonts.outfit(color: Colors.white)),
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
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.logout,
                  color: Colors.redAccent, size: 22),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyCalendar() {
    final now = DateTime.now();
    // Show 30 days (15 past, today, 14 future)
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(30, (index) {
          final date = DateTime(
            now.year,
            now.month,
            now.day - 15 + index,
          );
          final isToday = _isToday(date);
          final isSelected = _isSameDay(date, _selectedDate);
          final isPast = date.isBefore(DateTime(now.year, now.month, now.day));
          final isFuture = date.isAfter(DateTime(now.year, now.month, now.day));

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: GestureDetector(
              onTap: () {
                // Allow ALL days to be tapped (past, today, future)
                setState(() {
                  _selectedDate = date;
                });
              },
              child: Column(
                children: [
                  Text(
                    DateFormat('EEE').format(date).toUpperCase(),
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      color: isSelected
                          ? const Color(0xFF1D9E75)
                          : isToday
                              ? const Color(0xFF1D9E75)
                              : Theme.of(context).colorScheme.onSurface.withOpacity(0.24),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (isFuture
                              ? const Color(0xFF7C3AED)
                              : const Color(0xFF1D9E75))
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: isSelected
                          ? null
                          : Border.all(
                              color: isToday
                                  ? const Color(0xFF1D9E75).withOpacity(0.5)
                                  : isFuture
                                      ? const Color(0xFF7C3AED).withOpacity(0.2)
                                      : Theme.of(context).dividerColor),
                    ),
                    child: Text(
                      date.day.toString(),
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: isSelected
                            ? Colors.white
                            : isPast
                                ? Theme.of(context).colorScheme.onSurface.withOpacity(0.38)
                                : isFuture
                                    ? const Color(0xFF7C3AED).withOpacity(0.7)
                                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildDayStats(
      List<Habit> habits, int completedOnSelected, bool isViewingToday,
      [bool isFuture = false]) {
    if (habits.isEmpty) return const SizedBox.shrink();
    final total = habits.length;
    final percent = total == 0 ? 0.0 : completedOnSelected / total;
    final accentColor = isFuture
        ? const Color(0xFF7C3AED)
        : const Color(0xFF1D9E75);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: isFuture
            ? Border.all(color: const Color(0xFF7C3AED).withOpacity(0.3))
            : null,
      ),
      child: Row(
        children: [
          isFuture
              ? Container(
                  height: 60, width: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C3AED).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.event_outlined,
                      color: Color(0xFF7C3AED), size: 28),
                )
              : _buildProgressCircle(
                  percent,
                  (percent * 100).toInt().toString() + "%"),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isFuture
                      ? 'Planned Day'
                      : isViewingToday
                          ? "Today's Progress"
                          : "Day's Progress",
                  style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isFuture ? const Color(0xFF7C3AED) : Theme.of(context).colorScheme.onSurface),
                ),
                Text(
                  isFuture
                      ? 'All $total habits planned for this day'
                      : 'Completed $completedOnSelected of $total habits',
                  style:
                      GoogleFonts.outfit(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.38)),
                ),
                Text(
                  DateFormat('d MMM yyyy').format(_selectedDate),
                  style: GoogleFonts.outfit(
                      fontSize: 12, color: accentColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCircle(double percent, String label) {
    return SizedBox(
      height: 60,
      width: 60,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: percent,
            strokeWidth: 6,
            backgroundColor: Theme.of(context).dividerColor,
            valueColor:
                const AlwaysStoppedAnimation<Color>(Color(0xFF1D9E75)),
          ),
          Text(label,
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
        ],
      ),
    );
  }

  Widget _buildHabitCard(Habit habit, HabitProvider provider) {
    final color = Color(int.parse(habit.color, radix: 16));
    final now = DateTime.now();
    final isViewingToday = _isToday(_selectedDate);
    final isFutureDate =
        _selectedDate.isAfter(DateTime(now.year, now.month, now.day));

    // For today → use isCompletedToday (live toggle)
    // For past → check completionDates for that specific day
    // For future → always false
    final isCompleted = isFutureDate
        ? false
        : isViewingToday
            ? habit.isCompletedToday
            : _isCompletedOn(habit, _selectedDate);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: isFutureDate
              ? Border.all(color: const Color(0xFF7C3AED).withOpacity(0.2))
              : isCompleted
                  ? Border.all(color: color.withOpacity(0.3))
                  : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(habit.emoji,
                  style: const TextStyle(fontSize: 24)),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    habit.name,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                      decoration: isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.local_fire_department,
                          color: Colors.orange, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '${habit.streak} days',
                        style: GoogleFonts.outfit(
                            fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.38)),
                      ),
                      if (habit.endDate != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          '• ends ${DateFormat('d/M').format(habit.endDate!)}',
                          style: GoogleFonts.outfit(
                              fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.24)),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // CRUD popup menu
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.38), size: 20),
              color: Theme.of(context).cardColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              padding: EdgeInsets.zero,
              onSelected: (value) {
                if (value == 'edit') {
                  _showEditHabitDialog(context, habit, provider);
                } else if (value == 'delete') {
                  _confirmDelete(context, habit, provider);
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      const Icon(Icons.edit_outlined,
                          color: Color(0xFF1D9E75), size: 20),
                      const SizedBox(width: 10),
                      Text('Edit',
                          style: GoogleFonts.outfit(color: Theme.of(context).colorScheme.onSurface)),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      const Icon(Icons.delete_outline,
                          color: Colors.redAccent, size: 20),
                      const SizedBox(width: 10),
                      Text('Delete',
                          style:
                              GoogleFonts.outfit(color: Colors.redAccent)),
                    ],
                  ),
                ),
              ],
            ),
            // Complete toggle — now works for today and past dates. Future remains read-only.
            GestureDetector(
              onTap: isFutureDate
                  ? null
                  : () => provider.toggleHabitCompletion(habit, _selectedDate),
              child: Container(
                height: 32,
                width: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isFutureDate
                      ? const Color(0xFF7C3AED).withOpacity(0.1)
                      : isCompleted
                          ? color
                          : Colors.transparent,
                  border: Border.all(
                    color: isFutureDate
                        ? const Color(0xFF7C3AED).withOpacity(0.3)
                        : isCompleted
                            ? Colors.transparent
                            : Theme.of(context).dividerColor,
                    width: 2,
                  ),
                ),
                child: isFutureDate
                    ? const Icon(Icons.access_time,
                        color: Color(0xFF7C3AED), size: 16)
                    : isCompleted
                        ? const Icon(Icons.check, color: Colors.white, size: 18)
                        : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditHabitDialog(
      BuildContext context, Habit habit, HabitProvider provider) {
    final nameController = TextEditingController(text: habit.name);
    String selectedEmoji = habit.emoji;
    String selectedColor = habit.color;
    DateTime? startDate = habit.startDate;
    DateTime? endDate = habit.endDate;

    final emojis = [
      '🔥','💧','🏃','📚','🧘','🍎','🥦','🛌','🎸','👟','🎨','💻'
    ];
    final colors = [
      "FF1D9E75","FF7C3AED","FF2563EB","FFEF4444",
      "FFF97316","FFFACC15","FF00D2FD","FFEC4899"
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            top: 24,
            left: 24,
            right: 24,
          ),
          decoration: const BoxDecoration(
            color: Color(0xFF131318),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text('Edit Habit',
                    style: GoogleFonts.outfit(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                TextField(
                  controller: nameController,
                  style: GoogleFonts.outfit(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Habit Name',
                    labelStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: const Color(0xFF1F1F25),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Icon',
                    style: GoogleFonts.outfit(
                        color: Colors.white38, fontSize: 12)),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: emojis
                        .map((emoji) => GestureDetector(
                              onTap: () => setModalState(
                                  () => selectedEmoji = emoji),
                              child: Container(
                                margin:
                                    const EdgeInsets.only(right: 10),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: selectedEmoji == emoji
                                      ? Color(int.parse(selectedColor,
                                              radix: 16))
                                          .withOpacity(0.2)
                                      : const Color(0xFF1F1F25),
                                  borderRadius:
                                      BorderRadius.circular(12),
                                  border: Border.all(
                                    color: selectedEmoji == emoji
                                        ? Color(int.parse(selectedColor,
                                            radix: 16))
                                        : Colors.transparent,
                                  ),
                                ),
                                child: Text(emoji,
                                    style: const TextStyle(
                                        fontSize: 22)),
                              ),
                            ))
                        .toList(),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Color',
                    style: GoogleFonts.outfit(
                        color: Colors.white38, fontSize: 12)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: colors.map((colorHex) {
                    final c =
                        Color(int.parse(colorHex, radix: 16));
                    return GestureDetector(
                      onTap: () => setModalState(
                          () => selectedColor = colorHex),
                      child: Container(
                        height: 30,
                        width: 30,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: c,
                          border: Border.all(
                            color: selectedColor == colorHex
                                ? Colors.white
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Text('Date Range',
                    style: GoogleFonts.outfit(
                        color: Colors.white38, fontSize: 12)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate:
                                startDate ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null)
                            setModalState(() => startDate = picked);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1F1F25),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            startDate != null
                                ? DateFormat('d/M/yy')
                                    .format(startDate!)
                                : 'Start Date',
                            style: GoogleFonts.outfit(
                                color: startDate != null
                                    ? Colors.white
                                    : Colors.white38,
                                fontSize: 13),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: endDate ??
                                DateTime.now()
                                    .add(const Duration(days: 7)),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null)
                            setModalState(() => endDate = picked);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1F1F25),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            endDate != null
                                ? DateFormat('d/M/yy')
                                    .format(endDate!)
                                : 'End Date',
                            style: GoogleFonts.outfit(
                                color: endDate != null
                                    ? Colors.white
                                    : Colors.white38,
                                fontSize: 13),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    provider.updateHabit(
                      habit,
                      name: nameController.text.isNotEmpty
                          ? nameController.text
                          : null,
                      emoji: selectedEmoji,
                      color: selectedColor,
                      startDate: startDate,
                      endDate: endDate,
                    );
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1D9E75),
                    minimumSize: const Size(double.infinity, 54),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text('Save Changes',
                      style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, Habit habit, HabitProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1F1F25),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Habit',
            style: GoogleFonts.outfit(
                color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to delete "${habit.name}"?',
          style: GoogleFonts.outfit(color: Colors.white60),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: GoogleFonts.outfit(color: Colors.white38)),
          ),
          ElevatedButton(
            onPressed: () {
              provider.deleteHabit(habit.id);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Delete',
                style: GoogleFonts.outfit(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyHighlights(List<Habit> habits) {
    if (habits.isEmpty) return const SizedBox.shrink();

    double avgCompletion = 0.0;
    int maxStreak = 0;

    if (habits.isNotEmpty) {
      avgCompletion =
          habits.fold(0.0, (sum, h) => sum + h.completionRate) /
              habits.length;
      maxStreak =
          habits.fold(0, (max, h) => h.streak > max ? h.streak : max);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Weekly Highlights",
          style:
              GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            _buildHighlightCard(
                "${(avgCompletion * 100).toInt()}%",
                "Completion Rate",
                const Color(0xFF7C3AED),
                Icons.bolt),
            const SizedBox(width: 12),
            _buildHighlightCard(
                "$maxStreak",
                "Longest Streak",
                const Color(0xFFF97316),
                Icons.whatshot),
          ],
        ),
      ],
    );
  }

  Widget _buildHighlightCard(
      String value, String label, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 12),
            Text(value,
                style: GoogleFonts.outfit(
                    fontSize: 24, fontWeight: FontWeight.bold)),
            Text(label,
                style:
                    GoogleFonts.outfit(fontSize: 12, color: Colors.white38)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 40),
          Icon(Icons.auto_awesome,
              color: const Color(0xFF1D9E75).withOpacity(0.2), size: 80),
          const SizedBox(height: 20),
          Text(
            "No habits yet ! 🚀",
            style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white38),
          ),
          const SizedBox(height: 8),
          Text(
            "Create your first habit to start tracking.",
            style: GoogleFonts.outfit(fontSize: 14, color: Colors.white24),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomAppBar(
      color: const Color(0xFF131318),
      padding: EdgeInsets.zero,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            icon: Icon(Icons.home_filled,
                color: _currentIndex == 0
                    ? const Color(0xFF1D9E75)
                    : Colors.white38),
            onPressed: () => setState(() => _currentIndex = 0),
          ),
          IconButton(
            icon: Icon(Icons.bar_chart_rounded,
                color: _currentIndex == 1
                    ? const Color(0xFF1D9E75)
                    : Colors.white38),
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const AnalyticsScreen()));
            },
          ),
          const SizedBox(width: 48),
          IconButton(
            icon: Icon(Icons.chat_bubble_outline,
                color: _currentIndex == 2
                    ? const Color(0xFF1D9E75)
                    : Colors.white38),
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ZaraIntroScreen()));
            },
          ),
          IconButton(
            icon: Icon(Icons.person_outline,
                color: _currentIndex == 3
                    ? const Color(0xFF1D9E75)
                    : Colors.white38),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}
