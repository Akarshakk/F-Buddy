import 'dart:io';

void main() {
  print('Creating widgets directory README...');
  
  final readme = File('README.md');
  readme.writeAsStringSync('''
# Finzo Widgets

This directory contains reusable Flutter widgets used across the Finzo app.

## Widgets

### RagChatWidget
**File**: `rag_chat_widget.dart`

AI-powered financial advisory chatbot widget that appears in the Personal Finance Manager section.

**Features:**
- Floating action button (bottom-right)
- Expandable chat interface
- Message bubbles (user/AI)
- Typing indicator
- Source attribution
- Dark mode support
- Smooth animations

**Usage:**
```dart
import 'package:finzo/widgets/rag_chat_widget.dart';

// Add to any screen
Stack(
  children: [
    // Your main content
    YourContent(),
    
    // Floating chat widget
    const RagChatWidget(),
  ],
)
```

**Backend Requirement:**
Requires RAG service running on port 5002. See `RAG_FEATURE_GUIDE.md` for setup.

**API Endpoints Used:**
- `POST /chat` - Send query and get AI response
- `GET /health` - Check service status
- `GET /stats` - Get knowledge base statistics

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


