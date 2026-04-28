import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/ai_service.dart';
import '../services/settings_provider.dart';
import '../services/firebase_service.dart';
import '../models/activity.dart';
import 'dart:ui';
import 'dart:async';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter/services.dart';

class ChatWidget extends StatefulWidget {
  const ChatWidget({super.key});

  @override
  State<ChatWidget> createState() => _ChatWidgetState();
}

class _ChatWidgetState extends State<ChatWidget> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isThinking = false;
  AiService? _aiService;
  bool _isExpanded = false;
  StreamSubscription? _activitiesSubscription;
  String? _lastApiKey;

  final List<String> _suggestedQueries = [
    "📌 Analyze budget utilization",
    "⚠️ Identify low balance bottlenecks",
    "🚜 Status of Livestock projects",
    "📅 Summarize Q2 planning",
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initAi();
  }

  Future<void> _initAi() async {
    if (!mounted) return;
    final settings = Provider.of<SettingsProvider>(context);

    if (settings.geminiApiKey.isEmpty || settings.geminiApiKey == _lastApiKey) {
      return;
    }

    _lastApiKey = settings.geminiApiKey;
    _aiService = AiService(settings.geminiApiKey);

    final firebase = Provider.of<FirebaseService>(context, listen: false);

    // Cancel previous subscription if any
    await _activitiesSubscription?.cancel();

    // Set up real-time synchronization with Firestore
    _activitiesSubscription = firebase.streamActivities().listen((activities) {
      if (_aiService != null) {
        _aiService!.updateActivities(activities);
      }
    });

    // Initial fetch to start the session
    try {
      final initialActivities = await firebase.db
          .collection('activities')
          .get()
          .then(
            (s) => s.docs
                .map((d) => Activity.fromFirestore(d.data(), d.id))
                .toList(),
          );
      _aiService!.startNewSession(initialActivities);

      if (_messages.isEmpty && mounted) {
        setState(() {
          _messages.add(
            const ChatMessage(
              text:
                  "👋 Hello! I am the **AWFPS Intelligence Engine**, your premium administrative consultant.\n\nI have synchronized with the **live Firestore database** and I'm ready to help you with:\n\n*   📊 **Financial Analysis** & Budget Tracking\n*   ⚠️ **Bottleneck Detection** (PR/PPMP Balances)\n*   🚜 **Sector-specific Reports**\n\nHow can I assist your planning today?\n\n*Note: Puwede rin tayong mag-usap sa Filipino o Bisaya!*",
              isUser: false,
            ),
          );
        });
      }
    } catch (e) {
      debugPrint("ChatWidget: Failed to fetch initial activities: $e");
    }
  }

  @override
  void dispose() {
    _activitiesSubscription?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _sendMessage({String? text}) async {
    final messageText = text ?? _controller.text.trim();
    if (messageText.isEmpty || _aiService == null) return;

    setState(() {
      _messages.add(ChatMessage(text: messageText, isUser: true));
      if (text == null) _controller.clear();
      _isThinking = true;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    // Create a placeholder message for the AI response
    final aiMessageIndex = _messages.length;
    setState(() {
      _messages.add(const ChatMessage(text: "", isUser: false));
    });

    try {
      await for (final chunk in _aiService!.sendMessageStream(messageText)) {
        if (mounted) {
          setState(() {
            _messages[aiMessageIndex] = ChatMessage(text: chunk, isUser: false);
            _isThinking = false;
          });
          _scrollToBottom();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isThinking = false;
          _messages[aiMessageIndex] = ChatMessage(
            text: "Error: ${e.toString()}",
            isUser: false,
          );
        });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutQuart,
      width: _isExpanded ? 500 : 65,
      height: _isExpanded ? 650 : 65,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(_isExpanded ? 32 : 35),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.2),
            blurRadius: 25,
            spreadRadius: 5,
          ),
        ],
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
          width: 2,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_isExpanded ? 32 : 35),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Material(
            color: Colors.transparent,
            child: _isExpanded
                ? OverflowBox(
                    minWidth: 500,
                    maxWidth: 500,
                    minHeight: 650,
                    maxHeight: 650,
                    alignment: Alignment.bottomRight,
                    child: _buildChatContent(theme),
                  )
                : _buildCollapsedIcon(theme),
          ),
        ),
      ),
    );
  }

  Widget _buildCollapsedIcon(ThemeData theme) {
    return GestureDetector(
      onTap: () => setState(() => _isExpanded = true),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [theme.colorScheme.primary, theme.colorScheme.tertiary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
          builder: (context, value, child) {
            return Transform.scale(
              scale: 1.0 + (0.1 * value),
              child: const Icon(
                Icons.auto_awesome,
                color: Colors.white,
                size: 30,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildChatContent(ThemeData theme) {
    final settings = Provider.of<SettingsProvider>(context);

    return Column(
      children: [
        _buildHeader(theme),
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            itemCount: _messages.length,
            itemBuilder: (context, index) => _messages[index],
          ),
        ),
        if (!_isThinking && _messages.length <= 1) _buildSuggestedQueries(theme),
        if (_isThinking)
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const TypingIndicator(),
                ),
              ],
            ),
          ),
        _buildInput(theme),
      ],
    );
  }

  Widget _buildSuggestedQueries(ThemeData theme) {
    return Container(
      height: 50,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _suggestedQueries.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ActionChip(
              label: Text(
                _suggestedQueries[index],
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.primary,
                ),
              ),
              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.05),
              side: BorderSide(
                color: theme.colorScheme.primary.withValues(alpha: 0.2),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              onPressed: () => _sendMessage(text: _suggestedQueries[index]),
            ),
          );
        },
      ),
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
            child: const Icon(
              Icons.auto_awesome,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
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
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(
              Icons.delete_sweep_outlined,
              color: Colors.white70,
            ),
            tooltip: 'Clear Chat',
            onPressed: () {
              setState(() {
                _messages.clear();
                _messages.add(
                  const ChatMessage(
                    text:
                        "Hello! I am your AI Assistant. How can I help you today?",
                    isUser: false,
                  ),
                );
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: _initAi,
            tooltip: 'Restart AI Session',
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.3,
                ),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                ),
              ),
              child: TextField(
                controller: _controller,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText: "Ask about AWFPS data...",
                  hintStyle: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.5,
                    ),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: IconButton(
              onPressed: _sendMessage,
              icon: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
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
    final isDark = theme.brightness == Brightness.dark;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.85,
        ),
        decoration: BoxDecoration(
          gradient: isUser
              ? LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.primary.withValues(alpha: 0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isUser
              ? null
              : (isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.03)),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isUser ? 20 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 20),
          ),
          border: !isUser
              ? Border.all(color: theme.dividerColor.withValues(alpha: 0.1))
              : null,
          boxShadow: [
            BoxShadow(
              color: isUser
                  ? theme.colorScheme.primary.withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isUser)
              Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              )
            else ...[
              MarkdownBody(
                data: text.isEmpty ? "..." : text,
                selectable: true,
                styleSheet: MarkdownStyleSheet(
                  p: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontSize: 14,
                    height: 1.5,
                  ),
                  strong: const TextStyle(fontWeight: FontWeight.bold),
                  listBullet: TextStyle(color: theme.colorScheme.primary),
                  code: TextStyle(
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                  tableBody: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontSize: 12,
                  ),
                  tableHead: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  tableCellsPadding: const EdgeInsets.all(8),
                  tableBorder: TableBorder.all(
                    color: theme.dividerColor.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
              ),
              if (text.isNotEmpty && !isUser) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, size: 14),
                      visualDensity: VisualDensity.compact,
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: text));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Copied to clipboard'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                      color: theme.colorScheme.primary.withValues(alpha: 0.5),
                    ),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(3, (index) {
      return AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      );
    });

    _animations = _controllers.map((controller) {
      return Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut));
    }).toList();

    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 200), () {
        if (mounted) {
          _controllers[i].repeat(reverse: true);
        }
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _animations[index],
          builder: (context, child) {
            return Container(
              width: 5,
              height: 5,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(
                  alpha: 0.4 + (0.6 * _animations[index].value),
                ),
                shape: BoxShape.circle,
              ),
              transform: Matrix4.translationValues(
                0,
                -3 * _animations[index].value,
                0,
              ),
            );
          },
        );
      }),
    );
  }
}
