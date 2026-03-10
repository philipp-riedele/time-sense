import { appendFileSync, readFileSync, writeFileSync, mkdirSync } from 'fs';
import { execFileSync } from 'child_process';
import { join, basename } from 'path';
import { homedir, platform } from 'os';

function getTimezone() {
  if (platform() !== 'win32') {
    try { return execFileSync('date', ['+%Z'], { encoding: 'utf8' }).trim(); } catch {}
  }
  return new Date().toLocaleTimeString('en-US', { timeZoneName: 'short' }).split(' ').pop();
}

function formatTimestamp() {
  const now = new Date();
  const pad = n => String(n).padStart(2, '0');
  const d = `${now.getFullYear()}-${pad(now.getMonth() + 1)}-${pad(now.getDate())}`;
  const t = `${pad(now.getHours())}:${pad(now.getMinutes())}:${pad(now.getSeconds())}`;
  return `${d} ${t} ${getTimezone()}`;
}

function readConfig(key, defaultValue) {
  try {
    const conf = readFileSync(join(homedir(), '.claude', 'time-sense.conf'), 'utf8');
    const match = conf.match(new RegExp(`^${key}=(.+)$`, 'm'));
    return match ? match[1].trim().replace(/\r$/, '') : defaultValue;
  } catch { return defaultValue; }
}

function isRepeatPrompt(prompt, logDir) {
  const lastPromptFile = join(logDir, '.last-prompt');
  let isRepeat = false;
  try {
    const lastPrompt = readFileSync(lastPromptFile, 'utf8');
    isRepeat = lastPrompt === prompt;
  } catch {}
  try { writeFileSync(lastPromptFile, prompt); } catch {}
  return isRepeat;
}

const chunks = [];
process.stdin.on('data', c => chunks.push(c));
process.stdin.on('end', () => {
  const input = JSON.parse(Buffer.concat(chunks).toString());
  const timestamp = formatTimestamp();
  const prompt = input.prompt || '';

  const transcriptPath = input.transcript_path || '';
  const convId = transcriptPath ? basename(transcriptPath).replace(/\.jsonl$/, '') : '';

  const logDir = join(homedir(), '.claude', 'time-sense-logs');
  mkdirSync(logDir, { recursive: true });

  // Always log the event (for status tracking)
  if (convId) {
    appendFileSync(join(logDir, `${convId}.log`), `UserPrompt|${timestamp}\n`);
  }

  // Check if this is a repeated prompt (likely a loop iteration)
  const repeat = isRepeatPrompt(prompt, logDir);
  const injectOnRepeat = readConfig('inject_on_repeat', 'true') === 'true';

  if (repeat && !injectOnRepeat) {
    // Skip injection but output valid empty response
    console.log(JSON.stringify({}));
  } else {
    console.log(JSON.stringify({
      hookSpecificOutput: {
        hookEventName: 'UserPromptSubmit',
        additionalContext: `Current time: ${timestamp}. Any timestamp from a previous message is STALE. If your response involves time (process durations, file ages, build times, scheduling, 'how long ago'), use this timestamp as reference or run date for a fresh one. Never say 'recently' or 'a while ago' \u2014 calculate the exact duration.`
      }
    }));
  }
});
