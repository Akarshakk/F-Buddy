import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../services/translation_service.dart';

/// A widget that automatically translates text to the current app language.
/// Use this for dynamic text that isn't available in AppLocalizations.
class AutoTranslatedText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final TextOverflow? overflow;
  final int? maxLines;

  const AutoTranslatedText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.overflow,
    this.maxLines,
  });

  @override
  State<AutoTranslatedText> createState() => _AutoTranslatedTextState();
}

class _AutoTranslatedTextState extends State<AutoTranslatedText> {
  String? _translatedText;
  AppLanguage? _currentLang;
  String? _originalText;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkTranslation();
  }

  @override
  void didUpdateWidget(AutoTranslatedText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.text != oldWidget.text) {
      _checkTranslation();
    }
  }

  void _checkTranslation() {
    final languageProvider = context.watch<LanguageProvider>();
    final newLang = languageProvider.language;
    final text = widget.text;

    // If language changed or text changed
    if (_currentLang != newLang || _originalText != text) {
      _originalText = text;
      _currentLang = newLang;

      if (newLang == AppLanguage.english) {
        setState(() {
          _translatedText = null; // Show original (English)
        });
      } else {
        _translate(text, newLang);
      }
    }
  }

  Future<void> _translate(String text, AppLanguage target) async {
    try {
      final result = await TranslationService.instance.translate(
        text,
        source: AppLanguage.english,
        target: target,
      );
      if (mounted && _currentLang == target && _originalText == text) {
        setState(() {
          _translatedText = result;
        });
      }
    } catch (e) {
      debugPrint('AutoTranslation error: $e');
      // On error, we just keep showing the original text (or previous translation)
      // We could set _translatedText = text; but keeping it null shows widget.text
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _translatedText ?? widget.text,
      style: widget.style,
      textAlign: widget.textAlign,
      overflow: widget.overflow,
      maxLines: widget.maxLines,
    );
  }
}
