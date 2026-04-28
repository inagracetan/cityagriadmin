import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/ai_service.dart';
import '../services/settings_provider.dart';
import '../services/firebase_service.dart';
import '../models/activity.dart';
import 'dart:ui';
import 'package:flutter_markdown/flutter_markdown.dart';

class ChatWidget extends StatefulWidget {
  const ChatWidget({super.key});

  @override
  State<ChatWidget> createState() => _ChatWidgetState();
}

class _ChatWidgetState extends State<ChatWidget> {
  final TextEditingController _controller = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _isThinking = false;
  AiService? _aiService;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initAi();
    });
  }

  Future<void> _initAi() async {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    if (settings.geminiApiKey.isNotEmpty) {
      _aiService = AiService(settings.geminiApiKey);
      // Fetch data for context
      final firebase = Provider.of<FirebaseService>(context, listen: false);
      // For now, we take a snapshot of activities.
      // In a real app, you'd stream this or pass the current list.
      final activities = await firebase.db.collection('activities').get().then(
            (s) => s.docs.map((d) => Activity.fromFirestore(d.data(), d.id)).toList(),
          );
      _aiService!.startNewSession(activities);
    }
  }

  void _sendMessage() async {
    if (_controller.text.trim().isEmpty || _aiService == null) return;

    final userMessage = _controller.text.trim();
    setState(() {
      _messages.add(ChatMessage(text: userMessage, isUser: true));
      _controller.clear();
      _isThinking = true;
    });

    final response = await _aiService!.sendMessage(userMessage);

    setState(() {
      _isThinking = false;
      _messages.add(ChatMessage(text: response, isUser: false));
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final theme = Theme.of(context);

    if (settings.geminiApiKey.isEmpty) {
      return _buildApiKeyPrompt(settings, theme);
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutQuart,
      width: _isExpanded ? 350 : 60,
      height: _isExpanded ? 500 : 60,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(_isExpanded ? 24 : 30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_isExpanded ? 24 : 30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: _isExpanded ? _buildChatContent(theme) : _buildCollapsedIcon(theme),
        ),
      ),
    );
  }

  Widget _buildCollapsedIcon(ThemeData theme) {
    return GestureDetector(
      onTap: () => setState(() => _isExpanded = true),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.primary,
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withValues(alpha: 0.3),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: const Icon(Icons.auto_awesome, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildChatContent(ThemeData theme) {
    return Column(
      children: [
        _buildHeader(theme),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            itemCount: _messages.length,
            itemBuilder: (context, index) => _messages[index],
          ),
        ),
        if (_isThinking)
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainer.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const SizedBox(
                    width: 20,
                    height: 10,
                    child: Center(
                      child: LinearProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1B5E20)),
                        backgroundColor: Colors.transparent,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        _buildInput(theme),
      ],
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.colorScheme.primary, theme.colorScheme.tertiary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "AWFPS Assistant",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                "Online | Intelligence Engine",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70, size: 18),
            onPressed: () {
              setState(() => _messages.clear());
              _initAi();
            },
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white70, size: 18),
            onPressed: () => setState(() => _isExpanded = false),
          ),
        ],
      ),
    );
  }

  Widget _buildInput(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(top: BorderSide(color: theme.dividerColor)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: "Ask about activities...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainer,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _sendMessage,
            icon: const Icon(Icons.send),
            color: theme.colorScheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildApiKeyPrompt(SettingsProvider settings, ThemeData theme) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) {
            final controller = TextEditingController();
            return AlertDialog(
              title: const Text("Enter Gemini API Key"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("To use the AI assistant, please provide your Gemini API key from Google AI Studio."),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    decoration: const InputDecoration(labelText: "API Key"),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () {
                    settings.setGeminiApiKey(controller.text.trim());
                    Navigator.pop(context);
                    _initAi();
                  },
                  child: const Text("Save"),
                ),
              ],
            );
          },
        );
      },
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: theme.colorScheme.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(30),
        ),
        child: const Icon(Icons.key, color: Colors.red),
      ),
    );
  }
}


class ChatMessage extends StatelessWidget {
  final String text;
  final bool isUser;

  const ChatMessage({super.key, required this.text, required this.isUser});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        decoration: BoxDecoration(
          color: isUser 
              ? theme.colorScheme.primary 
              : theme.colorScheme.surfaceContainer,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          boxShadow: [
            if (!isUser)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: isUser 
          ? Text(
              text,
              style: TextStyle(
                color: isUser ? Colors.white : theme.colorScheme.onSurface,
              ),
            )
          : MarkdownBody(
              data: text,
              styleSheet: MarkdownStyleSheet(
                p: TextStyle(color: theme.colorScheme.onSurface, fontSize: 14),
                strong: const TextStyle(fontWeight: FontWeight.bold),
                listBullet: TextStyle(color: theme.colorScheme.primary),
                tableBody: TextStyle(color: theme.colorScheme.onSurface, fontSize: 12),
                tableHead: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
      ),
    );
  }
}
