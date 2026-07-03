# SummarizIt

SummarizIt is a feature-rich, high-performance Flutter application designed to extract and generate clean, structured bullet-point summaries from long texts, document images, and files. By combining **offline, frequency-based extractive algorithms** with **advanced Generative AI (Google Gemini)**, SummarizIt offers a dual-mode hybrid architecture tailored for both low-connectivity utility and high-intelligence synthesis.

---

## 🚀 Key Features

| Feature | Description | Engine / Packages | Offline |
| :--- | :--- | :--- | :---: |
| **Offline Extractive Summarization** | Instantly extracts key sentences by scoring term frequency-inverse sentence length. | Local Dart Engine | Yes |
| **Generative AI Summarization** | Produces natural-language, context-aware abstractive summaries using Google's Gemini models. | `google_generative_ai` | No |
| **Document Scanning (OCR)** | Take photos or upload images to scan and extract printed text. | `google_mlkit_text_recognition`, `image_picker` | Yes |
| **Text File Import** | Select and import contents of plain text `.txt` files directly into the editor. | `file_picker` | Yes |
| **Microsoft Word Export** | Shares summaries as custom-packaged, standard Microsoft Word `.docx` documents. | `archive` (Zip Open XML) | Yes |
| **Adaptive Styling** | Dark & Light glassmorphic design featuring custom smooth gradient animations. | `google_fonts` (Outfit) | Yes |

---

## 📂 Project Architecture

The codebase follows clean architecture principles, separating user interface layers, custom UI components, application logic services, and design styles:

```text
lib/
├── main.dart                          # App entry point & global ThemeData configurations
├── screens/
│   └── home_screen.dart               # Core viewport UI, input forms, setting controllers & custom animations
├── services/
│   ├── document_scanner_service.dart     # Camera/Gallery image picker and Google ML Kit OCR service
│   ├── file_export_service.dart          # Assembler for Plain Text and Open XML (.docx) export packages
│   └── summarizer_service.dart        # Hybrid engine (Local extractive summarizer & Gemini API adapter)
├── theme/
│   └── theme_provider.dart            # Centralized ThemeMode listeners, palettes, and dynamic colour mappings
├── utils/
│   └── constants.dart                 # App-wide static configuration values
└── widgets/
    ├── gradient_button.dart           # Custom, interactive gradient button with tactile micro-interactions
    └── summary_card.dart              # Container widget featuring animated entrants for bullet summaries
```

---

## 🧠 Technical Mechanics

### 1. Offline Extractive Summarization Algorithm
When operating offline or when AI is disabled, the system scores and extracts sentences using a word-frequency-based ranking:
* **Tokenization:** Splits input text into sentences using regex boundary lookbehinds (`(?<=[.!?])\s+`) and filters out short sentence fragments (less than 15 characters).
* **Stopword Removal:** Eliminates common English stopwords (e.g., *the*, *and*, *because*, *myself*) to avoid scoring functional grammar.
* **Word Frequency Mapping:** Tracks raw frequencies of remaining words, normalizing them by the highest frequency in the document:
  $$\text{Normalized Frequency}(w) = \frac{\text{Frequency}(w)}{\text{Max Frequency}}$$
* **Sentence Scoring:** Scores each sentence by summing the normalized frequencies of its constituent words, then divides by the word count of the sentence to eliminate bias toward longer sentences:
  $$\text{Score}(S) = \frac{\sum_{w \in S} \text{Normalized Frequency}(w)}{\text{Word Count}(S)}$$
* **Ordering:** Extracts the top $N$ highest-scoring sentences (dynamically bounded between 3 and 5 based on document length) and preserves their original chronological ordering to retain narrative flow.

### 2. Generative AI Engine (Gemini)
When AI is configured and enabled, SummarizIt connects to the `gemini-1.5-flash` model:
* Sends a structured instruction to output exactly $N$ bullet points starting with a hyphen.
* Falls back gracefully to the offline extractive summarizer if the API call fails or encounters invalid keys.

### 3. Open XML (.docx) Generation
To export summaries to Microsoft Word without external heavy native libraries, the app compiles the paragraphs into standard Office Open XML (OOXML) documents in memory:
1. Generates core document specifications (`document.xml`), relationships (`document.xml.rels`), numbering rules (`numbering.xml`), and content declarations (`[Content_Types].xml`).
2. Wraps and compresses the output directory structure into a standard ZIP folder using the Dart `archive` package.
3. Automatically triggers native platform share dialogs to save or send the generated binary document.

---

## ⚙️ Getting Started

### Prerequisites
* [Flutter SDK](https://docs.flutter.dev/get-started/install) (`^3.11.0` or higher)
* [Dart SDK](https://dart.dev/get-started) (`^3.0.0` or higher)
* A mobile device or emulator (necessary for OCR/ML Kit support; OCR does not run on web environments)

### Installation & Run
1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/summarizit.git
   cd summarizit
   ```
2. Pull application dependencies:
   ```bash
   flutter pub get
   ```
3. Run the project in development mode:
   ```bash
   flutter run
   ```

### Configuring Generative AI (Gemini)
1. Generate an API Key in the [Google AI Studio](https://aistudio.google.com/app/apikey).
2. Launch the app and tap the **Settings (Gear) icon** in the top-right corner.
3. Enable the **Use AI Summarization** toggle.
4. Input your Gemini API key and tap **Save**. The configuration is securely persisted offline using SharedPreferences.

---

## 🧪 Testing

The codebase includes widget testing to verify building and core dependencies. Run tests via the command line:

```bash
flutter test
```

To run a static analysis check and ensure proper formatting compliance:

```bash
flutter analyze
```

---

## 🤝 Contributing

Contributions are welcome! Please follow these guidelines:
1. Fork the repository.
2. Create your feature branch (`git checkout -b feature/AmazingFeature`).
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`).
4. Ensure all unit and widget tests pass.
5. Push to the branch (`git push origin feature/AmazingFeature`).
6. Open a Pull Request.

