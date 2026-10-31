# SummarizIt

SummarizIt is a Flutter application that summarizes text from direct input, imported text files, or scanned document images. It uses a hybrid approach: an on-device extractive summarizer for offline operation and the Google Gemini API for abstractive, bullet-point generation when online.

---

## How the Hybrid Summarizer Works

SummarizIt offers two summarization modes depending on user settings and network availability:

1. **Offline Extractive Summarization (On-Device)**
   - **Tokenization:** Breaks the input text into sentences using punctuation boundaries (`.`, `!`, `?`) and filters out fragments shorter than 15 characters.
   - **Stopword Removal:** Filters out common English functional words (e.g., *the*, *and*, *because*, *with*) to isolate content keywords.
   - **Frequency Scoring:** Builds a normalized word frequency table. Each sentence is scored by summing the normalized frequencies of its constituent words divided by its word count, preventing bias toward overly long sentences.
   - **Chronological Ordering & Bounding:** Dynamically selects between 3 and 5 top-scoring sentences (depending on document length) and sorts them back into their original narrative order.

2. **Generative AI Summarization (Google Gemini)**
   - When enabled, the app sends prompts to Google's official `gemini-3.8-flash` model requesting concise, hyphen-prefixed bullet points.
   - API keys are stored in encrypted device storage (`flutter_secure_storage`) rather than plaintext preferences, and requests have a 30-second timeout.

3. **Handling Long Inputs (Map-Reduce Chunking)**
   - When text exceeds the single-request threshold (4,000 characters), the app splits the document along sentence boundaries into chunks.
   - **Map Phase:** Each chunk is summarized individually into intermediate key points.
   - **Reduce Phase:** All intermediate summaries are combined and submitted in a final prompt to synthesize the requested number of cohesive bullet points.

4. **Fallback and Failure Transparency**
   - If the Gemini request fails, times out, or encounters network issues, the service automatically falls back to the on-device extractive summarizer.
   - Unlike silent fallbacks, the UI immediately alerts the user with a notification (`AI unavailable, used offline summary`) so errors are never hidden.

---

## Platform Support

| Feature | Android | iOS | Web | Desktop (macOS / Linux / Windows) |
| :--- | :---: | :---: | :---: | :---: |
| **Offline Extractive Summarizer** | Yes | Yes | Yes | Yes |
| **Gemini AI Summarizer** | Yes | Yes | Yes | Yes |
| **Text File Import (`.txt`)** | Yes | Yes | Yes | Yes |
| **Word Export (`.docx`) & Sharing** | Yes | Yes | Partial (Download) | Yes |
| **Document Scanning (OCR)** | Yes | Yes | **No** (ML Kit requires Android/iOS) | No |
| **Secure API Key Storage** | Yes (Keystore) | Yes (Keychain) | Yes (Web Storage) | Yes (Keyring / Credential Manager) |

---

## Limitations

- **OCR Environment:** Document scanning and optical character recognition rely on Google ML Kit, which is restricted to mobile platforms (Android and iOS). It is not supported on web or desktop.
- **Language Optimization:** The offline extractive engine's stopword dictionary is currently tailored to English text. Non-English text will be scored on raw word frequencies without stopword filtering.
- **Extractive Nature of Offline Engine:** Offline summaries select existing sentences verbatim from the document rather than paraphrasing or synthesizing new sentences.
- **Network Dependency for AI:** Generative summaries require an active internet connection and a valid Google Gemini API key.

---

## Project Architecture

The project uses a layered directory structure separating screens, background services, UI widgets, and utilities:

```text
lib/
├── main.dart                          # Application entry point & theme initialization
├── screens/
│   └── home_screen.dart               # Main UI view: text editor, action triggers, settings modal
├── services/
│   ├── document_scanner_service.dart  # Camera/Gallery image picker and ML Kit OCR wrapper
│   ├── file_export_service.dart       # Formats and packages Plain Text and DOCX (ZIP Open XML) files
│   └── summarizer_service.dart        # Hybrid engine: offline scoring, Gemini client, chunking & fallback
├── theme/
│   └── theme_provider.dart            # Light and dark theme palettes and ThemeMode management
├── utils/
│   └── constants.dart                 # Centralized constants: model name, timeouts, storage keys, prompts
└── widgets/
    ├── gradient_button.dart           # Custom action button with tactile press feedback
    └── summary_card.dart              # Animated summary display card with copy and export controls
```

---

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`^3.11.0` or higher)
- [Dart SDK](https://dart.dev/get-started) (`^3.0.0` or higher)
- Android Studio / Xcode (for mobile development and camera/OCR testing)

### Installation & Run

1. Clone the repository:
   ```bash
   git clone https://github.com/Ashwin-R05/summarizit.git
   cd summarizit
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the application:
   ```bash
   flutter run
   ```

### Configuring the Gemini API Key

1. Obtain a free API key from [Google AI Studio](https://aistudio.google.com/app/apikey).
2. In SummarizIt, open the **Settings** dialog via the gear icon in the top app bar.
3. Toggle **Use AI Summarization** on.
4. Paste your Gemini API key and tap **Save**. The key is stored in hardware-backed secure storage via `flutter_secure_storage`.

---

## Testing & CI

Unit and widget tests cover the extractive summarization engine, stopword filtering, scoring bounds, chronological order, long text chunking, Gemini mock fallback, and DOCX ZIP package generation:

```bash
# Run unit and widget tests
flutter test

# Run static analysis
flutter analyze
```

A continuous integration pipeline is configured via GitHub Actions (`.github/workflows/dart.yml`) to automatically run `flutter analyze` and `flutter test` on every push and pull request.
