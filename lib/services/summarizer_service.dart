import 'dart:async';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:summarizit/utils/constants.dart';

/// Represents the outcome of a summarization request.
class SummaryResult {
  /// The extracted or generated bullet points.
  final List<String> bullets;

  /// Whether the result fell back to the offline extractive summarizer.
  final bool usedFallback;

  /// A descriptive message if a fallback occurred.
  final String? notice;

  const SummaryResult({
    required this.bullets,
    this.usedFallback = false,
    this.notice,
  });
}

/// Extractive text summarization engine and Generative AI wrapper.
/// Scores sentences by word frequency (excluding stopwords) and returns
/// the top 3–5 most important sentences as bullet points, or uses Gemini API.
class SummarizerService {
  final SharedPreferences? prefs;

  SummarizerService({this.prefs});

  /// Check if AI is configured and enabled.
  bool get isAiEnabled {
    final apiKey = prefs?.getString(AppConstants.keyGeminiApiKey);
    final useAi = prefs?.getBool(AppConstants.keyUseAiSummarization) ?? false;
    return apiKey != null && apiKey.isNotEmpty && useAi;
  }
  /// English stopwords to ignore when scoring.
  static const Set<String> _stopwords = {
    'i', 'me', 'my', 'myself', 'we', 'our', 'ours', 'ourselves', 'you',
    'your', 'yours', 'yourself', 'yourselves', 'he', 'him', 'his', 'himself',
    'she', 'her', 'hers', 'herself', 'it', 'its', 'itself', 'they', 'them',
    'their', 'theirs', 'themselves', 'what', 'which', 'who', 'whom', 'this',
    'that', 'these', 'those', 'am', 'is', 'are', 'was', 'were', 'be', 'been',
    'being', 'have', 'has', 'had', 'having', 'do', 'does', 'did', 'doing',
    'a', 'an', 'the', 'and', 'but', 'if', 'or', 'because', 'as', 'until',
    'while', 'of', 'at', 'by', 'for', 'with', 'about', 'against', 'between',
    'through', 'during', 'before', 'after', 'above', 'below', 'to', 'from',
    'up', 'down', 'in', 'out', 'on', 'off', 'over', 'under', 'again',
    'further', 'then', 'once', 'here', 'there', 'when', 'where', 'why',
    'how', 'all', 'both', 'each', 'few', 'more', 'most', 'other', 'some',
    'such', 'no', 'nor', 'not', 'only', 'own', 'same', 'so', 'than', 'too',
    'very', 's', 't', 'can', 'will', 'just', 'don', 'should', 'now', 'd',
    'll', 'm', 'o', 're', 've', 'y', 'ain', 'aren', 'couldn', 'didn',
    'doesn', 'hadn', 'hasn', 'haven', 'isn', 'ma', 'mightn', 'mustn',
    'needn', 'shan', 'shouldn', 'wasn', 'weren', 'won', 'wouldn', 'also',
    'however', 'would', 'could', 'may', 'might', 'shall', 'must', 'yet',
    'still', 'already', 'even', 'though', 'although', 'since', 'whether',
    'into', 'upon', 'within', 'without', 'along', 'among', 'around',
    'throughout', 'toward', 'towards', 'across', 'behind', 'beyond',
  };

  /// Splits [text] into sentences using common punctuation boundaries.
  List<String> _tokenizeSentences(String text) {
    // Normalize whitespace
    final cleaned = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    // Split on period / exclamation / question mark followed by space or end
    final raw = cleaned.split(RegExp(r'(?<=[.!?])\s+'));
    return raw
        .map((s) => s.trim())
        .where((s) => s.length > 15) // ignore very short fragments
        .toList();
  }

  /// Extracts meaningful words from [text] (lowercased, non-stopword,
  /// alphabetic only).
  List<String> _extractWords(String text) {
    return text
        .toLowerCase()
        .split(RegExp(r'[^a-z]+'))
        .where((w) => w.length > 2 && !_stopwords.contains(w))
        .toList();
  }

  /// Summarize [text] asynchronously. Returns AI summary if enabled,
  /// otherwise falls back to extractive summarization.
  Future<SummaryResult> summarizeAsync(
    String text, {
    int bulletCount = AppConstants.defaultBulletCount,
  }) async {
    if (isAiEnabled) {
      try {
        final apiKey = prefs!.getString(AppConstants.keyGeminiApiKey)!;
        final model = GenerativeModel(
          model: AppConstants.geminiModel,
          apiKey: apiKey,
        );

        final prompt =
            'Summarize the following text into exactly $bulletCount concise bullet points. '
            'Only output the bullet points, starting each with a hyphen. Do not include introductory text.\n\n$text';

        final response = await model
            .generateContent([Content.text(prompt)])
            .timeout(AppConstants.geminiTimeout);

        if (response.text != null && response.text!.trim().isNotEmpty) {
          // Parse the hyphenated list into a string array
          final bullets = response.text!
              .split('\n')
              .map((line) => line.trim())
              .where((line) => line.startsWith('-'))
              .map((line) => line.substring(1).trim()) // Remove hyphen
              .where((line) => line.isNotEmpty)
              .toList();

          if (bullets.isNotEmpty) {
            return SummaryResult(bullets: bullets, usedFallback: false);
          }
        }

        // Empty response from AI: fallback to offline extractive summary
        return SummaryResult(
          bullets: summarize(text, bulletCount: bulletCount),
          usedFallback: true,
          notice: AppConstants.fallbackNotice,
        );
      } catch (e) {
        // Fall back to extractive summarization on error or timeout
        return SummaryResult(
          bullets: summarize(text, bulletCount: bulletCount),
          usedFallback: true,
          notice: AppConstants.fallbackNotice,
        );
      }
    }
    return SummaryResult(
      bullets: summarize(text, bulletCount: bulletCount),
      usedFallback: false,
    );
  }

  /// Summarize [text] into [bulletCount] key sentences (default 3–5).
  List<String> summarize(String text, {int bulletCount = AppConstants.defaultBulletCount}) {
    final sentences = _tokenizeSentences(text);
    if (sentences.isEmpty) return [];

    // Build word frequency map across all sentences
    final allWords = _extractWords(text);
    final freq = <String, int>{};
    for (final w in allWords) {
      freq[w] = (freq[w] ?? 0) + 1;
    }

    // Normalize frequencies
    final maxFreq = freq.values.reduce((a, b) => a > b ? a : b);
    final normFreq = freq.map((k, v) => MapEntry(k, v / maxFreq));

    // Score each sentence
    final scores = <int, double>{};
    for (int i = 0; i < sentences.length; i++) {
      final words = _extractWords(sentences[i]);
      if (words.isEmpty) continue;
      double score = 0;
      for (final w in words) {
        score += normFreq[w] ?? 0;
      }
      // Normalize by sentence length to avoid bias toward long sentences
      scores[i] = score / words.length;
    }

    // Determine how many bullets (3–5 depending on text length)
    int count = bulletCount;
    if (sentences.length <= 3) {
      count = sentences.length;
    } else if (sentences.length <= 6) {
      count = 3;
    } else {
      count = count.clamp(3, 5);
    }

    // Get top indices, sorted by original order to preserve flow
    final topIndices = (scores.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value)))
        .take(count)
        .map((e) => e.key)
        .toList()
      ..sort();

    return topIndices.map((i) => sentences[i]).toList();
  }
}
