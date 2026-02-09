import 'dart:io';

void main() {
  print('Creating widgets directory README...');
  
  final readme = File('README.md');
  readme.writeAsStringSync('''
# Finzo Widgets

This directory contains reusable Flutter widgets used across the Finzo app.

## Widgets

### SmartChatWidget
**File**: `smart_chat_widget.dart`

AI-powered financial chatbot widget that provides conversational CRUD operations.

**Features:**
- Floating action button (bottom-right)
- Expandable chat interface
- Full-screen mode for dedicated chat tab
- Voice input (speech-to-text)
- Multi-language support
- Message bubbles (user/AI)
- Typing indicator
- Dark mode support
- Smooth animations
- Portfolio report generation

**Usage:**
```dart
import 'package:finzo/widgets/smart_chat_widget.dart';

// Add to any screen
Stack(
  children: [
    // Your main content
    YourContent(),
    
    // Floating chat widget
    const SmartChatWidget(),
  ],
)

// Or use in full-screen mode
const SmartChatWidget(isFullScreen: true),
```

**Backend Requirement:**
Requires main backend with /api/chat endpoint. Uses Gemini API for NLP.

**Capabilities:**
- READ: Get expenses, income, debts, portfolio, analytics
- WRITE: Add/update/delete expenses, income, debts
- ACTIONS: Generate portfolio report, set savings goals
- GROUPS: Create groups, add members, manage expenses

**State Management:**
- Uses `StatefulWidget` with `SingleTickerProviderStateMixin`
- Manages local chat history
- Handles loading states
- Error handling with fallback messages

**Customization:**
Colors and theme adapt automatically to app's light/dark mode.
''');
  
  print('✅ README created successfully!');
}


