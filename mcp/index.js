// Jarvy MCP Service — localhost:3001
// Bridges Flutter ↔ macOS Calendar & Reminders via osascript.
// Extensible: add new tool routes following the pattern below.

'use strict';

const express = require('express');
const { exec } = require('child_process');
const { promisify } = require('util');

const execAsync = promisify(exec);
const app = express();
const PORT = 3001;

app.use(express.json());

// ── Health ────────────────────────────────────────────────────────────────
app.get('/health', (_, res) => res.json({ ok: true, service: 'jarvy-mcp' }));

// ── Helpers ───────────────────────────────────────────────────────────────

/** Run an AppleScript string and return trimmed stdout. */
async function runScript(script) {
  const { stdout } = await execAsync(`osascript -e '${script.replace(/'/g, "'\\''")}'`);
  return stdout.trim();
}

/** Parse ISO date string into AppleScript date literal. */
function isoToAppleDate(iso) {
  const d = new Date(iso);
  // AppleScript date: "Wednesday, May 28, 2026 at 09:00:00 AM"
  return d.toLocaleDateString('en-US', {
    weekday: 'long', year: 'numeric', month: 'long', day: 'numeric',
  }) + ' at ' + d.toLocaleTimeString('en-US', {
    hour: '2-digit', minute: '2-digit', second: '2-digit',
  });
}

// ── Calendar ──────────────────────────────────────────────────────────────

/**
 * GET /calendar/today
 * Returns today's calendar events from all calendars.
 */
app.get('/calendar/today', async (_, res) => {
  try {
    const script = `
      set today to current date
      set startOfDay to today - (time of today) * seconds
      set endOfDay to startOfDay + 86399
      set output to ""
      tell application "Calendar"
        repeat with cal in calendars
          set evts to (every event of cal whose start date >= startOfDay and start date <= endOfDay)
          repeat with evt in evts
            set evtTitle to summary of evt
            set evtStart to start date of evt
            set h to hours of evtStart
            set m to minutes of evtStart
            set ampm to "AM"
            if h >= 12 then set ampm to "PM"
            if h > 12 then set h to h - 12
            if h = 0 then set h to 12
            set mStr to text -2 thru -1 of ("00" & m)
            set output to output & h & ":" & mStr & " " & ampm & "|" & evtTitle & "\n"
          end repeat
        end repeat
      end tell
      return output
    `;
    const raw = await runScript(script);
    const events = raw
      .split('\n')
      .filter(Boolean)
      .map(line => {
        const [time, ...titleParts] = line.split('|');
        return { time: time.trim(), title: titleParts.join('|').trim() };
      });
    res.json(events);
  } catch (err) {
    console.error('calendar/today error:', err.message);
    res.json([]); // degrade gracefully
  }
});

/**
 * GET /calendar/range?start=ISO&end=ISO
 * Returns events in a date range.
 */
app.get('/calendar/range', async (req, res) => {
  const { start, end } = req.query;
  if (!start || !end) return res.status(400).json({ error: 'start and end required' });

  try {
    const startDate = new Date(start);
    const endDate = new Date(end);
    const script = `
      set startD to date "${isoToAppleDate(startDate.toISOString())}"
      set endD to date "${isoToAppleDate(endDate.toISOString())}"
      set output to ""
      tell application "Calendar"
        repeat with cal in calendars
          set evts to (every event of cal whose start date >= startD and start date <= endD)
          repeat with evt in evts
            set evtTitle to summary of evt
            set evtDate to start date of evt
            set output to output & (short date string of evtDate) & " " & (time string of evtDate) & "|" & evtTitle & "\n"
          end repeat
        end repeat
      end tell
      return output
    `;
    const raw = await runScript(script);
    const events = raw
      .split('\n')
      .filter(Boolean)
      .map(line => {
        const [time, ...titleParts] = line.split('|');
        return { time: time.trim(), title: titleParts.join('|').trim() };
      });
    res.json(events);
  } catch (err) {
    console.error('calendar/range error:', err.message);
    res.json([]);
  }
});

/**
 * POST /calendar/create
 * Body: { title, start (ISO), end (ISO), notes?, calendar? }
 */
app.post('/calendar/create', async (req, res) => {
  const { title, start, end, notes = '', calendar = 'Calendar' } = req.body;
  if (!title || !start || !end) {
    return res.status(400).json({ error: 'title, start, end required' });
  }

  try {
    const startApple = isoToAppleDate(start);
    const endApple = isoToAppleDate(end);
    const notesLine = notes
      ? `set description of newEvent to "${notes.replace(/"/g, '\\"')}"`
      : '';

    const script = `
      tell application "Calendar"
        tell calendar "${calendar}"
          set newEvent to make new event with properties {summary:"${title.replace(/"/g, '\\"')}", start date:date "${startApple}", end date:date "${endApple}"}
          ${notesLine}
        end tell
      end tell
      return "ok"
    `;
    await runScript(script);
    res.json({ ok: true });
  } catch (err) {
    console.error('calendar/create error:', err.message);
    res.status(500).json({ error: err.message });
  }
});

// ── Reminders ─────────────────────────────────────────────────────────────

/**
 * GET /reminders/pending
 * Returns all incomplete reminders.
 */
app.get('/reminders/pending', async (_, res) => {
  try {
    const script = `
      set output to ""
      tell application "Reminders"
        set incompleteTodos to every reminder whose completed is false
        repeat with r in incompleteTodos
          set rName to name of r
          set rDue to ""
          try
            set rDue to due date of r as string
          end try
          set output to output & rName & "|" & rDue & "\n"
        end repeat
      end tell
      return output
    `;
    const raw = await runScript(script);
    const reminders = raw
      .split('\n')
      .filter(Boolean)
      .map(line => {
        const [title, due] = line.split('|');
        return { title: title.trim(), due: due ? due.trim() : null };
      });
    res.json(reminders);
  } catch (err) {
    console.error('reminders/pending error:', err.message);
    res.json([]);
  }
});

/**
 * POST /reminders/create
 * Body: { title, dueDate? (ISO), list? }
 */
app.post('/reminders/create', async (req, res) => {
  const { title, dueDate, list = 'Reminders' } = req.body;
  if (!title) return res.status(400).json({ error: 'title required' });

  try {
    const dueLine = dueDate
      ? `set due date of newReminder to date "${isoToAppleDate(dueDate)}"`
      : '';

    const script = `
      tell application "Reminders"
        tell list "${list}"
          set newReminder to make new reminder with properties {name:"${title.replace(/"/g, '\\"')}"}
          ${dueLine}
        end tell
      end tell
      return "ok"
    `;
    await runScript(script);
    res.json({ ok: true });
  } catch (err) {
    console.error('reminders/create error:', err.message);
    res.status(500).json({ error: err.message });
  }
});

// ── Start ─────────────────────────────────────────────────────────────────
app.listen(PORT, '127.0.0.1', () => {
  console.log(`[jarvy-mcp] listening on http://127.0.0.1:${PORT}`);
});
