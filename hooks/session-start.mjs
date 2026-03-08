import { appendFileSync, mkdirSync, existsSync, writeFileSync } from 'fs';
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

  // Initialize settings with defaults on first run
  const confPath = join(homedir(), '.claude', 'time-sense.conf');
  if (!existsSync(confPath)) {
    mkdirSync(join(homedir(), '.claude'), { recursive: true });
    writeFileSync(confPath, 'inject_timeline=full\n');
  }

  const transcriptPath = input.transcript_path || '';
  const convId = transcriptPath ? basename(transcriptPath).replace(/\.jsonl$/, '') : '';

  if (convId) {
    const logDir = join(homedir(), '.claude', 'time-sense-logs');
    mkdirSync(logDir, { recursive: true });
    appendFileSync(join(logDir, `${convId}.log`), `SessionStart|${timestamp}\n`);
  }

  console.log(JSON.stringify({
    hookSpecificOutput: {
      hookEventName: 'SessionStart',
      additionalContext: `Current time: ${timestamp}. This is your temporal anchor for this session. Before any time-related statement, always run date to get a fresh timestamp. Never reuse old timestamps. Never guess what time it is.`
    }
  }));
});
