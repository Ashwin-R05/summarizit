/// App-wide configuration values and constants.
class AppConstants {
  AppConstants._();

  /// The official supported Google Gemini Flash model name.
  static const String geminiModel = 'gemini-3.8-flash';

  /// Default number of bullet points for generated summaries.
  static const int defaultBulletCount = 5;

  /// Maximum timeout duration for Gemini API requests.
  static const Duration geminiTimeout = Duration(seconds: 30);

  /// User-facing notice shown when AI generation fails and falls back to offline summarization.
  static const String fallbackNotice = 'AI unavailable, used offline summary';

  /// Key used in storage for the Gemini API key.
  static const String keyGeminiApiKey = 'gemini_api_key';

  /// Key used in preferences for the AI summarization toggle.
  static const String keyUseAiSummarization = 'use_ai_summarization';
}
