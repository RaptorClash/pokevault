// GENERATED CODE - DO NOT MODIFY BY HAND
// Generated from lib/i18n/languages.json via tool/translate_all.py

class AppLanguageConfig {
  final String code;
  final String flag;
  final String nameNative;
  final String nameEn;
  final bool isPokemonFranchise;
  final String slangCode;

  const AppLanguageConfig({
    required this.code,
    required this.flag,
    required this.nameNative,
    required this.nameEn,
    required this.isPokemonFranchise,
    required this.slangCode,
  });
}

class LanguageRegistry {
  static const List<AppLanguageConfig> supportedAppLanguages = [
    AppLanguageConfig(
      code: 'de',
      flag: '🇩🇪',
      nameNative: 'Deutsch',
      nameEn: 'German',
      isPokemonFranchise: true,
      slangCode: 'de',
    ),
    AppLanguageConfig(
      code: 'en',
      flag: '🇬🇧',
      nameNative: 'English',
      nameEn: 'English',
      isPokemonFranchise: true,
      slangCode: 'en',
    ),
    AppLanguageConfig(
      code: 'fr',
      flag: '🇫🇷',
      nameNative: 'Français',
      nameEn: 'French',
      isPokemonFranchise: true,
      slangCode: 'fr',
    ),
    AppLanguageConfig(
      code: 'es',
      flag: '🇪🇸',
      nameNative: 'Español',
      nameEn: 'Spanish',
      isPokemonFranchise: true,
      slangCode: 'es',
    ),
    AppLanguageConfig(
      code: 'it',
      flag: '🇮🇹',
      nameNative: 'Italiano',
      nameEn: 'Italian',
      isPokemonFranchise: true,
      slangCode: 'it',
    ),
    AppLanguageConfig(
      code: 'ja',
      flag: '🇯🇵',
      nameNative: '日本語',
      nameEn: 'Japanese',
      isPokemonFranchise: true,
      slangCode: 'ja',
    ),
    AppLanguageConfig(
      code: 'ko',
      flag: '🇰🇷',
      nameNative: '한국어',
      nameEn: 'Korean',
      isPokemonFranchise: true,
      slangCode: 'ko',
    ),
    AppLanguageConfig(
      code: 'zh-Hans',
      flag: '🇨🇳',
      nameNative: '简体中文',
      nameEn: 'Simplified Chinese',
      isPokemonFranchise: true,
      slangCode: 'zh-Hans',
    ),
    AppLanguageConfig(
      code: 'zh-Hant',
      flag: '🇹🇼',
      nameNative: '繁體中文',
      nameEn: 'Traditional Chinese',
      isPokemonFranchise: true,
      slangCode: 'zh-Hant',
    ),
    AppLanguageConfig(
      code: 'pt',
      flag: '🇵🇹',
      nameNative: 'Português',
      nameEn: 'Portuguese',
      isPokemonFranchise: false,
      slangCode: 'pt',
    ),
    AppLanguageConfig(
      code: 'nl',
      flag: '🇳🇱',
      nameNative: 'Nederlands',
      nameEn: 'Dutch',
      isPokemonFranchise: false,
      slangCode: 'nl',
    ),
    AppLanguageConfig(
      code: 'pl',
      flag: '🇵🇱',
      nameNative: 'Polski',
      nameEn: 'Polish',
      isPokemonFranchise: false,
      slangCode: 'pl',
    ),
    AppLanguageConfig(
      code: 'ru',
      flag: '🇷🇺',
      nameNative: 'Русский',
      nameEn: 'Russian',
      isPokemonFranchise: false,
      slangCode: 'ru',
    ),
  ];

  static List<AppLanguageConfig> get supportedPokemonLanguages =>
      supportedAppLanguages.where((l) => l.isPokemonFranchise).toList();

  static const Map<String, String> _languageAliases = {
    'zh': 'zh-Hans',
    'zh-cn': 'zh-Hans',
    'zh-sg': 'zh-Hans',
    'zh-cmn-hans': 'zh-Hans',
    'zh-tw': 'zh-Hant',
    'zh-hk': 'zh-Hant',
    'zh-mo': 'zh-Hant',
    'zh-cmn-hant': 'zh-Hant',
  };

  static AppLanguageConfig? findByCode(String code) {
    final normalized = code.toLowerCase().replaceAll('_', '-');
    for (final lang in supportedAppLanguages) {
      if (lang.code.toLowerCase().replaceAll('_', '-') == normalized) {
        return lang;
      }
    }
    final aliasTarget = _languageAliases[normalized];
    if (aliasTarget != null) {
      for (final lang in supportedAppLanguages) {
        if (lang.code.toLowerCase().replaceAll('_', '-') == aliasTarget.toLowerCase()) {
          return lang;
        }
      }
    }
    return null;
  }

  static bool isPokemonFranchise(String code) {
    final lang = findByCode(code);
    return lang?.isPokemonFranchise ?? false;
  }

  static String resolveEffectivePokemonLanguage(
    String appLangCode,
    String pokemonLangCode,
  ) {
    if (pokemonLangCode != 'auto') {
      final explicit = findByCode(pokemonLangCode);
      return explicit?.code ?? pokemonLangCode;
    }

    if (isPokemonFranchise(appLangCode)) {
      final matched = findByCode(appLangCode);
      return matched?.code ?? appLangCode;
    }

    return 'en';
  }
}
