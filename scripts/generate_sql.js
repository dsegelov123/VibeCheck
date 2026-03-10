/**
 * Converts sessions.json into a Supabase-ready SQL seed file.
 * Run: node generate_sql.js
 * Output: seed_sessions.sql — paste this into Supabase SQL Editor.
 */

import { readFileSync, writeFileSync } from 'fs';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

const __dir = dirname(fileURLToPath(import.meta.url));
const sessions = JSON.parse(readFileSync(join(__dir, 'sessions.json'), 'utf8'));

const escape = (str) => str ? str.replace(/'/g, "''") : '';

const lines = [];

lines.push(`-- VibeCheck: Meditation Sessions Seed`);
lines.push(`-- Generated: ${new Date().toISOString()}`);
lines.push(`-- Paste this entire file into: Supabase Dashboard → SQL Editor → Run`);
lines.push(``);
lines.push(`-- Step 1: Add the script column if it doesn't exist yet`);
lines.push(`ALTER TABLE meditation_sessions ADD COLUMN IF NOT EXISTS script TEXT;`);
lines.push(``);
lines.push(`-- Step 2: Insert all 24 sessions (upsert — safe to re-run)`);
lines.push(`INSERT INTO meditation_sessions`);
lines.push(`  (title, description, category, duration_minutes, colors, audio_url, image_url, script)`);
lines.push(`VALUES`);

const valueRows = sessions.map((s, i) => {
  // PostgreSQL array literal: ARRAY['#C5CAE9','#7986CB']
  const colors = `ARRAY[${s.colors.map(c => `'${c}'`).join(',')}]`;
  const comma = i < sessions.length - 1 ? ',' : '';
  return `  ('${escape(s.title)}', '${escape(s.description)}', '${escape(s.category)}', ${s.duration_minutes}, ${colors}, '', '', '${escape(s.script)}')${comma}`;
});

lines.push(...valueRows);
lines.push(`ON CONFLICT DO NOTHING;`);
lines.push(``);
lines.push(`-- Verify: run this after inserting to confirm 24 rows`);
lines.push(`SELECT category, COUNT(*) as count FROM meditation_sessions GROUP BY category ORDER BY category;`);

const sql = lines.join('\n');
const outPath = join(__dir, 'seed_sessions.sql');
writeFileSync(outPath, sql, 'utf8');

console.log(`\n✅  SQL file written to: ${outPath}`);
console.log(`📋  Instructions:`);
console.log(`    1. Open https://supabase.com → your project → SQL Editor`);
console.log(`    2. Click "New Query"`);
console.log(`    3. Paste the contents of seed_sessions.sql`);
console.log(`    4. Click "Run"\n`);
