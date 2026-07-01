# SummarizIt

SummarizIt is a Flutter application that provides instant, AI-powered summaries of your texts. You can paste long articles or upload text files and images (OCR) to get concise bullet points.

## Features
- **Extractive Summarization:** A built-in summarization engine that extracts key sentences based on word frequency.
- **Generative AI Summarization (Gemini):** Get human-like, abstractive summaries by integrating Google's Gemini API.
- **File Upload & OCR:** Upload a `.txt` file or snap a picture of a document to extract and summarize text.
- **Export Options:** Download your summaries as `.txt` or `.docx` files.
- **Dark & Light Mode:** Toggle between themes effortlessly.

## Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (Ensure you are using `^3.11.0` or higher based on `pubspec.yaml` environment bounds).
- A [Google Gemini API Key](https://aistudio.google.com/app/apikey) (Optional, for advanced AI summarization).

### Installation
1. Clone the repository:
   ```bash
   git clone <repository_url>
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

### Using AI Summarization (Gemini)
To enable the Generative AI features:
1. Tap the **Settings icon** (gear) located in the top-right corner of the home screen, next to the theme toggle.
2. Toggle **Use AI Summarization**.
3. Enter your Gemini API Key in the provided text field.
4. Tap **Save**.
5. When you click **Summarize**, the app will securely call the Gemini API instead of the local summarization engine.

### Using OCR & File Upload
- **Image/OCR:** Tap the image icon inside the text input box to upload an image from your gallery. The app will use Google ML Kit to extract the text. (Note: OCR is currently primarily supported on mobile environments).
- **Text File Upload:** Tap the file upload icon inside the text input box to select and load a `.txt` file into the editor.

## Contributing
Contributions are welcome! Please ensure any new code follows Flutter linting rules by running:
```bash
flutter analyze
```
