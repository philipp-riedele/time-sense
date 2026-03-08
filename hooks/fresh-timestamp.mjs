import { appendFileSync, mkdirSync } from 'fs';
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

const chunks = [];
process.stdin.on('data', c => chunks.push(c));
process.stdin.on('end', () => {
  const input = JSON.parse(Buffer.concat(chunks).toString());
  const timestamp = formatTimestamp();

  const transcriptPath = input.transcript_path || '';
  const convId = transcriptPath ? basename(transcriptPath).replace(/\.jsonl$/, '') : '';

  if (convId) {
    const logDir = join(homedir(), '.claude', 'time-sense-logs');
    mkdirSync(logDir, { recursive: true });
    appendFileSync(join(logDir, `${convId}.log`), `UserPrompt|${timestamp}\n`);
  }

  console.log(JSON.stringify({
    hookSpecificOutput: {
      hookEventName: 'UserPromptSubmit',
      additionalContext: `Current time: ${timestamp}. Any timestamp from a previous message is STALE. If your response involves time (process durations, file ages, build times, scheduling, 'how long ago'), use this timestamp as reference or run date for a fresh one. Never say 'recently' or 'a while ago' \u2014 calculate the exact duration.`
    }
  }));
});
