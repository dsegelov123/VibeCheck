-- Enable pgvector extension
create extension if not exists vector;

-- Table for emotional snapshots
create table if not exists public.emotional_snapshots (
    id uuid primary key default gen_random_uuid(),
    created_at timestamp with time zone default timezone('utc'::text, now()),
    timestamp timestamp with time zone not null,
    mood text not null,
    transcript text,
    audio_url text,
    sentiment_scores jsonb,
    embedding vector(1536) -- Match OpenAI embedding size
);

-- Enable RLS
alter table public.emotional_snapshots enable row level security;

-- Policy: Users can only see their own data (assuming auth is setup)
-- create policy "Users can only access their own snapshots" 
-- on emotional_snapshots for all 
-- using (auth.uid() = user_id);
