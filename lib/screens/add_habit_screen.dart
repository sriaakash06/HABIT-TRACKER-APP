import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../providers/habit_provider.dart';

// ─────────────────────────────────────────────
// Habit template model
// ─────────────────────────────────────────────
class HabitTemplate {
  final String emoji;
  final String name;
  final String color;
  const HabitTemplate(this.emoji, this.name, this.color);
}

class HabitCategory {
  final String title;
  final String icon;
  final List<HabitTemplate> templates;
  const HabitCategory(this.title, this.icon, this.templates);
}

final List<HabitCategory> habitCategories = [
  HabitCategory('🥦 Health & Fitness', '🥦', [
    HabitTemplate('🏃', 'Morning Walk / Run', 'FF1D9E75'),
    HabitTemplate('💧', 'Drink 8 Glasses of Water', 'FF2563EB'),
    HabitTemplate('🥑', 'Eat Healthy Meals', 'FF1D9E75'),
    HabitTemplate('🧘', 'Stretch or Yoga', 'FF7C3AED'),
    HabitTemplate('🏋️', 'Exercise / Workout', 'FFEF4444'),
    HabitTemplate('🍎', 'Eat Fruits & Vegetables', 'FF1D9E75'),
    HabitTemplate('🚴', 'Cycling', 'FFF97316'),
    HabitTemplate('🦷', 'Brush Teeth Twice', 'FF00D2FD'),
  ]),
  HabitCategory('🧠 Mind & Learning', '🧠', [
    HabitTemplate('📚', 'Read for 20 Minutes', 'FF7C3AED'),
    HabitTemplate('🧘', 'Meditate / Deep Breathe', 'FF7C3AED'),
    HabitTemplate('📝', 'Write in Journal', 'FFFACC15'),
    HabitTemplate('🎯', 'Practice Focus / No Distractions', 'FFEF4444'),
    HabitTemplate('🗣️', 'Learn a New Word', 'FF2563EB'),
    HabitTemplate('🎵', 'Practice Music', 'FFEC4899'),
    HabitTemplate('🧩', 'Solve a Puzzle / Brain Game', 'FFF97316'),
    HabitTemplate('📖', 'Study for 30 Minutes', 'FF7C3AED'),
  ]),
  HabitCategory('😴 Sleep & Rest', '😴', [
    HabitTemplate('🛌', 'Sleep by 10 PM', 'FF7C3AED'),
    HabitTemplate('⏰', 'Wake Up on Time', 'FFFACC15'),
    HabitTemplate('📵', 'No Screen Before Bed', 'FFEF4444'),
    HabitTemplate('🌙', 'Consistent Sleep Schedule', 'FF7C3AED'),
    HabitTemplate('☀️', 'Morning Sunlight', 'FFF97316'),
    HabitTemplate('😴', 'Afternoon Nap (20 min)', 'FF2563EB'),
  ]),
  HabitCategory('💼 Productivity', '💼', [
    HabitTemplate('📋', 'Plan Daily Tasks', 'FF2563EB'),
    HabitTemplate('✅', 'Complete Top 3 Priorities', 'FF1D9E75'),
    HabitTemplate('📧', 'Clear Inbox', 'FFF97316'),
    HabitTemplate('💻', 'Deep Work Session', 'FF2563EB'),
    HabitTemplate('📵', 'No Social Media Before Noon', 'FFEF4444'),
    HabitTemplate('💰', 'Track Daily Expenses', 'FFFACC15'),
    HabitTemplate('🚀', 'Work on Side Project', 'FF7C3AED'),
    HabitTemplate('📞', 'Call / Connect with a Mentor', 'FF1D9E75'),
  ]),
  HabitCategory('❤️ Social & Family', '❤️', [
    HabitTemplate('📞', 'Call a Family Member', 'FFEC4899'),
    HabitTemplate('🙏', 'Express Gratitude', 'FFFACC15'),
    HabitTemplate('🤝', 'Help Someone Today', 'FF1D9E75'),
    HabitTemplate('💌', 'Write a Kind Message', 'FFEC4899'),
    HabitTemplate('🚶', 'Family Walk / Time Together', 'FF1D9E75'),
    HabitTemplate('😊', 'Smile & Be Positive', 'FFFACC15'),
  ]),
  HabitCategory('🧒 Kids Friendly', '🧒', [
    HabitTemplate('📚', 'Read a Story Book', 'FF7C3AED'),
    HabitTemplate('🎨', 'Draw or Paint', 'FFEC4899'),
    HabitTemplate('🧹', 'Tidy Up My Room', 'FF1D9E75'),
    HabitTemplate('🦷', 'Brush Teeth Morning & Night', 'FF00D2FD'),
    HabitTemplate('🥛', 'Drink Milk', 'FF2563EB'),
    HabitTemplate('📝', 'Do Homework', 'FFFACC15'),
    HabitTemplate('🤲', 'Wash Hands Before Eating', 'FF1D9E75'),
    HabitTemplate('🎮', 'Limit Screen Time', 'FFEF4444'),
  ]),
  HabitCategory('👴 Senior Friendly', '👴', [
    HabitTemplate('🚶', 'Evening Walk (15 min)', 'FF1D9E75'),
    HabitTemplate('💊', 'Take Medications on Time', 'FFEF4444'),
    HabitTemplate('💧', 'Drink Enough Water', 'FF2563EB'),
    HabitTemplate('📺', 'Limit TV Time', 'FFF97316'),
    HabitTemplate('📞', 'Call Family / Friends', 'FFEC4899'),
    HabitTemplate('🧘', 'Simple Stretching / Breathing', 'FF7C3AED'),
    HabitTemplate('📖', 'Read Newspaper / Book', 'FF7C3AED'),
    HabitTemplate('😴', 'Sleep & Wake on Schedule', 'FF7C3AED'),
  ]),
];

// ─────────────────────────────────────────────
// AddHabitScreen
// ─────────────────────────────────────────────
class AddHabitScreen extends StatefulWidget {
  const AddHabitScreen({Key? key}) : super(key: key);

  @override
  _AddHabitScreenState createState() => _AddHabitScreenState();
}

class _AddHabitScreenState extends State<AddHabitScreen>
    with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  String _selectedEmoji = '🔥';
  String _selectedColor = "FF1D9E75";
  String _selectedFrequency = 'Daily';
  DateTime? _startDate;
  DateTime? _endDate;
  late TabController _tabController;

  final List<String> _emojis = [
    '🔥', '💧', '🏃', '📚', '🧘', '🍎',
    '🥦', '🛌', '🎸', '👟', '🎨', '💻',
    '🧠', '💪', '🧹', '💊', '🚴', '✍️',
  ];
  final List<String> _colors = [
    "FF1D9E75", "FF7C3AED", "FF2563EB", "FFEF4444",
    "FFF97316", "FFFACC15", "FF00D2FD", "FFEC4899"
  ];
  final List<String> _frequencies = ['Daily', 'Weekly', 'Custom'];

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(length: 2, vsync: this); // 0=Custom, 1=Templates
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _applyTemplate(HabitTemplate template) {
    setState(() {
      _selectedEmoji = template.emoji;
      _nameController.text = template.name;
      _selectedColor = template.color;
    });
    // Switch to custom tab to let user finalize
    _tabController.animateTo(0);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${template.emoji} ${template.name} selected!',
            style: GoogleFonts.outfit()),
        backgroundColor: const Color(0xFF1D9E75),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _saveHabit() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Please enter a habit name!', style: GoogleFonts.outfit()),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.redAccent,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    Provider.of<HabitProvider>(context, listen: false).addHabit(
      _nameController.text,
      _selectedEmoji,
      color: _selectedColor,
      startDate: _startDate,
      endDate: _endDate,
    );
    Navigator.pop(context);
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF1D9E75),
            surface: Color(0xFF1F1F25),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ??
          (_startDate?.add(const Duration(days: 7)) ??
              DateTime.now().add(const Duration(days: 7))),
      firstDate: _startDate ?? DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF1D9E75),
            surface: Color(0xFF1F1F25),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _endDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = Color(int.parse(_selectedColor, radix: 16));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      app_bar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: Text("New Habit",
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: accentColor,
          indicatorWeight: 3,
          labelColor: accentColor,
          unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.38),
          tabs: [
            Tab(child: Text('✏️ Custom', style: GoogleFonts.outfit(fontSize: 14))),
            Tab(
                child: Text('⚡ Quick Templates',
                    style: GoogleFonts.outfit(fontSize: 14))),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCustomTab(accentColor),
          _buildTemplatesTab(),
        ],
      ),
    );
  }

  // ── Custom tab ──────────────────────────────
  Widget _buildCustomTab(Color accentColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          // Preview card
          if (_nameController.text.isNotEmpty)
            _buildPreviewCard(accentColor),

          const Label(text: "CHOOSE ICON"),
          const SizedBox(height: 12),
          _buildIconSelector(),
          const SizedBox(height: 24),

          const Label(text: "HABIT NAME"),
          const SizedBox(height: 12),
          TextField(
            controller: _nameController,
            onChanged: (_) => setState(() {}),
            style: GoogleFonts.outfit(color: Theme.of(context).colorScheme.onSurface, fontSize: 18),
            decoration: InputDecoration(
              hintText: "E.g. Morning Meditation",
              hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.24)),
              filled: true,
              fillColor: Theme.of(context).cardColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
              suffixIcon: _nameController.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear, color: Colors.white38),
                      onPressed: () => setState(
                          () => _nameController.clear()),
                    ),
            ),
          ),
          const SizedBox(height: 24),

          const Label(text: "THEME COLOR"),
          const SizedBox(height: 12),
          _buildColorSelector(),
          const SizedBox(height: 24),

          const Label(text: "FREQUENCY"),
          const SizedBox(height: 12),
          _buildFrequencySelector(),
          const SizedBox(height: 24),

          const Label(text: "DATE RANGE (OPTIONAL)"),
          const SizedBox(height: 12),
          _buildDateRangePicker(accentColor),
          const SizedBox(height: 40),

          ElevatedButton(
            onPressed: _saveHabit,
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              minimumSize: const Size(double.infinity, 60),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              elevation: 8,
              shadowColor: accentColor.withOpacity(0.5),
            ),
            child: Text("Create Habit 🚀",
                style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildPreviewCard(Color accentColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accentColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Text(_selectedEmoji, style: const TextStyle(fontSize: 32)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _nameController.text,
                  style: GoogleFonts.outfit(
                      fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
                ),
                Text(
                  '$_selectedFrequency • ${_startDate != null ? DateFormat('d/M').format(_startDate!) : 'Anytime'}',
                  style:
                      GoogleFonts.outfit(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.38)),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('Preview',
                style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: accentColor,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // ── Templates tab ────────────────────────────
  Widget _buildTemplatesTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: habitCategories.length,
      itemBuilder: (context, catIndex) {
        final category = habitCategories[catIndex];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (catIndex == 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1D9E75).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: const Color(0xFF1D9E75).withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.bolt_rounded,
                          color: Color(0xFF1D9E75), size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Tap any habit to instantly fill the form!',
                          style: GoogleFonts.outfit(
                              fontSize: 13,
                              color: const Color(0xFF1D9E75)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 12),
              child: Text(
                category.title,
                style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface),
              ),
            ),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: category.templates
                  .map((template) => _buildTemplateChip(template))
                  .toList(),
            ),
            const SizedBox(height: 24),
            const Divider(color: Colors.white10, height: 1),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }

  Widget _buildTemplateChip(HabitTemplate template) {
    final color = Color(int.parse(template.color, radix: 16));
    return GestureDetector(
      onTap: () => _applyTemplate(template),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(template.emoji,
                style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text(
              template.name,
              style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  // ── Shared widgets ────────────────────────────
  Widget _buildDateRangePicker(Color accentColor) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: _pickStartDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      vertical: 16, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: _startDate != null
                        ? Border.all(color: accentColor.withOpacity(0.5))
                        : Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.calendar_today_outlined,
                              color: _startDate != null
                                  ? accentColor
                                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.38),
                              size: 16),
                          const SizedBox(width: 8),
                          Text('Start Date',
                              style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.38))),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _startDate != null
                            ? DateFormat('d/M/yyyy').format(_startDate!)
                            : 'Select date',
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: _startDate != null
                              ? Theme.of(context).colorScheme.onSurface
                              : Theme.of(context).colorScheme.onSurface.withOpacity(0.38),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: _pickEndDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      vertical: 16, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: _endDate != null
                        ? Border.all(color: accentColor.withOpacity(0.5))
                        : Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.event_outlined,
                              color:
                                  _endDate != null ? accentColor : Theme.of(context).colorScheme.onSurface.withOpacity(0.38),
                              size: 16),
                          const SizedBox(width: 8),
                          Text('End Date',
                              style: GoogleFonts.outfit(
                                  fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.38))),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _endDate != null
                            ? DateFormat('d/M/yyyy').format(_endDate!)
                            : 'Select date',
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: _endDate != null
                              ? Theme.of(context).colorScheme.onSurface
                              : Theme.of(context).colorScheme.onSurface.withOpacity(0.38),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        // Show date range summary
        if (_startDate != null && _endDate != null) ...[
          const SizedBox(height: 12),
          Container(
            padding:
                const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: accentColor.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.timeline, color: accentColor, size: 16),
                const SizedBox(width: 8),
                Text(
                  '${_endDate!.difference(_startDate!).inDays + 1} days challenge',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: accentColor,
                  ),
                ),
              ],
            ),
          ),
        ],
        // Clear button
        if (_startDate != null || _endDate != null) ...[
          const SizedBox(height: 8),
          TextButton(
            onPressed: () =>
                setState(() { _startDate = null; _endDate = null; }),
            child: Text('Clear dates',
                style: GoogleFonts.outfit(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.38), fontSize: 13)),
          ),
        ],
      ],
    );
  }

  Widget _buildIconSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _emojis
            .map((emoji) => GestureDetector(
                  onTap: () => setState(() => _selectedEmoji = emoji),
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _selectedEmoji == emoji
                          ? Color(int.parse(_selectedColor, radix: 16))
                              .withOpacity(0.1)
                          : Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                          color: _selectedEmoji == emoji
                              ? Color(int.parse(_selectedColor, radix: 16))
                              : Theme.of(context).dividerColor),
                    ),
                    child: Text(emoji,
                        style: const TextStyle(fontSize: 24)),
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildColorSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: _colors.map((colorHex) {
        final color = Color(int.parse(colorHex, radix: 16));
        return GestureDetector(
          onTap: () => setState(() => _selectedColor = colorHex),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: _selectedColor == colorHex ? 36 : 30,
            width: _selectedColor == colorHex ? 36 : 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              border: Border.all(
                  color: _selectedColor == colorHex
                      ? Theme.of(context).colorScheme.onSurface
                      : Colors.transparent,
                  width: 2),
              boxShadow: _selectedColor == colorHex
                  ? [
                      BoxShadow(
                          color: color.withOpacity(0.5),
                          blurRadius: 8,
                          spreadRadius: 2)
                    ]
                  : [],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFrequencySelector() {
    return Row(
      children: _frequencies
          .map((freq) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ElevatedButton(
                    onPressed: () =>
                        setState(() => _selectedFrequency = freq),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedFrequency == freq
                          ? Theme.of(context).cardColor
                          : Colors.transparent,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                        side: BorderSide(
                            color: _selectedFrequency == freq
                                ? const Color(0xFF1D9E75)
                                : Colors.white10),
                      ),
                    ),
                    child: Text(freq,
                        style: TextStyle(
                            color: _selectedFrequency == freq
                                ? Colors.white
                                : Colors.white38)),
                  ),
                ),
              ))
          .toList(),
    );
  }
}

// ─────────────────────────────────────────────
class Label extends StatelessWidget {
  final String text;
  const Label({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.outfit(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.38),
        letterSpacing: 1.2,
      ),
    );
  }
}
