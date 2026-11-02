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

  /// Maximum character length per chunk for long input texts before chunking is triggered.
  static const int maxChunkCharLength = 4000;

  /// Maximum file size (in bytes) allowed for text file ingestion (5 MB).
  static const int maxFileBytes = 5 * 1024 * 1024;

  /// Builds the prompt for summarizing text into a specified number of bullet points.
  static String buildSummaryPrompt(String text, int bulletCount) {
    return 'Summarize the following text into exactly $bulletCount concise, informative bullet points.\n\n'
        'Output rules:\n'
        '- Output only the bullet points, each on a new line.\n'
        '- Start each bullet point with a hyphen followed by a space ("- ").\n'
        '- Do not include any title, introductory text, preamble, or conclusion.\n\n'
        'Text to summarize:\n$text';
  }

  /// Builds the prompt for summarizing an intermediate chunk of long text.
  static String buildChunkSummaryPrompt(String chunk) {
    return 'Summarize the key information from this section into concise bullet points.\n\n'
        'Output rules:\n'
        '- Output only bullet points, each on a new line.\n'
        '- Start each bullet point with a hyphen followed by a space ("- ").\n'
        '- Do not include any conversational text or preamble.\n\n'
        'Section to summarize:\n$chunk';
  }
}
