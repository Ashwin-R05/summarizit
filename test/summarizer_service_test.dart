import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:summarizit/services/summarizer_service.dart';
import 'package:summarizit/utils/constants.dart';

/// Test mock for [GeminiClient] allowing customizable response behavior.
class MockGeminiClient implements GeminiClient {
  final Future<String?> Function(String prompt)? onGenerate;
  final bool shouldFail;
  final bool shouldTimeout;
  final String? responseText;

  MockGeminiClient({
    this.onGenerate,
    this.shouldFail = false,
    this.shouldTimeout = false,
    this.responseText,
  });

  @override
  Future<String?> generateContent(String prompt) async {
    if (shouldTimeout) {
      // Simulate a delay exceeding AppConstants.geminiTimeout
      await Future<void>.delayed(const Duration(seconds: 40));
      return responseText;
    }
    if (shouldFail) {
      throw Exception('Gemini API call failed: 503 Service Unavailable');
    }
    if (onGenerate != null) {
      return onGenerate!(prompt);
    }
    return responseText ?? '- Point 1\n- Point 2\n- Point 3';
  }
}

void main() {
  group('SummarizerService — Offline Extractive Summarizer', () {
    late SummarizerService service;

    setUp(() {
      service = SummarizerService();
    });

    test('Stopword removal eliminates common functional words', () {
      final text = 'The quick brown fox is jumping over the lazy dog and because of that it was tired.';
      final words = service.extractWords(text);

      expect(words, contains('quick'));
      expect(words, contains('brown'));
      expect(words, contains('fox'));
      expect(words, contains('jumping'));
      expect(words, contains('lazy'));
      expect(words, contains('tired'));

      // Verify stopwords are excluded
      expect(words, isNot(contains('the')));
      expect(words, isNot(contains('is')));
      expect(words, isNot(contains('over')));
      expect(words, isNot(contains('and')));
      expect(words, isNot(contains('because')));
      expect(words, isNot(contains('that')));
      expect(words, isNot(contains('was')));
    });

    test('Scoring ranks sentences with high-frequency topic keywords higher', () {
      // "quantum computing" appears repeatedly across the document
      final text =
          'Quantum computing uses quantum mechanics to solve complex problems. '
          'Classical computers operate with binary bits of zeros and ones. '
          'Quantum processors leverage quantum superposition and quantum entanglement. '
          'Weather forecasts predict mild rain in southern regions tomorrow morning. '
          'Quantum algorithms provide exponential speedup for specific computational quantum simulations.';

      final summary = service.summarize(text, bulletCount: 3);

      expect(summary.length, equals(3));
      // Top sentences should be about quantum computing, not weather
      expect(summary.any((s) => s.contains('Weather forecasts')), isFalse);
      expect(summary.any((s) => s.contains('Quantum')), isTrue);
    });

    group('Sentence bounds (3–5)', () {
      test('Returns all sentences when input has 3 or fewer sentences', () {
        final text =
            'Artificial intelligence is advancing at an unprecedented pace worldwide. '
            'Machine learning models now power language translation and speech recognition. '
            'Autonomous systems are being deployed across healthcare and robotics.';

        final summary = service.summarize(text);
        expect(summary.length, equals(3));
      });

      test('Returns exactly 3 sentences when input has 4 to 6 sentences', () {
        final text =
            'Renewable energy sources are becoming the dominant power choice. '
            'Solar power installations have increased significantly across global markets. '
            'Wind turbines generate substantial clean electricity on offshore coastal wind farms. '
            'Energy storage batteries are critical for grid balancing and reliability. '
            'Hydroelectric dams continue providing reliable baseload renewable energy.';

        final summary = service.summarize(text, bulletCount: 5);
        // Between 4 and 6 sentences, the extractive engine clamps to exactly 3
        expect(summary.length, equals(3));
      });

      test('Bounds output between 3 and 5 sentences for long texts (7+ sentences)', () {
        final text =
            'Sentence number one introduces the primary subject matter clearly. '
            'Sentence number two elaborates with supporting details and empirical evidence. '
            'Sentence number three discusses the historical methodology and background. '
            'Sentence number four describes the contemporary technological landscape. '
            'Sentence number five provides analysis of emerging industry patterns. '
            'Sentence number six discusses various future research possibilities. '
            'Sentence number seven evaluates the overarching societal impact. '
            'Sentence number eight summarizes the essential findings and recommendations.';

        final summaryDefault = service.summarize(text, bulletCount: 5);
        expect(summaryDefault.length, inInclusiveRange(3, 5));

        final summaryThree = service.summarize(text, bulletCount: 2);
        expect(summaryThree.length, equals(3)); // clamped to minimum 3

        final summaryMax = service.summarize(text, bulletCount: 10);
        expect(summaryMax.length, equals(5)); // clamped to maximum 5
      });
    });

    test('Chronological ordering preserves original narrative sequence', () {
      final text =
          'Alpha introductory sentence explaining foundational concepts of computing. '
          'Beta second sentence expanding on algorithms and theoretical principles. '
          'Gamma third sentence describing hardware architectures and processor design. '
          'Delta fourth sentence presenting software engineering principles and practices. '
          'Epsilon fifth sentence detailing networking protocols and cloud infrastructures. '
          'Zeta sixth sentence discussing distributed database systems and scalability. '
          'Eta seventh sentence concluding with artificial intelligence applications.';

      final summary = service.summarize(text, bulletCount: 4);

      // Verify each selected sentence appears in the order of original occurrence
      final indices = summary.map((sentence) => text.indexOf(sentence)).toList();
      for (int i = 0; i < indices.length - 1; i++) {
        expect(indices[i], lessThan(indices[i + 1]),
            reason: 'Sentences must appear in original chronological text order');
      }
    });

    group('Very short and edge-case inputs', () {
      test('Returns empty list for empty or whitespace-only input', () {
        expect(service.summarize(''), isEmpty);
        expect(service.summarize('   \n\t  '), isEmpty);
      });

      test('Filters out sentence fragments shorter than 15 characters', () {
        final text = 'Hi. Ok. Yes. No. Fine.';
        expect(service.summarize(text), isEmpty);
      });

      test('Handles single valid sentence gracefully without crashing', () {
        final text = 'This is a single valid sentence that exceeds the minimum character threshold.';
        final summary = service.summarize(text);
        expect(summary.length, equals(1));
        expect(summary.first, equals(text));
      });
    });

    test('Text chunking splits text along sentence boundaries when exceeding max length', () {
      final sentenceA = 'This is sentence A with sufficient content to form a valid sentence block.';
      final sentenceB = 'This is sentence B providing further information in this demonstration paragraph.';
      final fullText = '$sentenceA $sentenceB';

      // Setting a small chunk limit to force splitting
      final chunks = service.chunkText(fullText, maxChunkLength: sentenceA.length + 5);
      expect(chunks.length, equals(2));
      expect(chunks[0], equals(sentenceA));
      expect(chunks[1], equals(sentenceB));
    });
  });

  group('SummarizerService — Gemini Integration & Fallback', () {
    test('Gemini failure triggers offline fallback with user notice', () async {
      final mockClient = MockGeminiClient(shouldFail: true);
      SharedPreferences.setMockInitialValues({
        AppConstants.keyUseAiSummarization: true,
      });
      final prefs = await SharedPreferences.getInstance();

      final service = SummarizerService(
        prefs: prefs,
        geminiClient: mockClient,
      );

      final text =
          'Renewable energy sources are becoming the dominant power choice. '
          'Solar power installations have increased significantly across global markets. '
          'Wind turbines generate substantial clean electricity on offshore coastal wind farms. '
          'Energy storage batteries are critical for grid balancing and reliability. '
          'Hydroelectric dams continue providing reliable baseload renewable energy.';

      final result = await service.summarizeAsync(text);

      expect(result.usedFallback, isTrue);
      expect(result.notice, equals(AppConstants.fallbackNotice));
      expect(result.bullets, isNotEmpty);
      // Bullets should match offline extractive summarizer
      expect(result.bullets, equals(service.summarize(text)));
    });

    test('Gemini success returns AI generated bullet points without fallback notice', () async {
      final mockClient = MockGeminiClient(
        responseText: '- First key insight from AI\n- Second crucial takeaway\n- Third synthesized point',
      );
      SharedPreferences.setMockInitialValues({
        AppConstants.keyUseAiSummarization: true,
      });
      final prefs = await SharedPreferences.getInstance();

      final service = SummarizerService(
        prefs: prefs,
        geminiClient: mockClient,
      );

      final text =
          'Artificial intelligence models process natural language with transformer architectures. '
          'These deep neural networks excel at summarization and generation tasks.';

      final result = await service.summarizeAsync(text);

      expect(result.usedFallback, isFalse);
      expect(result.notice, isNull);
      expect(result.bullets.length, equals(3));
      expect(result.bullets[0], equals('First key insight from AI'));
      expect(result.bullets[1], equals('Second crucial takeaway'));
      expect(result.bullets[2], equals('Third synthesized point'));
    });
  });

  group('SummarizerService — API Key Handling & Secure Storage', () {
    test('Stores and retrieves API key with FlutterSecureStorage', () async {
      FlutterSecureStorage.setMockInitialValues({
        AppConstants.keyGeminiApiKey: 'secret-secure-key-12345',
      });
      const secureStorage = FlutterSecureStorage();
      final service = SummarizerService(secureStorage: secureStorage);

      final key = await service.getApiKey();
      expect(key, equals('secret-secure-key-12345'));

      await service.saveApiKey('updated-secret-key-99999');
      final updatedKey = await service.getApiKey();
      expect(updatedKey, equals('updated-secret-key-99999'));
    });

    test('Migrates legacy unencrypted API key from SharedPreferences to FlutterSecureStorage', () async {
      FlutterSecureStorage.setMockInitialValues({});
      SharedPreferences.setMockInitialValues({
        AppConstants.keyGeminiApiKey: 'legacy-shared-prefs-key',
      });

      const secureStorage = FlutterSecureStorage();
      final prefs = await SharedPreferences.getInstance();
      final service = SummarizerService(prefs: prefs, secureStorage: secureStorage);

      // Retrieving the key should migrate it
      final key = await service.getApiKey();
      expect(key, equals('legacy-shared-prefs-key'));

      // SharedPreferences should no longer hold the key
      expect(prefs.containsKey(AppConstants.keyGeminiApiKey), isFalse);

      // Secure storage should now hold the key
      final secureKey = await secureStorage.read(key: AppConstants.keyGeminiApiKey);
      expect(secureKey, equals('legacy-shared-prefs-key'));
    });
  });
}

