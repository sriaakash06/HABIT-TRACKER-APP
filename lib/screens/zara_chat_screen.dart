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
import 'package:google_fonts/google_fonts.dart';

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
  bool _isLoading = false;
  String? _currentSessionId;
  String _sessionTitle = "New Chat";
  bool _isFirstLoad = true;

  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _createNewSession();
  }

  void _createNewSession() {
    setState(() {
      _currentSessionId = DateTime.now().millisecondsSinceEpoch.toString();
      _messages.clear();
      _sessionTitle = "New Chat";
      _isFirstLoad = true;
      _addZaraMessage(
          "Vanakkam da! 👋 I'm Zara, your habit coach. How can I help you today?",
          saveToDb: false);
    });
  }

  Future<void> _loadSession(String sessionId, String title) async {
    final user = _auth.currentUser;
    if (user == null) return;

    setState(() {
      _isLoading = true;
      _currentSessionId = sessionId;
      _sessionTitle = title;
      _messages.clear();
      _isFirstLoad = false;
    });

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('sessions')
          .doc(sessionId)
          .collection('messages')
          .orderBy('timestamp', descending: false)
          .get();

      setState(() {
        _messages.addAll(snapshot.docs.map((doc) => _ChatMessage(
              text: doc['text'],
              isUser: doc['isUser'],
              timestamp: (doc['timestamp'] as Timestamp).toDate(),
            )));
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (e) {
      debugPrint("Error loading session: $e");
      setState(() => _isLoading = false);
    }
  }

  void _addZaraMessage(String text, {bool saveToDb = true}) async {
    if (saveToDb) {
      setState(() => _zaraTyping = true);
      await Future.delayed(const Duration(milliseconds: 1000));
    }
    if (!mounted) return;

    final msg = _ChatMessage(text: text, isUser: false, timestamp: DateTime.now());
    
    setState(() {
      _zaraTyping = false;
      _messages.add(msg);
    });
    _scrollToBottom();

    if (saveToDb && _currentSessionId != null) {
      _saveMessageToDb(msg);
    }
  }

  Future<void> _saveMessageToDb(_ChatMessage msg) async {
    final user = _auth.currentUser;
    if (user == null || _currentSessionId == null) return;

    bool isNew = _sessionTitle == "New Chat";

    // Update/Create session doc
    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('sessions')
        .doc(_currentSessionId)
        .set({
      'title': isNew ? (msg.text.length > 30 ? msg.text.substring(0, 30) + "..." : msg.text) : _sessionTitle,
      'lastTimestamp': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (isNew && msg.isUser) {
      setState(() {
        _sessionTitle = msg.text.length > 30 ? msg.text.substring(0, 30) + "..." : msg.text;
      });
    }

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('sessions')
        .doc(_currentSessionId)
        .collection('messages')
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
    _getDynamicResponse(text);
  }

  Future<void> _getDynamicResponse(String userText) async {
    final apiKey = dotenv.env['GROQ_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      _addZaraMessage("AI Key not found da! Please check .env.", saveToDb: true);
      return;
    }

    final habitProvider = Provider.of<HabitProvider>(context, listen: false);
    final habitContext = habitProvider.habits.map((h) => "- ${h.name}: Streak ${h.streak}").join("\n");

    try {
      final response = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "model": "llama-3-70b-8192",
          "messages": [
            {
              "role": "system",
              "content": "You are 'Zara', a futuristic and friendly AI habit companion. Speak English with Tamil slang like 'da', 'ko', 'machan'. Be motivating. Context:\n$habitContext"
            },
            ..._messages.reversed.take(6).toList().reversed.map((m) => {
              "role": m.isUser ? "user" : "assistant",
              "content": m.text
            }),
          ],
          "temperature": 0.7,
          "max_tokens": 1000,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final aiMessage = data['choices'][0]['message']['content'];
        _addZaraMessage(aiMessage, saveToDb: true);
      } else {
        _addZaraMessage("Brain error da! Status ${response.statusCode}. 🤖", saveToDb: true);
      }
    } catch (e) {
      _addZaraMessage("Connection failure da! 📶", saveToDb: true);
    } finally {
      if (mounted) setState(() => _zaraTyping = false);
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "Zara AI",
          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
        ),
        iconTheme: IconThemeData(color: Theme.of(context).colorScheme.onSurface),
        actions: [
          IconButton(
            icon: Icon(Icons.add_circle_outline, color: Theme.of(context).primaryColor),
            onPressed: _createNewSession,
          )
        ],
      ),
      drawer: _buildDrawer(),
      body: Column(
        children: [
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF1D9E75)))
              : ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  itemCount: _messages.length + (_zaraTyping ? 1 : 0),
                  itemBuilder: (context, i) {
                    if (_zaraTyping && i == _messages.length) {
                      return _buildTypingIndicator();
                    }
                    return _buildMessageBubble(_messages[i]);
                  },
                ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    final user = _auth.currentUser;
    return Drawer(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          Container(
            height: 150,
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.history_toggle_off, size: 32, color: Color(0xFF1D9E75)),
                const SizedBox(height: 12),
                Text("Chat History", 
                  style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
              ],
            ),
          ),
          ListTile(
            onTap: () {
              Navigator.pop(context);
              _createNewSession();
            },
            leading: const Icon(Icons.add_comment, color: Color(0xFF1D9E75)),
            title: Text("New Chat Session", style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
          ),
          const Divider(),
          Expanded(
            child: user == null
                ? const Center(child: Text("Guest Mode"))
                : StreamBuilder<QuerySnapshot>(
                    stream: _firestore
                        .collection('users')
                        .doc(user.uid)
                        .collection('sessions')
                        .orderBy('lastTimestamp', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                      final docs = snapshot.data!.docs;
                      if (docs.isEmpty) return Center(child: Text("No history yet da!", style: GoogleFonts.outfit(color: Colors.grey)));
                      
                      return ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: docs.length,
                        itemBuilder: (context, i) {
                          final doc = docs[i];
                          final isSelected = doc.id == _currentSessionId;
                          return ListTile(
                            selected: isSelected,
                            selectedTileColor: Theme.of(context).primaryColor.withOpacity(0.05),
                            leading: Icon(Icons.chat_outlined, size: 18, color: isSelected ? const Color(0xFF1D9E75) : Colors.grey),
                            title: Text(doc['title'], 
                              maxLines: 1, 
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(fontSize: 14, color: isSelected ? const Color(0xFF1D9E75) : Theme.of(context).colorScheme.onSurface)),
                            onTap: () {
                              Navigator.pop(context);
                              _loadSession(doc.id, doc['title']);
                            },
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, size: 16, color: Colors.grey),
                              onPressed: () {
                                _firestore.collection('users').doc(user.uid).collection('sessions').doc(doc.id).delete();
                              },
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(_ChatMessage msg) {
    final isZara = !msg.isUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: msg.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: msg.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (isZara)
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(color: Color(0xFF1D9E75), shape: BoxShape.circle),
                  child: const Icon(Icons.auto_awesome, size: 14, color: Colors.white),
                ),
              const SizedBox(width: 10),
              Text(
                isZara ? "ZARA" : "YOU",
                style: GoogleFonts.outfit(
                  fontSize: 10, 
                  fontWeight: FontWeight.bold, 
                  letterSpacing: 1,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: msg.isUser 
                ? Theme.of(context).primaryColor.withOpacity(0.1) 
                : Theme.of(context).cardColor,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(isZara ? 4 : 20),
                bottomRight: Radius.circular(isZara ? 20 : 4),
              ),
              border: isZara ? Border.all(color: Theme.of(context).dividerColor) : null,
            ),
            child: Text(
              msg.text,
              style: GoogleFonts.outfit(
                fontSize: 15,
                height: 1.6,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: TextField(
                controller: _inputCtrl,
                style: GoogleFonts.outfit(fontSize: 15),
                decoration: const InputDecoration(
                  hintText: 'Ask Zara anything...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.grey),
                ),
                onSubmitted: _sendMessage,
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => _sendMessage(_inputCtrl.text),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(color: Color(0xFF1D9E75), shape: BoxShape.circle),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Row(
              children: [
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1D9E75)),
                ),
                const SizedBox(width: 12),
                Text("Zara is thinking...", style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey)),
              ],
            ),
          ),
        ],
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
