import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/zara_robot.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../providers/habit_provider.dart';
import 'package:provider/provider.dart';

class ZaraChatScreen extends StatefulWidget {
  const ZaraChatScreen({super.key});

  @override
  State<ZaraChatScreen> createState() => _ZaraChatScreenState();
}

class _ZaraChatScreenState extends State<ZaraChatScreen>
    with TickerProviderStateMixin {
  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _zaraTyping = false;
  bool _isLoading = true;
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  // Quick reply suggestions
  final List<String> _suggestions = [
    "How am I doing today? 📊",
    "Motivate me da! 💪",
    "My streak status 🔥",
    "Add a new habit ➕",
  ];

  @override
  void initState() {
    super.initState();
    _loadChatHistory();
  }

  Future<void> _loadChatHistory() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('chats')
          .orderBy('timestamp', descending: false)
          .get();

      if (snapshot.docs.isEmpty) {
        // Initial greeting if history is empty
        _addZaraMessage(
            "Vanakkam da! 👋 I'm Zara!\n\nI'm here to help you build better habits and stay consistent. Ko sollu — what's on your mind today? 😊",
            saveToDb: true);
      } else {
        setState(() {
          _messages.addAll(snapshot.docs.map((doc) => _ChatMessage(
                text: doc['text'],
                isUser: doc['isUser'],
                timestamp: (doc['timestamp'] as Timestamp).toDate(),
              )));
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint("Error loading chat: $e");
      setState(() => _isLoading = false);
    }
  }

  void _addZaraMessage(String text, {bool saveToDb = false}) async {
    setState(() => _zaraTyping = true);
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;

    final msg = _ChatMessage(text: text, isUser: false, timestamp: DateTime.now());
    
    setState(() {
      _zaraTyping = false;
      _messages.add(msg);
      _isLoading = false;
    });
    _scrollToBottom();

    if (saveToDb) {
      _saveMessageToDb(msg);
    }
  }

  Future<void> _saveMessageToDb(_ChatMessage msg) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('chats')
        .add({
      'text': msg.text,
      'isUser': msg.isUser,
      'timestamp': Timestamp.fromDate(msg.timestamp),
    });
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;
    _inputCtrl.clear();

    final msg = _ChatMessage(text: text, isUser: true, timestamp: DateTime.now());
    setState(() {
      _messages.add(msg);
      _zaraTyping = true;
    });
    _scrollToBottom();
    _saveMessageToDb(msg);

    // Call dynamic AI
    _getDynamicResponse(text);
  }

  Future<void> _getDynamicResponse(String userText) async {
    final apiKey = dotenv.env['GROQ_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      _addZaraMessage("AI Key not found da! Please check .env.", saveToDb: true);
      return;
    }

    // Get habit context
    final habitProvider = Provider.of<HabitProvider>(context, listen: false);
    final habitContext = habitProvider.habits.map((h) => "- ${h.name} (${h.category}): Streak ${h.streak}, Progress ${h.completionRate.toStringAsFixed(2)}%").join("\n");

    try {
      final response = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "model": "llama-3.3-70b-versatile",
          "messages": [
            {
              "role": "system",
              "content": "You are 'Zara', a futuristic and friendly AI habit companion for an app called 'Trackify'. You speak in a mix of English and Tamil slang (like using 'da', 'ko', 'vanakkam'). Be motivating, insightful, and concise. Don't be too formal. Here is the user's current habit progress:\n$habitContext"
            },
            ..._messages.reversed.take(6).toList().reversed.map((m) => {
              "role": m.isUser ? "user" : "assistant",
              "content": m.text
            }),
            {"role": "user", "content": userText}
          ],
          "temperature": 0.7,
          "max_completion_tokens": 1024,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final aiMessage = data['choices'][0]['message']['content'];
        _addZaraMessage(aiMessage, saveToDb: true);
      } else {
        _addZaraMessage("Sorry da, I'm having a technical glitch! Try again later. 🤖", saveToDb: true);
      }
    } catch (e) {
      debugPrint("GROQ Error: $e");
      _addZaraMessage("Network error da! Check your internet. 📶", saveToDb: true);
    } finally {
      setState(() => _zaraTyping = false);
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0F),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            // Mini robot icon in app bar
            SizedBox(
              width: 36,
              height: 36,
              child: CustomPaint(painter: _MiniRobotPainter()),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Zara',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF1D9E75),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Online',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: Color(0xFF1D9E75),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF1D9E75)))
              : ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  itemCount: _messages.length + (_zaraTyping ? 1 : 0),
                  itemBuilder: (context, i) {
                    if (_zaraTyping && i == _messages.length) {
                      return _buildTypingIndicator();
                    }
                    return _buildMessageBubble(_messages[i]);
                  },
                ),
          ),

          // Quick suggestions
          if (_messages.length <= 1)
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _suggestions.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) => GestureDetector(
                  onTap: () => _sendMessage(_suggestions[i]),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF12121A),
                      border: Border.all(color: const Color(0xFF1D9E75).withOpacity(0.4)),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _suggestions[i],
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: Color(0xFF9FE1CB),
                      ),
                    ),
                  ),
                ),
              ),
            ),

          const SizedBox(height: 8),

          // Input field
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF12121A),
              border: Border.all(color: const Color(0xFF1E2830)),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _inputCtrl,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 14,
                      color: Color(0xFFE2E8F0),
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Talk to Zara...',
                      hintStyle: TextStyle(
                        color: Color(0xFF2D3748),
                        fontFamily: 'monospace',
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                    ),
                    onSubmitted: _sendMessage,
                  ),
                ),
                GestureDetector(
                  onTap: () => _sendMessage(_inputCtrl.text),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: Color(0xFF1D9E75),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(_ChatMessage msg) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            msg.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!msg.isUser) ...[
            Container(
              width: 28,
              height: 28,
              margin: const EdgeInsets.only(right: 8),
              child: CustomPaint(painter: _MiniRobotPainter()),
            ),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: msg.isUser
                    ? const Color(0xFF1D9E75)
                    : const Color(0xFF12121A),
                border: msg.isUser
                    ? null
                    : Border.all(
                        color: const Color(0xFF1D9E75).withOpacity(0.3)),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(msg.isUser ? 16 : 4),
                  bottomRight: Radius.circular(msg.isUser ? 4 : 16),
                ),
              ),
              child: Text(
                msg.text,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  color: msg.isUser
                      ? Colors.white
                      : const Color(0xFFE2E8F0),
                  height: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            margin: const EdgeInsets.only(right: 8),
            child: CustomPaint(painter: _MiniRobotPainter()),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF12121A),
              border: Border.all(
                  color: const Color(0xFF1D9E75).withOpacity(0.3)),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                3,
                (i) => _TypingDot(delay: i * 200),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypingDot extends StatefulWidget {
  final int delay;
  const _TypingDot({required this.delay});

  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _anim = Tween<double>(begin: 0, end: -6).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Transform.translate(
        offset: Offset(0, _anim.value),
        child: Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: const BoxDecoration(
            color: Color(0xFF1D9E75),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  _ChatMessage({required this.text, required this.isUser, required this.timestamp});
}

class _MiniRobotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final teal = Paint()..color = const Color(0xFF1D9E75);
    final body = Paint()..color = const Color(0xFF12121A);
    final border = Paint()
      ..color = const Color(0xFF1D9E75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final scaleX = size.width / 200;
    final scaleY = size.height / 260;

    canvas.save();
    canvas.scale(scaleX, scaleY);

    // Head
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(62, 36, 76, 68), const Radius.circular(18)),
      body,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(62, 36, 76, 68), const Radius.circular(18)),
      border,
    );

    // Eyes
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(76, 54, 18, 14), const Radius.circular(7)),
      teal,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(106, 54, 18, 14), const Radius.circular(7)),
      teal,
    );

    // Torso
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(55, 112, 90, 80), const Radius.circular(16)),
      body,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(55, 112, 90, 80), const Radius.circular(16)),
      border,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(_) => false;
}

