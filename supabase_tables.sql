-- Supabase Tables for Voicely App
-- This file contains all the necessary tables for the translation app

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ========================================
-- USERS TABLE (extends Supabase auth.users)
-- ========================================
CREATE TABLE IF NOT EXISTS public.users (
  id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  full_name TEXT,
  avatar_url TEXT,
  is_pro BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  last_login_at TIMESTAMP WITH TIME ZONE,
  preferences JSONB DEFAULT '{}'::jsonb
);

-- ========================================
-- CATEGORIES TABLE (for Books feature)
-- ========================================
CREATE TABLE IF NOT EXISTS public.categories (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  name TEXT NOT NULL,
  name_tr TEXT,
  name_fr TEXT,
  name_es TEXT,
  name_de TEXT,
  name_ar TEXT,
  description TEXT,
  icon TEXT DEFAULT 'book',
  color TEXT DEFAULT '#3B82F6',
  word_count INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT TRUE,
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ========================================
-- WORDS TABLE (for Books feature)
-- ========================================
CREATE TABLE IF NOT EXISTS public.words (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  category_id UUID REFERENCES public.categories(id) ON DELETE CASCADE,
  word TEXT NOT NULL,
  translation TEXT NOT NULL,
  phonetic TEXT,
  audio_url TEXT,
  example_sentence TEXT,
  difficulty_level INTEGER DEFAULT 1, -- 1: Easy, 2: Medium, 3: Hard
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ========================================
-- USER FAVORITES TABLE (for user's favorite words)
-- ========================================
CREATE TABLE IF NOT EXISTS public.user_favorites (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
  word_id UUID REFERENCES public.words(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, word_id)
);

-- ========================================
-- LEARNING PROGRESS TABLE (for tracking user progress)
-- ========================================
CREATE TABLE IF NOT EXISTS public.learning_progress (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
  word_id UUID REFERENCES public.words(id) ON DELETE CASCADE,
  category_id UUID REFERENCES public.categories(id) ON DELETE CASCADE,
  mastery_level INTEGER DEFAULT 0, -- 0: Not learned, 1: Familiar, 2: Known, 3: Mastered
  review_count INTEGER DEFAULT 0,
  last_reviewed_at TIMESTAMP WITH TIME ZONE,
  next_review_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, word_id)
);

-- ========================================
-- TRANSLATION HISTORY TABLE (for user's translation history)
-- ========================================
CREATE TABLE IF NOT EXISTS public.translation_history (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
  source_text TEXT NOT NULL,
  translated_text TEXT NOT NULL,
  source_language TEXT NOT NULL,
  target_language TEXT NOT NULL,
  translation_model TEXT DEFAULT 'standard', -- 'standard', 'ai_pro'
  is_favorite BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ========================================
-- USER FAVORITE TRANSLATIONS TABLE (for user's favorite translations)
-- ========================================
CREATE TABLE IF NOT EXISTS public.user_favorite_translations (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
  translation_history_id UUID REFERENCES public.translation_history(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, translation_history_id)
);

-- ========================================
-- INDEXES FOR PERFORMANCE
-- ========================================
CREATE INDEX IF NOT EXISTS idx_users_email ON public.users(email);
CREATE INDEX IF NOT EXISTS idx_words_category_id ON public.words(category_id);
CREATE INDEX IF NOT EXISTS idx_words_active ON public.words(is_active);
CREATE INDEX IF NOT EXISTS idx_user_favorites_user_id ON public.user_favorites(user_id);
CREATE INDEX IF NOT EXISTS idx_user_favorites_word_id ON public.user_favorites(word_id);
CREATE INDEX IF NOT EXISTS idx_learning_progress_user_id ON public.learning_progress(user_id);
CREATE INDEX IF NOT EXISTS idx_learning_progress_word_id ON public.learning_progress(word_id);
CREATE INDEX IF NOT EXISTS idx_learning_progress_category_id ON public.learning_progress(category_id);
CREATE INDEX IF NOT EXISTS idx_translation_history_user_id ON public.translation_history(user_id);
CREATE INDEX IF NOT EXISTS idx_translation_history_created_at ON public.translation_history(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_user_favorite_translations_user_id ON public.user_favorite_translations(user_id);

-- ========================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ========================================

-- Enable RLS on all tables
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.words ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_favorites ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.learning_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.translation_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_favorite_translations ENABLE ROW LEVEL SECURITY;

-- Users table policies
CREATE POLICY "Users can view own profile" ON public.users
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON public.users
  FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON public.users
  FOR INSERT WITH CHECK (auth.uid() = id);

-- Categories table policies (read-only for all authenticated users)
CREATE POLICY "Authenticated users can view categories" ON public.categories
  FOR SELECT USING (auth.role() = 'authenticated');

-- Words table policies (read-only for all authenticated users)
CREATE POLICY "Authenticated users can view words" ON public.words
  FOR SELECT USING (auth.role() = 'authenticated');

-- User favorites table policies
CREATE POLICY "Users can manage own favorites" ON public.user_favorites
  FOR ALL USING (auth.uid() = user_id);

-- Learning progress table policies
CREATE POLICY "Users can manage own learning progress" ON public.learning_progress
  FOR ALL USING (auth.uid() = user_id);

-- Translation history table policies
CREATE POLICY "Users can manage own translation history" ON public.translation_history
  FOR ALL USING (auth.uid() = user_id);

-- User favorite translations table policies
CREATE POLICY "Users can manage own favorite translations" ON public.user_favorite_translations
  FOR ALL USING (auth.uid() = user_id);

-- ========================================
-- TRIGGERS FOR AUTOMATIC UPDATES
-- ========================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply triggers to tables with updated_at
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON public.users
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_categories_updated_at BEFORE UPDATE ON public.categories
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_words_updated_at BEFORE UPDATE ON public.words
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_learning_progress_updated_at BEFORE UPDATE ON public.learning_progress
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Function to update word count in categories
CREATE OR REPLACE FUNCTION update_category_word_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE public.categories 
    SET word_count = word_count + 1 
    WHERE id = NEW.category_id;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE public.categories 
    SET word_count = word_count - 1 
    WHERE id = OLD.category_id;
    RETURN OLD;
  END IF;
  RETURN NULL;
END;
$$ language 'plpgsql';

-- Apply trigger to words table
CREATE TRIGGER update_category_word_count_trigger
  AFTER INSERT OR DELETE ON public.words
  FOR EACH ROW EXECUTE FUNCTION update_category_word_count();

-- ========================================
-- SAMPLE DATA
-- ========================================

-- Insert sample categories
INSERT INTO public.categories (id, name, name_tr, name_fr, name_es, name_de, name_ar, description, icon, color, sort_order) VALUES
  (uuid_generate_v4(), 'Expressions', 'İfadeler', 'Expressions', 'Expresiones', 'Ausdrücke', 'التعبيرات', 'Common expressions and phrases', 'chat', '#10B981', 1),
  (uuid_generate_v4(), 'Verbs', 'Fiiller', 'Verbes', 'Verbos', 'Verben', 'الأفعال', 'Essential verbs and conjugations', 'flash_on', '#F59E0B', 2),
  (uuid_generate_v4(), 'Basic', 'Temel', 'Basique', 'Básico', 'Grundlegend', 'أساسي', 'Basic vocabulary and greetings', 'school', '#3B82F6', 3),
  (uuid_generate_v4(), 'Culture', 'Kültür', 'Culture', 'Cultura', 'Kultur', 'الثقافة', 'Cultural terms and customs', 'celebration', '#8B5CF6', 4),
  (uuid_generate_v4(), 'Travel', 'Seyahat', 'Voyage', 'Viaje', 'Reise', 'السفر', 'Travel-related vocabulary', 'flight', '#EF4444', 5),
  (uuid_generate_v4(), 'Technical', 'Teknik', 'Technique', 'Técnico', 'Technisch', 'تقني', 'Technical and professional terms', 'computer', '#6B7280', 6),
  (uuid_generate_v4(), 'Objects', 'Nesneler', 'Objets', 'Objetos', 'Objekte', 'الأشياء', 'Common objects and items', 'inventory', '#84CC16', 7)
ON CONFLICT DO NOTHING;

-- Insert sample words for Expressions category
INSERT INTO public.words (category_id, word, translation, phonetic, example_sentence) 
SELECT 
  c.id,
  'Hello',
  'Merhaba',
  'mɛrˈhaba',
  'Hello, how are you today?'
FROM public.categories c WHERE c.name = 'Expressions'
UNION ALL
SELECT 
  c.id,
  'Good morning',
  'Günaydın',
  'ɡynajˈdɯn',
  'Good morning, have a great day!'
FROM public.categories c WHERE c.name = 'Expressions'
UNION ALL
SELECT 
  c.id,
  'Thank you',
  'Teşekkür ederim',
  'teʃɛkˈkyr ɛdɛˈrim',
  'Thank you for your help.'
FROM public.categories c WHERE c.name = 'Expressions'
UNION ALL
SELECT 
  c.id,
  'You are welcome',
  'Rica ederim',
  'riˈdʒa ɛdɛˈrim',
  'You are welcome, it was my pleasure.'
FROM public.categories c WHERE c.name = 'Expressions'
UNION ALL
SELECT 
  c.id,
  'How are you?',
  'Nasılsın?',
  'naˈsɯlsɯn',
  'How are you doing today?'
FROM public.categories c WHERE c.name = 'Expressions';

-- Insert sample words for Verbs category
INSERT INTO public.words (category_id, word, translation, phonetic, example_sentence) 
SELECT 
  c.id,
  'To be',
  'Olmak',
  'olˈmak',
  'I want to be a teacher.'
FROM public.categories c WHERE c.name = 'Verbs'
UNION ALL
SELECT 
  c.id,
  'To have',
  'Sahip olmak',
  'saˈhip olˈmak',
  'I have a car.'
FROM public.categories c WHERE c.name = 'Verbs'
UNION ALL
SELECT 
  c.id,
  'To go',
  'Gitmek',
  'ɡitˈmɛk',
  'I go to school every day.'
FROM public.categories c WHERE c.name = 'Verbs'
UNION ALL
SELECT 
  c.id,
  'To come',
  'Gelmek',
  'ɡɛlˈmɛk',
  'Please come to the meeting.'
FROM public.categories c WHERE c.name = 'Verbs'
UNION ALL
SELECT 
  c.id,
  'To do',
  'Yapmak',
  'japˈmak',
  'What are you doing?'
FROM public.categories c WHERE c.name = 'Verbs';

-- Insert sample words for Basic category
INSERT INTO public.words (category_id, word, translation, phonetic, example_sentence) 
SELECT 
  c.id,
  'Yes',
  'Evet',
  'ɛˈvɛt',
  'Yes, I agree with you.'
FROM public.categories c WHERE c.name = 'Basic'
UNION ALL
SELECT 
  c.id,
  'No',
  'Hayır',
  'haˈjɯr',
  'No, I do not want to go.'
FROM public.categories c WHERE c.name = 'Basic'
UNION ALL
SELECT 
  c.id,
  'Please',
  'Lütfen',
  'lytˈfɛn',
  'Please help me.'
FROM public.categories c WHERE c.name = 'Basic'
UNION ALL
SELECT 
  c.id,
  'Sorry',
  'Özür dilerim',
  'øˈzyr diˈlɛrim',
  'Sorry for being late.'
FROM public.categories c WHERE c.name = 'Basic'
UNION ALL
SELECT 
  c.id,
  'Excuse me',
  'Affedersiniz',
  'afːɛdɛrˈsiniz',
  'Excuse me, where is the bathroom?'
FROM public.categories c WHERE c.name = 'Basic';

-- ========================================
-- FUNCTIONS FOR API
-- ========================================

-- Function to get user's favorite words
CREATE OR REPLACE FUNCTION get_user_favorites(user_uuid UUID)
RETURNS TABLE (
  word_id UUID,
  word TEXT,
  translation TEXT,
  phonetic TEXT,
  category_name TEXT,
  created_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    w.id,
    w.word,
    w.translation,
    w.phonetic,
    c.name as category_name,
    uf.created_at
  FROM public.user_favorites uf
  JOIN public.words w ON uf.word_id = w.id
  JOIN public.categories c ON w.category_id = c.id
  WHERE uf.user_id = user_uuid
  ORDER BY uf.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get user's translation history
CREATE OR REPLACE FUNCTION get_user_translation_history(user_uuid UUID, limit_count INTEGER DEFAULT 50)
RETURNS TABLE (
  id UUID,
  source_text TEXT,
  translated_text TEXT,
  source_language TEXT,
  target_language TEXT,
  translation_model TEXT,
  is_favorite BOOLEAN,
  created_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    th.id,
    th.source_text,
    th.translated_text,
    th.source_language,
    th.target_language,
    th.translation_model,
    th.is_favorite,
    th.created_at
  FROM public.translation_history th
  WHERE th.user_id = user_uuid
  ORDER BY th.created_at DESC
  LIMIT limit_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get user's learning progress
CREATE OR REPLACE FUNCTION get_user_learning_progress(user_uuid UUID)
RETURNS TABLE (
  word_id UUID,
  word TEXT,
  translation TEXT,
  category_name TEXT,
  mastery_level INTEGER,
  review_count INTEGER,
  last_reviewed_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    lp.word_id,
    w.word,
    w.translation,
    c.name as category_name,
    lp.mastery_level,
    lp.review_count,
    lp.last_reviewed_at
  FROM public.learning_progress lp
  JOIN public.words w ON lp.word_id = w.id
  JOIN public.categories c ON w.category_id = c.id
  WHERE lp.user_id = user_uuid
  ORDER BY lp.mastery_level DESC, lp.last_reviewed_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
