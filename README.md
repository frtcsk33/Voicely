# Voicely - Flutter Voice Translator

A Flutter application that provides voice translation capabilities. This app allows users to speak in one language and get real-time translation to another language.

## Features

- **Voice Recognition**: Speak in your native language and have it transcribed
- **Text Translation**: Translate text between multiple languages
- **Text-to-Speech**: Listen to translations in the target language
- **Multiple Languages**: Support for English, Turkish, German, and French
- **Modern UI**: Clean and intuitive Material Design interface

## Supported Languages

- English (en)
- Turkish (tr)
- German (de)
- French (fr)

## Getting Started

### Prerequisites

- Flutter SDK (>=3.0.0)
- Dart SDK
- Android Studio / Xcode for mobile development

### Installation

1. Clone the repository
2. Navigate to the project directory
3. Install dependencies:
   ```bash
   flutter pub get
   ```

### Running the App

For Android:
```bash
flutter run
```

For iOS:
```bash
flutter run
```

## Dependencies

- `speech_to_text`: For voice recognition
- `flutter_tts`: For text-to-speech functionality
- `http`: For API calls to translation service
- `provider`: For state management

## Permissions

The app requires the following permissions:
- **Microphone**: For voice recognition
- **Internet**: For translation API calls
- **Speech Recognition**: For voice input processing

## Architecture

The app follows a clean architecture pattern with:
- **Provider Pattern**: For state management
- **Separation of Concerns**: UI, business logic, and data layers are separated
- **Material Design**: Modern and accessible UI components

## Translation API

The app uses LibreTranslate API for translation services. The API endpoint is:
`https://libretranslate.de/translate`

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## License

This project is licensed under the MIT License. 