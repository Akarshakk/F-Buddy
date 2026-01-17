import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import '../providers/language_provider.dart';

class TranslationService {
  TranslationService._();
  static final TranslationService instance = TranslationService._();

  final Map<String, OnDeviceTranslator> _translators = {};
  final OnDeviceTranslatorModelManager _modelManager = OnDeviceTranslatorModelManager();

  TranslateLanguage _toMlKitLanguage(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.hindi:
        return TranslateLanguage.hindi;
      case AppLanguage.marathi:
        return TranslateLanguage.marathi;
      case AppLanguage.english:
      default:
        return TranslateLanguage.english;
    }
  }

  String _cacheKey(AppLanguage source, AppLanguage target) => '${source.name}-${target.name}';

  Future<void> ensureModel(AppLanguage language) async {
    final lang = _toMlKitLanguage(language);
    final downloaded = await _modelManager.isModelDownloaded(lang.bcpCode);
    if (!downloaded) {
      await _modelManager.downloadModel(lang.bcpCode);
    }
  }

  Future<String> translate(
    String text, {
    required AppLanguage source,
    required AppLanguage target,
  }) async {
    if (source == target) return text;

    await ensureModel(source);
    await ensureModel(target);

    final key = _cacheKey(source, target);
    _translators[key] ??= OnDeviceTranslator(
      sourceLanguage: _toMlKitLanguage(source),
      targetLanguage: _toMlKitLanguage(target),
    );

    return _translators[key]!.translateText(text);
  }

  Future<void> close() async {
    for (final translator in _translators.values) {
      await translator.close();
    }
    _translators.clear();
  }
}
