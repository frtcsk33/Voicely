# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Voicely is a Flutter voice translation app that supports multiple languages and features user authentication, translation history, and vocabulary learning. The app uses Supabase for backend services and supports both production and demo modes.

## Development Commands

### Core Flutter Commands
- **Run the app**: `flutter run`
- **Get dependencies**: `flutter pub get`
- **Analyze code**: `flutter analyze`
- **Format code**: `dart format .`
- **Run linter**: `flutter analyze --fatal-infos`

### Testing
- **Run tests**: `flutter test`
- **Run widget tests**: `flutter test test/widget_test.dart`

### Build Commands
- **Build APK**: `flutter build apk`
- **Build iOS**: `flutter build ios`
- **Build for web**: `flutter build web`

## Architecture

### State Management
- Uses **Provider pattern** for state management
- Main providers:
  - `TranslatorProvider`: Handles translation state and language selection
  - `AuthService`: Manages user authentication with Supabase
  - `UserService`: Manages user profile data and activity tracking
  - `BooksService`: Handles vocabulary books and categories

### Database Architecture
- **Supabase** backend with PostgreSQL database
- Key tables: users, categories, words, translation_history, user_favorites, learning_progress
- Row Level Security (RLS) enabled for all user data
- Database schema defined in `supabase_tables.sql`

### Core Services
- `SupabaseConfig` (`lib/services/supabase_client.dart`): Database configuration
- `AuthService` (`lib/services/auth_service.dart`): Authentication with demo mode fallback
- `UserService` (`lib/services/user_service.dart`): User profile management
- `BooksService` (`lib/services/books_service.dart`): Vocabulary management
- `TranslatorProvider` (`lib/providers/translator_provider.dart`): Translation logic

### Authentication System
- Extends Supabase Auth with custom user profiles
- Supports both production and demo modes
- User profiles automatically created via database triggers
- Translation limits enforced (50/day for free users, unlimited for pro)

### Multi-language Support
- Supports 40+ languages with proper locale handling
- Language selection stored in user preferences
- UI text localization through `TranslatorProvider.getLocalizedText()`

## Key Files and Directories

### Core Application
- `lib/main.dart`: App entry point with provider setup
- `lib/screens/`: UI screens (AI homepage, camera, books, settings, auth)
- `lib/widgets/`: Reusable UI components
- `lib/models/`: Data models (UserProfile, BookCategory, Word)

### Services Layer
- `lib/services/supabase_client.dart`: Database client configuration
- `lib/services/auth_service.dart`: Authentication service with demo mode
- `lib/services/user_service.dart`: User profile and activity management
- `lib/services/books_service.dart`: Vocabulary data management

### Database
- `supabase_tables.sql`: Complete database schema with RLS policies
- `update_users_table.sql`: Database migrations

## Development Guidelines

### Database Setup
1. Run `supabase_tables.sql` in Supabase SQL editor to create all tables
2. Update Supabase credentials in `lib/services/supabase_client.dart`
3. App automatically falls back to demo mode if Supabase unavailable

### Authentication Flow
- Registration creates both auth user and profile via database trigger
- Sign-in loads user profile automatically
- All user data protected by Row Level Security policies
- Demo mode provides mock authentication for development

### Translation System
- Uses LibreTranslate API (`https://libretranslate.de/translate`)
- Tracks daily translation limits per user
- Supports voice-to-text and text-to-speech functionality
- Translation history automatically saved for authenticated users

### Testing Strategy
- Widget tests in `test/widget_test.dart`
- Demo mode allows offline development and testing
- Authentication system works with mock data when Supabase unavailable

## Features

### Core Features
- Voice translation between 40+ languages
- Two-way conversation mode (Google Translate-style)
- Text-to-speech and speech-to-text
- OCR translation from camera images
- Translation history and favorites
- Vocabulary learning with books/categories
- User progress tracking with streak days

### Pro Features
- Unlimited translations (vs 50/day for free users)
- Advanced AI translation models
- Enhanced vocabulary learning features

### User Management
- Email/password authentication
- User profiles with preferences and learning languages
- Activity tracking and engagement metrics
- Subscription plan management (free/pro/premium)