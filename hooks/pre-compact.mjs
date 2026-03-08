import { appendFileSync, readFileSync, mkdirSync } from 'fs';
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

function readConfig() {
  try {
    const content = readFileSync(join(homedir(), '.claude', 'time-sense.conf'), 'utf8');
    const match = content.match(/^inject_timeline=(.+)$/m);
    return match ? match[1].trim() : 'full';
  } catch {
    return 'full';
  }
}

const chunks = [];
process.stdin.on('data', c => chunks.push(c));
process.stdin.on('end', () => {
  const input = JSON.parse(Buffer.concat(chunks).toString());
  const timestamp = formatTimestamp();

  const transcriptPath = input.transcript_path || '';
  const convId = transcriptPath ? basename(transcriptPath).replace(/\.jsonl$/, '') : '';

  let msg = `Current time at compaction: ${timestamp}.`;

  if (convId) {
    const logDir = join(homedir(), '.claude', 'time-sense-logs');
    const logFile = join(logDir, `${convId}.log`);
    mkdirSync(logDir, { recursive: true });
    appendFileSync(logFile, `PreCompact|${timestamp}\n`);

    try {
      const content = readFileSync(logFile, 'utf8');
      const lines = content.trim().split('\n').filter(l => l.length > 0);
      const total = lines.length;
      const compactions = lines.filter(l => l.startsWith('PreCompact')).length;
      const sessions = lines.filter(l => l.startsWith('SessionStart')).length;
      const userPrompts = lines.filter(l => l.startsWith('UserPrompt')).length;

      const firstParts = lines[0].split('|');
      const firstEvent = firstParts.length >= 3 ? firstParts[2] : firstParts[1] || '';

      const mode = readConfig();

      if (mode === 'summary') {
        const structural = lines
          .filter(l => l.startsWith('SessionStart') || l.startsWith('PreCompact'))
          .join('\n');
        msg = `Compaction #${compactions} at ${timestamp}. Conversation first started at ${firstEvent}. Total sessions: ${sessions}. Total compactions: ${compactions}. Total user messages: ${userPrompts}. Total events logged: ${total}. Session starts and compaction timestamps (structural events):\n${structural}`;
      } else {
        const timeline = content.trim();
        msg = `Compaction #${compactions} at ${timestamp}. Conversation first started at ${firstEvent}. Total sessions: ${sessions}. Total events logged: ${total}. Full conversation timeline (preserve ALL timestamps in the compacted summary so temporal context across sessions and compactions is never lost):\n${timeline}`;
      }
    } catch {
      // Log file doesn't exist or is unreadable — use default message
    }
  }

  console.log(JSON.stringify({ systemMessage: msg }));
});
