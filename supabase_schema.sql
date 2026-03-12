-- Enable pgvector extension
create extension if not exists vector;

-- Table for emotional snapshots
create table if not exists public.emotional_snapshots (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) NOT NULL,
  timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  mood TEXT NOT NULL,
  transcript TEXT,
  sentiment_scores JSONB,
  companion_response TEXT,
  embedding vector(1536), -- Match OpenAI embedding size
  is_journal_entry BOOLEAN DEFAULT FALSE,
  journal_title_summary TEXT,
  journal_long_summary TEXT,
  mood_distribution JSONB DEFAULT '{}'::jsonb
);

-- Enable RLS
alter table public.emotional_snapshots enable row level security;

-- Policy: Users can only see their own data (assuming auth is setup)
-- create policy "Users can only access their own snapshots" 
-- on emotional_snapshots for all 
-- using (auth.uid() = user_id);
