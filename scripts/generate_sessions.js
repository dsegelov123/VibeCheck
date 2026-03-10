/**
 * VibeCheck Mindfulness Content Factory
 * ======================================
 * Generates guided meditation scripts for all 12 categories using GPT-4o.
 *
 * SETUP:
 *   1. Run: npm install in this directory (or `npm install node-fetch dotenv`)
 *   2. Create a `.env` file next to this script with: OPENAI_API_KEY=sk-...
 *   3. Run: node generate_sessions.js
 *
 * OUTPUT: sessions.json — ready to import into Supabase.
 */

import { readFileSync, writeFileSync } from 'fs';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';
import dotenv from 'dotenv';
import fetch from 'node-fetch';

dotenv.config({ path: join(dirname(fileURLToPath(import.meta.url)), '.env') });

const API_KEY = process.env.OPENAI_API_KEY;
if (!API_KEY || API_KEY.length < 20) {
  console.error('❌  OPENAI_API_KEY not found. Create a .env file next to this script.');
  process.exit(1);
}

// ─── Category Foundations ────────────────────────────────────────────────────

const CATEGORIES = [
  {
    name: 'Sleep',
    emoji: '😴',
    goal: 'Dissolve the mental chatter of the day and ease the body into rest.',
    bullets: [
      'Open with permission: "You have done enough today."',
      'Progressive body relaxation: toes → legs → torso → shoulders → face',
      'Visualisation: a warm softly lit room or a still dark lake',
      'Counting breath technique: count exhales from 10 down to 1, reset if lost',
      'Voice pacing should slow — sentences become shorter towards the end',
      'End without a "wake up" cue — simply trail into silence',
    ],
    colors: ['#C5CAE9', '#7986CB'],
    durations: [7, 15],
  },
  {
    name: 'Anxiety SOS',
    emoji: '🌪️',
    goal: 'Interrupt the anxiety loop and return the user to their body immediately.',
    bullets: [
      'Open immediately with breath: 4-count inhale, 6-count exhale',
      'Name and normalise the feeling: "Anxiety is not the enemy."',
      'Physiological sigh: double inhale through the nose, one long exhale',
      'Grounding: name 5 things you can feel or hear right now',
      'Affirmation of safety and capacity: "You have been through hard things."',
      'Close with one slow intentional breath — no recap, end clean',
    ],
    colors: ['#FFCCBC', '#FF8A65'],
    durations: [3, 7],
  },
  {
    name: 'Stress Relief',
    emoji: '🔴',
    goal: 'Release accumulated tension without requiring stillness or perfection.',
    bullets: [
      'Acknowledge the weight without trying to fix it',
      'Breath as a release valve: each exhale = letting go of something specific',
      'Neck and shoulder tension release — permission to roll, drop, soften',
      'Visualisation: stress as a colour, slowly draining away with each breath',
      'Reframe: "The problems are still there, but you are bigger than them now."',
      'Return to the room feeling intentional and calm',
    ],
    colors: ['#FFCDD2', '#EF9A9A'],
    durations: [5, 10],
  },
  {
    name: 'Focus',
    emoji: '🎯',
    goal: 'Clear mental clutter and narrow attention to a single point of engagement.',
    bullets: [
      'Set an intention: "What is the one thing that matters right now?"',
      'Clear the tabs: visualise closing background thoughts one by one',
      'Box breathing for activation: 4-4-4-4',
      'Single-point focus: breath at the tip of the nose, or a single word',
      'Reinforce: "Every time your mind wanders, returning IS the practice."',
      'End with an energised and ready state — prompt the user to open their eyes',
    ],
    colors: ['#E3F2FD', '#64B5F6'],
    durations: [5, 10],
  },
  {
    name: 'Morning Ritual',
    emoji: '🌅',
    goal: 'Anchor the day with intention and a sense of personal agency.',
    bullets: [
      'Open: "This is a new canvas. Nothing from yesterday has to carry forward."',
      'Gentle body awakening: stretch visualisation, deep yawn, shake hands',
      'Set one word or theme for the day — invite the user to choose internally',
      'Gratitude seed: name one small thing to look forward to today',
      'Energy breath: short sharp inhales followed by a strong exhale',
      'Close with a declaration: "I am ready."',
    ],
    colors: ['#FFF9C4', '#FFD54F'],
    durations: [5, 10],
  },
  {
    name: 'Wind Down',
    emoji: '🌙',
    goal: 'Create a clean psychological boundary between the day and rest.',
    bullets: [
      '"Working hours are over. You can put it all down now."',
      'Day completion ritual: mentally place unfinished tasks in a box to open tomorrow',
      'Slow diaphragmatic breathing — extend the exhale progressively each cycle',
      'Body check-in: what did your body carry today? Shoulders, jaw, chest?',
      'Letting go of the roles you played today — employee, parent, partner — just you now',
      'Close with warmth: "Rest is not a reward. It is your right."',
    ],
    colors: ['#B3E5FC', '#4FC3F7'],
    durations: [7, 12],
  },
  {
    name: 'Emotional Processing',
    emoji: '💔',
    goal: 'Create a safe container to feel, not fix, difficult emotions.',
    bullets: [
      'Lead with unconditional validation: "Whatever you are feeling is allowed here."',
      'Locate the emotion physically: heaviness in the chest, tight throat, empty stomach',
      'Breath as a messenger — sitting with the feeling rather than escaping it',
      'Invitation to name without judging: "What would you call this, if it were a weather pattern?"',
      'Loving-kindness seed: "May I be gentle with myself."',
      'No forced resolution — end with acceptance, not toxic positivity',
    ],
    colors: ['#E1BEE7', '#CE93D8'],
    durations: [7, 15],
  },
  {
    name: 'Confidence',
    emoji: '💪',
    goal: 'Build embodied self-belief before a challenge or during a low-confidence moment.',
    bullets: [
      'Ground in the body first: feel your feet, your weight, your presence',
      'Recall one specific moment of past success — hold the feeling, not the full story',
      'Breathing to expand: breathe into the chest, sit or stand a little taller',
      'Inner critic interrupt: "That voice is trying to protect me, not define me."',
      'Power affirmations rooted in identity: "I belong here. I am enough."',
      'Close with a readiness state: purposeful breath, eyes forward',
    ],
    colors: ['#F3E5F5', '#AB47BC'],
    durations: [5, 10],
  },
  {
    name: 'Anger Release',
    emoji: '😤',
    goal: 'Process and discharge anger without suppression or escalation.',
    bullets: [
      'Validate completely: "Anger is information. It tells you what matters to you."',
      'Locate tension: jaw, fists, chest, solar plexus',
      'Physical release breath: strong audible exhale through the mouth — a definite "ha"',
      'Shift from heat to curiosity: "What is this anger protecting underneath?"',
      'Compassion bridge — for self first, then if ready, towards the situation',
      '"You don\'t have to act from this place. You can choose how to respond."',
    ],
    colors: ['#FFECB3', '#FFB300'],
    durations: [5, 10],
  },
  {
    name: 'Body Scan',
    emoji: '🌿',
    goal: 'Reconnect with the physical body; counter dissociation and chronic tension.',
    bullets: [
      'Begin with contact points: "Feel wherever your body meets the surface beneath you."',
      'Slow scan from the crown of the head downward — never rush a region',
      'No judgement, only noticing: tight, warm, numb, heavy — all equally valid',
      'Breath directed to areas of tension: warm light filling that space',
      'Grounding mantra: "I am here. I am safe. I am in my body."',
      'Return to full awareness gently — wiggle fingers, open eyes slowly',
    ],
    colors: ['#DCEDC8', '#AED581'],
    durations: [10, 20],
  },
  {
    name: 'Gratitude',
    emoji: '🙏',
    goal: 'Shift emotional baseline upward through purposeful, embodied noticing.',
    bullets: [
      'Brief science hook: "Gratitude activates the same brain circuits as real joy."',
      'Three-layer gratitude: something in the world → your life → yourself',
      'Savour each item for three full breaths rather than listing quickly',
      'Amplification: "Let this feeling expand with each breath in."',
      'Loving-kindness send-out: extend the warm feeling to someone who needs it',
      'Close: "You already carry something worth protecting today."',
    ],
    colors: ['#FFE0B2', '#FFCC80'],
    durations: [5, 10],
  },
  {
    name: 'Energy Boost',
    emoji: '🔋',
    goal: 'Combat low drive, morning fog, or burnout with an energising mental reset.',
    bullets: [
      'Acknowledge low energy without shame: "Rest was necessary. Now let\'s rise."',
      'Energising breath: Kapalabhati — short sharp exhales — or a 2-2 inhale-exhale ratio',
      'Movement invite: roll shoulders, tap the sternum, open the chest wide',
      'Purpose connection: "What is one thing only you can bring to today?"',
      'Visualise momentum: a small fire igniting in the chest, growing with each inhale',
      'End charged: "You don\'t have to feel like it to start. You just have to begin."',
    ],
    colors: ['#C8E6C9', '#66BB6A'],
    durations: [3, 7],
  },
];

// ─── Duration Helpers ─────────────────────────────────────────────────────────

const DURATION_LABELS = { 3: 'Short', 5: 'Short', 7: 'Medium', 10: 'Medium', 12: 'Medium', 15: 'Long', 20: 'Long' };

// ─── Script Generator ────────────────────────────────────────────────────────

async function generateScript(category, durationMinutes) {
  const durationLabel = DURATION_LABELS[durationMinutes] ?? 'Medium';
  const bulletList = category.bullets.map((b, i) => `${i + 1}. ${b}`).join('\n');

  const systemPrompt = `You are an expert mindfulness and meditation script writer. 
You write guided meditation scripts in a warm, intimate, second-person voice ("you", "your").
Your scripts always include explicit breath cues and follow the narrative arc given to you.
You match the pacing to the session duration — shorter sessions are more direct, longer ones breathe more.`;

  const userPrompt = `Write a guided meditation script for the following category.

CATEGORY: ${category.emoji} ${category.name}
GOAL: ${category.goal}
DURATION: ${durationLabel} (~${durationMinutes} minutes)

NARRATIVE ARC (use these as ordered story beats, not a rigid checklist):
${bulletList}

OUTPUT: Return ONLY a valid JSON object with these exact keys:
{
  "title": "A short, evocative session title (not just the category name — be creative)",
  "description": "One compelling sentence describing what this session offers (max 15 words)",
  "category": "${category.name}",
  "duration_minutes": ${durationMinutes},
  "colors": ${JSON.stringify(category.colors)},
  "script": "The full narrated meditation script. Use ellipses (...) for natural pauses. Include explicit breath cues. Do not add headers or section labels inside the script."
}`;

  const response = await fetch('https://api.openai.com/v1/chat/completions', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${API_KEY}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      model: 'gpt-4o',
      messages: [
        { role: 'system', content: systemPrompt },
        { role: 'user', content: userPrompt },
      ],
      response_format: { type: 'json_object' },
      temperature: 0.85,
    }),
  });

  if (!response.ok) {
    const err = await response.text();
    throw new Error(`OpenAI API error (${response.status}): ${err}`);
  }

  const data = await response.json();
  const content = data.choices[0].message.content;
  return JSON.parse(content);
}

// ─── Main ─────────────────────────────────────────────────────────────────────

async function main() {
  const allSessions = [];
  let sessionId = 1;

  console.log(`\n🧘 VibeCheck Content Factory — Generating ${CATEGORIES.flatMap(c => c.durations).length} sessions...\n`);

  for (const category of CATEGORIES) {
    for (const duration of category.durations) {
      const label = `${category.emoji} ${category.name} (${duration} min)`;
      process.stdout.write(`  Generating ${label}... `);

      try {
        const session = await generateScript(category, duration);
        session.id = `gen-${String(sessionId).padStart(3, '0')}`;
        session.image_url = '';
        session.audio_url = '';
        allSessions.push(session);
        sessionId++;
        console.log('✅');
      } catch (err) {
        console.error(`❌  Failed: ${err.message}`);
      }

      // Be kind to the API — small delay between calls
      await new Promise(r => setTimeout(r, 500));
    }
  }

  const outputPath = join(dirname(fileURLToPath(import.meta.url)), 'sessions.json');
  writeFileSync(outputPath, JSON.stringify(allSessions, null, 2), 'utf8');

  console.log(`\n✨  Done! ${allSessions.length} sessions written to sessions.json`);
  console.log(`📋  Next step: import sessions.json into your Supabase 'meditation_sessions' table.\n`);
}

main().catch(err => {
  console.error('\n❌  Fatal error:', err.message);
  process.exit(1);
});
