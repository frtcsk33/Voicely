-- Update existing users table with missing columns
-- This script safely adds columns if they don't exist
-- Run this in your Supabase SQL editor

-- First, let's see the current structure
SELECT 
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
  AND table_name = 'users'
ORDER BY ordinal_position;

-- Add missing columns one by one (will only add if they don't exist)

-- Add subscription_plan column
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_name = 'users' AND column_name = 'subscription_plan') THEN
    ALTER TABLE public.users ADD COLUMN subscription_plan VARCHAR(50) DEFAULT 'free';
  END IF;
END $$;

-- Add subscription_expires_at column
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_name = 'users' AND column_name = 'subscription_expires_at') THEN
    ALTER TABLE public.users ADD COLUMN subscription_expires_at TIMESTAMPTZ;
  END IF;
END $$;

-- Add total_translations column
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_name = 'users' AND column_name = 'total_translations') THEN
    ALTER TABLE public.users ADD COLUMN total_translations INTEGER DEFAULT 0;
  END IF;
END $$;

-- Add daily_translations column
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_name = 'users' AND column_name = 'daily_translations') THEN
    ALTER TABLE public.users ADD COLUMN daily_translations INTEGER DEFAULT 0;
  END IF;
END $$;

-- Add last_daily_reset column
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_name = 'users' AND column_name = 'last_daily_reset') THEN
    ALTER TABLE public.users ADD COLUMN last_daily_reset TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP;
  END IF;
END $$;

-- Add preferred_language column
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_name = 'users' AND column_name = 'preferred_language') THEN
    ALTER TABLE public.users ADD COLUMN preferred_language VARCHAR(10) DEFAULT 'en';
  END IF;
END $$;

-- Add learning_languages column (array of text)
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_name = 'users' AND column_name = 'learning_languages') THEN
    ALTER TABLE public.users ADD COLUMN learning_languages TEXT[] DEFAULT '{}';
  END IF;
END $$;

-- Add streak_days column
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_name = 'users' AND column_name = 'streak_days') THEN
    ALTER TABLE public.users ADD COLUMN streak_days INTEGER DEFAULT 0;
  END IF;
END $$;

-- Add last_activity_at column
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_name = 'users' AND column_name = 'last_activity_at') THEN
    ALTER TABLE public.users ADD COLUMN last_activity_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP;
  END IF;
END $$;

-- Add is_active column
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_name = 'users' AND column_name = 'is_active') THEN
    ALTER TABLE public.users ADD COLUMN is_active BOOLEAN DEFAULT true;
  END IF;
END $$;

-- Add settings column (JSONB for flexible storage)
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_name = 'users' AND column_name = 'settings') THEN
    ALTER TABLE public.users ADD COLUMN settings JSONB DEFAULT '{}';
  END IF;
END $$;

-- Add constraints
DO $$
BEGIN
  -- Add subscription plan check constraint if it doesn't exist
  IF NOT EXISTS (SELECT 1 FROM information_schema.constraint_column_usage 
                 WHERE constraint_name = 'users_subscription_plan_check') THEN
    ALTER TABLE public.users ADD CONSTRAINT users_subscription_plan_check 
    CHECK (subscription_plan IN ('free', 'pro', 'premium'));
  END IF;
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

-- Create indexes for better performance (only if they don't exist)
CREATE INDEX IF NOT EXISTS idx_users_subscription ON public.users(subscription_plan);
CREATE INDEX IF NOT EXISTS idx_users_last_activity ON public.users(last_activity_at);

-- Enable Row Level Security if not already enabled
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- Create RLS policies (will only create if they don't exist)
DO $$
BEGIN
  -- Users can view their own profile
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Users can view own profile') THEN
    CREATE POLICY "Users can view own profile" 
    ON public.users FOR SELECT 
    TO authenticated 
    USING (auth.uid() = id);
  END IF;
  
  -- Users can update their own profile
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Users can update own profile') THEN
    CREATE POLICY "Users can update own profile" 
    ON public.users FOR UPDATE 
    TO authenticated 
    USING (auth.uid() = id);
  END IF;
  
  -- Users can insert their own profile
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Users can insert own profile') THEN
    CREATE POLICY "Users can insert own profile" 
    ON public.users FOR INSERT 
    TO authenticated 
    WITH CHECK (auth.uid() = id);
  END IF;
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

-- Create or replace function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_users_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger if it doesn't exist
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trigger_update_users_updated_at') THEN
    CREATE TRIGGER trigger_update_users_updated_at
      BEFORE UPDATE ON public.users
      FOR EACH ROW
      EXECUTE FUNCTION update_users_updated_at();
  END IF;
END $$;

-- Create function to handle daily reset of translation count
CREATE OR REPLACE FUNCTION reset_daily_translations()
RETURNS TRIGGER AS $$
BEGIN
  -- If last reset was before today, reset daily count
  IF DATE(NEW.last_daily_reset) < CURRENT_DATE THEN
    NEW.daily_translations = 0;
    NEW.last_daily_reset = CURRENT_TIMESTAMP;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for daily reset if it doesn't exist
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trigger_reset_daily_translations') THEN
    CREATE TRIGGER trigger_reset_daily_translations
      BEFORE UPDATE ON public.users
      FOR EACH ROW
      WHEN (OLD.daily_translations IS DISTINCT FROM NEW.daily_translations)
      EXECUTE FUNCTION reset_daily_translations();
  END IF;
END $$;

-- Update existing users to have default values for new columns
UPDATE public.users 
SET 
  subscription_plan = COALESCE(subscription_plan, 'free'),
  total_translations = COALESCE(total_translations, 0),
  daily_translations = COALESCE(daily_translations, 0),
  last_daily_reset = COALESCE(last_daily_reset, CURRENT_TIMESTAMP),
  preferred_language = COALESCE(preferred_language, 'en'),
  learning_languages = COALESCE(learning_languages, '{}'),
  streak_days = COALESCE(streak_days, 0),
  last_activity_at = COALESCE(last_activity_at, CURRENT_TIMESTAMP),
  is_active = COALESCE(is_active, true),
  settings = COALESCE(settings, '{}')
WHERE 
  subscription_plan IS NULL 
  OR total_translations IS NULL 
  OR daily_translations IS NULL 
  OR last_daily_reset IS NULL 
  OR preferred_language IS NULL 
  OR learning_languages IS NULL 
  OR streak_days IS NULL 
  OR last_activity_at IS NULL 
  OR is_active IS NULL 
  OR settings IS NULL;

-- Display final table structure
SELECT 
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
  AND table_name = 'users'
ORDER BY ordinal_position;

-- Show count of users
SELECT COUNT(*) as total_users FROM public.users;

COMMENT ON TABLE public.users IS 'Extended user profiles with app-specific data';
COMMENT ON COLUMN public.users.total_translations IS 'Total number of translations performed by user';
COMMENT ON COLUMN public.users.daily_translations IS 'Number of translations performed today';
COMMENT ON COLUMN public.users.learning_languages IS 'Array of language codes user is learning';
COMMENT ON COLUMN public.users.streak_days IS 'Number of consecutive days user has been active';