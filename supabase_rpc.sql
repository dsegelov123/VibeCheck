-- Enable pgvector extension
create extension if not exists vector;

-- Ensure the embedding column exists (in case the table was created without it earlier)
alter table public.emotional_snapshots add column if not exists embedding vector(1536);

-- Create the matching function for Vector similarity search in Supabase
create or replace function match_snapshots (
  query_embedding vector(1536),
  match_threshold float,
  match_count int
)
returns table (
  id text,
  mood text,
  transcript text,
  companion_response text,
  similarity float
)
language sql stable
as $$
  select
    emotional_snapshots.id,
    emotional_snapshots.mood,
    emotional_snapshots.transcript,
    emotional_snapshots."companionResponse" as companion_response,
    1 - (emotional_snapshots.embedding <=> query_embedding) as similarity
  from emotional_snapshots
  where 1 - (emotional_snapshots.embedding <=> query_embedding) > match_threshold
    and emotional_snapshots.transcript is not null
  order by similarity desc
  limit match_count;
$$;
