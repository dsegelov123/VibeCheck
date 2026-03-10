/**
 * VibeCheck Supabase Seeder
 * =========================
 * Imports sessions.json into the Supabase 'meditation_sessions' table.
 * Run: node seed_supabase.js
 */

import { readFileSync } from 'fs';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';
import fetch from 'node-fetch';

const SUPABASE_URL = 'https://ifvmtbtnybrmkoaazfto.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imlmdm10YnRueWJybWtvYWF6ZnRvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzMwNzExNjksImV4cCI6MjA4ODY0NzE2OX0.-m613mRExKVAq2-GOVfiJWx5JMVU8wltWGBU4fX88WU';

const __dir = dirname(fileURLToPath(import.meta.url));
const sessions = JSON.parse(readFileSync(join(__dir, 'sessions.json'), 'utf8'));

// Strip the `script` field — Supabase only stores metadata.
// The full scripts (including text) remain in sessions.json (bundled as a Flutter asset).
const supabaseSessions = sessions.map(({ script, id, ...rest }) => ({
  ...rest,
  audio_url: rest.audio_url ?? '',
  image_url: rest.image_url ?? '',
}));

async function seed() {
  console.log(`\n🚀 Seeding ${supabaseSessions.length} sessions into Supabase...\n`);

  // Upsert in batches of 5 to avoid rate limits
  const BATCH_SIZE = 5;
  let successCount = 0;

  for (let i = 0; i < supabaseSessions.length; i += BATCH_SIZE) {
    const batch = supabaseSessions.slice(i, i + BATCH_SIZE);
    const batchLabels = batch.map(s => s.title).join(', ');
    process.stdout.write(`  Batch ${Math.floor(i / BATCH_SIZE) + 1}: ${batchLabels.substring(0, 80)}... `);

    const response = await fetch(`${SUPABASE_URL}/rest/v1/meditation_sessions`, {
      method: 'POST',
      headers: {
        'apikey': SUPABASE_ANON_KEY,
        'Authorization': `Bearer ${SUPABASE_ANON_KEY}`,
        'Content-Type': 'application/json',
        'Prefer': 'resolution=merge-duplicates',
      },
      body: JSON.stringify(batch),
    });

    if (response.ok || response.status === 201) {
      console.log('✅');
      successCount += batch.length;
    } else {
      const err = await response.text();
      console.log(`❌  (HTTP ${response.status}): ${err.substring(0, 200)}`);
    }

    await new Promise(r => setTimeout(r, 200));
  }

  console.log(`\n✨  Done! ${successCount}/${supabaseSessions.length} sessions seeded into Supabase.\n`);
}

seed().catch(err => {
  console.error('\n❌  Fatal error:', err.message);
  process.exit(1);
});
