import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../config/app_theme.dart';
import '../services/chat_service.dart';
import '../services/translation_service.dart';
import '../services/markets_service.dart';
import '../services/portfolio_report_service.dart';
import '../providers/language_provider.dart';
import '../providers/analytics_provider.dart';
import 'package:finzo/l10n/app_localizations.dart';

/// Floating chat widget for AI-powered financial advisory
class SmartChatWidget extends StatefulWidget {
  final bool isFullScreen;

  const SmartChatWidget({
    super.key,
    this.isFullScreen = false,
    this.onToggle,
  });

  final ValueChanged<bool>? onToggle;

  @override
  State<SmartChatWidget> createState() => _SmartChatWidgetState();
}

class _SmartChatWidgetState extends State<SmartChatWidget>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  final List<ChatMessage> _messages = [];
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final TranslationService _translationService = TranslationService.instance;
  bool _isLoading = false;

  // Pending action for confirmation flow
  String? _pendingAction;
  Map<String, dynamic>? _pendingParams;

  // Speech to text
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool _speechAvailable = false;

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    // Initialize speech to text
    _initSpeech();

    // Add welcome message
    // Welcome message is localized when widget builds (header shows language)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final l10n = context.l10n;
      _addMessage(
        ChatMessage(
          text: l10n.t('welcome_ai'),
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );
    });
  }

  Future<void> _initSpeech() async {
    _speechAvailable = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          setState(() => _isListening = false);
        }
      },
      onError: (error) {
        setState(() => _isListening = false);
      },
    );
    setState(() {});
  }

  Future<void> _startListening() async {
    if (!_speechAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Speech recognition not available'),
          backgroundColor: Colors.red[400],
        ),
      );
      return;
    }

    setState(() => _isListening = true);
    
    await _speech.listen(
      onResult: (result) {
        setState(() {
          _messageController.text = result.recognizedWords;
          // Move cursor to end
          _messageController.selection = TextSelection.fromPosition(
            TextPosition(offset: _messageController.text.length),
          );
        });
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      partialResults: true,
      localeId: 'en_IN', // Indian English
    );
  }

  Future<void> _stopListening() async {
    await _speech.stop();
    setState(() => _isListening = false);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _toggleChat() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
    widget.onToggle?.call(_isExpanded);
  }

  void _addMessage(ChatMessage message) {
    setState(() {
      _messages.add(message);
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// Handle portfolio report generation triggered from chat
  Future<void> _handleGenerateReport() async {
    try {
      // Fetch full portfolio data
      final portfolio = await MarketsService.getPortfolio();
      if (portfolio != null && portfolio.holdings.isNotEmpty) {
        // Generate and open PDF report
        await PortfolioReportService.generateAndPrintReport(portfolio);
        _addMessage(
          ChatMessage(
            text: '✅ Report generated! Check your print/download dialog.',
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
      } else {
        _addMessage(
          ChatMessage(
            text: '📊 You need some holdings in your portfolio first to generate a report.',
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
      }
    } catch (e) {
      print('[SmartChat] Error generating report: $e');
      _addMessage(
        ChatMessage(
          text: '❌ Failed to generate report. Please try again.',
          isUser: false,
          timestamp: DateTime.now(),
          isError: true,
        ),
      );
    }
  }

  Future<void> _sendMessage() async {
    final languageProvider = context.read<LanguageProvider>();
    final selectedLang = languageProvider.language;

    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    // Add user message
    _addMessage(
      ChatMessage(
        text: text,
        isUser: true,
        timestamp: DateTime.now(),
      ),
    );

    _messageController.clear();
    setState(() => _isLoading = true);

    try {
      // Translate user message to English if needed
      String outbound = text;
      if (selectedLang != AppLanguage.english) {
        try {
          outbound = await _translationService.translate(
            text,
            source: selectedLang,
            target: AppLanguage.english,
          );
        } catch (e) {
          _addMessage(
            ChatMessage(
              text: context.l10n.t('translate_fail'),
              isUser: false,
              timestamp: DateTime.now(),
              isError: true,
            ),
          );
        }
      }

      // Gather financial context (Balance + Portfolio)
      Map<String, dynamic> financialContext = {};
      
      // Strict Privacy Mode: We do NOT send any data snapshot upfront.
      // Gemini will use tools (getBalance, getPortfolio, etc.) to fetch data on demand.
      // This ensures minimum data exposure.

      // Build conversation history from previous messages (exclude welcome and error messages)
      List<Map<String, String>> conversationHistory = [];
      for (int i = 1; i < _messages.length; i++) { // Skip welcome message at index 0
        final msg = _messages[i];
        if (!msg.isError) {
          conversationHistory.add({
            'role': msg.isUser ? 'user' : 'assistant',
            'content': msg.text,
          });
        }
      }

      // Check if user is confirming a pending action
      final lowerText = outbound.toLowerCase().trim();
      final isConfirmation = _pendingAction != null && 
          (lowerText == 'yes' || lowerText == 'confirm' || lowerText == 'ok' || 
           lowerText == 'sure' || lowerText == 'go ahead' || lowerText == 'do it');

      if (isConfirmation && _pendingAction != null && _pendingParams != null) {
        // Execute the pending action
        final executeResult = await SmartChatService.executeAction(_pendingAction!, _pendingParams!);
        
        // Clear pending action
        _pendingAction = null;
        _pendingParams = null;
        
        String resultText = executeResult.message;
        if (selectedLang != AppLanguage.english) {
          try {
            resultText = await _translationService.translate(
              executeResult.message,
              source: AppLanguage.english,
              target: selectedLang,
            );
          } catch (_) {}
        }
        
        _addMessage(
          ChatMessage(
            text: resultText,
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
      } else {
        // Clear any pending action if user sends something else
        if (_pendingAction != null && !isConfirmation) {
          _pendingAction = null;
          _pendingParams = null;
        }

        // Get AI response with context and conversation history
        final response = await SmartChatService.chat(
          outbound, 
          context: financialContext,
          conversationHistory: conversationHistory,
        );

        if (response.success) {
          String answerText = response.answer;

          // Translate answer back to selected language if needed
          if (selectedLang != AppLanguage.english) {
            try {
              answerText = await _translationService.translate(
                response.answer,
                source: AppLanguage.english,
                target: selectedLang,
              );
            } catch (_) {
              answerText = '${response.answer}\n\n${context.l10n.t('translation_unavailable')}';
            }
          }

          _addMessage(
            ChatMessage(
              text: answerText,
              isUser: false,
              timestamp: DateTime.now(),
              sources: response.sources,
            ),
          );

          // Store pending action if this is a confirmation request
          if (response.needsConfirmation && response.action != null && response.params != null) {
            _pendingAction = response.action;
            _pendingParams = response.params;
          }

          // Handle special actions
          if (response.action == 'generatePortfolioReport') {
            // Trigger portfolio report generation
            _handleGenerateReport();
          }
        } else {
          _addMessage(
            ChatMessage(
              text: "${context.l10n.t('error_generic')} Error: ${response.message}",
              isUser: false,
              timestamp: DateTime.now(),
              isError: true,
            ),
          );
        }
      }
    } catch (e) {
      _addMessage(
        ChatMessage(
          text: context.l10n.t('error_connect'),
          isUser: false,
          timestamp: DateTime.now(),
          isError: true,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isFullScreen) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final backgroundColor = isDark ? AppColorsDark.background : Colors.white;
      
      return Scaffold(
        backgroundColor: backgroundColor,
        body: SafeArea(
          child: _buildChatInterface(context),
        ),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColorsDark.primary : AppColors.primary;
    final surfaceColor = isDark ? AppColorsDark.surface : AppColors.surface;

    return Stack(
      children: [
        // Expanded chat window
        if (_isExpanded)
          Positioned(
            right: 16,
            bottom: 90,
            child: ScaleTransition(
              scale: _scaleAnimation,
              alignment: Alignment.bottomRight,
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(16),
                color: surfaceColor,
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.85,
                  height: MediaQuery.of(context).size.height * 0.6,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: primaryColor.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: _buildChatInterface(context),
                ),
              ),
            ),
          ),

        // Floating action button
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            onPressed: _toggleChat,
            backgroundColor: primaryColor,
            child: Icon(
              _isExpanded ? Icons.close : Icons.chat,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChatInterface(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColorsDark.primary : AppColors.primary;
    final surfaceColor = isDark ? AppColorsDark.surface : AppColors.surface;
    final backgroundColor = isDark ? AppColorsDark.background : Colors.white;
    final languageProvider = context.watch<LanguageProvider>();
    final l10n = context.l10n;

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryColor, primaryColor.withOpacity(0.8)],
            ),
            borderRadius: widget.isFullScreen 
                ? null 
                : const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
          ),
          child: Row(
            children: [
              const Icon(Icons.smart_toy, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.t('ai_header'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${context.l10n.t('language')}: ${languageProvider.displayName}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (!widget.isFullScreen)
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: _toggleChat,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
        ),

        // Messages
        Expanded(
          child: Container(
            color: backgroundColor,
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _buildMessageBubble(_messages[index]);
              },
            ),
          ),
        ),

        // Loading indicator
        if (_isLoading)
          Container(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                const SizedBox(width: 16),
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(primaryColor),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  context.l10n.t('thinking'),
                  style: TextStyle(
                    color: primaryColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

        // Input field
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: surfaceColor,
            border: Border(
              top: BorderSide(
                color: primaryColor.withOpacity(0.2),
              ),
            ),
          ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: context.l10n.t('chat_hint_finance'),
                          border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(color: primaryColor.withOpacity(0.3)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(color: primaryColor.withOpacity(0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(color: primaryColor),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    filled: true,
                    fillColor: backgroundColor,
                  ),
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                  enabled: !_isLoading,
                ),
              ),
              const SizedBox(width: 12),
              // Mic button for speech-to-text
              Container(
                decoration: BoxDecoration(
                  color: _isListening 
                      ? Colors.red 
                      : primaryColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(
                    _isListening ? Icons.mic : Icons.mic_none,
                    color: _isListening ? Colors.white : primaryColor,
                  ),
                  onPressed: _isLoading 
                      ? null 
                      : (_isListening ? _stopListening : _startListening),
                  tooltip: _isListening ? 'Stop listening' : 'Speak',
                ),
              ),
              const SizedBox(width: 12),
              // Send button
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryColor, primaryColor.withOpacity(0.8)],
                  ),
                  shape: BoxShape.circle,
                  ),
                child: IconButton(
                  icon: const Icon(Icons.send, color: Colors.white),
                  onPressed: _isLoading ? null : _sendMessage,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColorsDark.primary : AppColors.primary;
    final textColor = isDark ? AppColorsDark.textPrimary : AppColors.textPrimary;
    final surfaceColor = isDark ? AppColorsDark.surface : Colors.grey.shade200;

    // Determine background color
    Color bubbleColor;
    if (message.isUser) {
      bubbleColor = primaryColor;
    } else if (message.isError) {
      bubbleColor = isDark ? Colors.red.withOpacity(0.2) : Colors.red.shade50;
    } else {
      bubbleColor = isDark ? Colors.grey.shade800 : Colors.grey.shade200;
    }

    // Determine text color
    Color messageTextColor;
    if (message.isUser) {
      messageTextColor = Colors.white;
    } else if (message.isError) {
      messageTextColor = isDark ? Colors.red.shade200 : Colors.red.shade900;
    } else {
      messageTextColor = isDark ? Colors.white : Colors.black87;
    }

    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment:
              message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.circular(16).copyWith(
                  bottomRight: message.isUser ? const Radius.circular(4) : null,
                  bottomLeft: !message.isUser ? const Radius.circular(4) : null,
                ),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: messageTextColor,
                  fontSize: 14,
                ),
              ),
            ),
            if (message.sources != null && message.sources!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 8),
                child: Text(
                  '${context.l10n.t('sources_label')}: ${message.sources!.join(", ")}',
                  style: TextStyle(
                    fontSize: 10,
                    color: textColor.withOpacity(0.6),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 2, left: 8, right: 8),
              child: Text(
                _formatTime(message.timestamp),
                style: TextStyle(
                  fontSize: 10,
                  color: textColor.withOpacity(0.6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final List<String>? sources;
  final bool isError;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.sources,
    this.isError = false,
  });
}


