---
marp: true
theme: default
paginate: false
style: |
  @import url('https://fonts.googleapis.com/css2?family=Cinzel:wght@400;700;900&family=Lato:wght@300;400;700&display=swap');

  :root {
    --bg-dark: #0d0d1a;
    --bg-panel: #141428;
    --bg-card: #1a1a35;
    --gold: #c9a84c;
    --gold-light: #f0d080;
    --teal: #4ecdc4;
    --purple: #9b59b6;
    --red: #e74c3c;
    --green: #2ecc71;
    --text-light: #e8e8f0;
    --text-dim: #9090b0;
  }

  section {
    width: 3840px;
    height: 2160px;
    background: var(--bg-dark);
    color: var(--text-light);
    font-family: 'Lato', sans-serif;
    font-size: 28px;
    padding: 0;
    display: flex;
    flex-direction: column;
    justify-content: flex-start;
    align-items: stretch;
    overflow: hidden;
  }

  h1 {
    font-family: 'Cinzel', serif;
    color: var(--gold);
    text-align: center;
    font-size: 120px;
    font-weight: 900;
    letter-spacing: 14px;
    margin: 0;
    text-shadow: 0 0 60px rgba(201,168,76,0.5);
  }

  h2 {
    font-family: 'Cinzel', serif;
    color: var(--gold);
    font-size: 36px;
    font-weight: 700;
    letter-spacing: 3px;
    margin: 0 0 20px 0;
    border-bottom: 2px solid var(--gold);
    padding-bottom: 8px;
    text-transform: uppercase;
  }

  h3 {
    font-family: 'Cinzel', serif;
    color: var(--gold-light);
    font-size: 28px;
    font-weight: 700;
    margin: 16px 0 8px 0;
    letter-spacing: 1px;
  }

  p {
    margin: 6px 0;
    line-height: 1.5;
  }

  ul {
    margin: 6px 0;
    padding-left: 30px;
  }

  li {
    margin: 4px 0;
    line-height: 1.45;
  }

  strong {
    color: var(--gold-light);
  }

  code {
    background: rgba(201,168,76,0.15);
    color: var(--teal);
    padding: 2px 8px;
    border-radius: 4px;
    font-size: 0.85em;
    font-family: 'Courier New', monospace;
  }

  .header-band {
    background: linear-gradient(135deg, #0a0a1a 0%, #1a1230 40%, #0d0d1a 100%);
    border-bottom: 5px solid var(--gold);
    padding: 40px 120px 30px;
    text-align: center;
    flex-shrink: 0;
  }

  .subtitle {
    color: var(--text-dim);
    font-size: 30px;
    letter-spacing: 5px;
    text-transform: uppercase;
    margin-top: 8px;
  }

  .tag-row {
    display: flex;
    justify-content: center;
    gap: 20px;
    margin-top: 18px;
    flex-wrap: wrap;
  }

  .tag {
    background: rgba(201,168,76,0.12);
    border: 2px solid rgba(201,168,76,0.4);
    color: var(--gold);
    padding: 6px 24px;
    border-radius: 30px;
    font-size: 24px;
    letter-spacing: 1px;
  }

  .body-grid {
    display: grid;
    grid-template-columns: 1fr 1fr 1fr;
    gap: 30px;
    padding: 30px 60px;
    flex: 1;
    min-height: 0;
  }

  .col {
    display: flex;
    flex-direction: column;
    gap: 26px;
    min-height: 0;
  }

  .col .card {
    flex: 1;
  }

  .card {
    background: var(--bg-card);
    border: 1px solid rgba(201,168,76,0.2);
    border-radius: 14px;
    padding: 30px 36px;
    flex-shrink: 0;
  }

  .card-accent-teal   { border-left: 6px solid var(--teal); }
  .card-accent-gold   { border-left: 6px solid var(--gold); }
  .card-accent-red    { border-left: 6px solid var(--red); }
  .card-accent-green  { border-left: 6px solid var(--green); }
  .card-accent-purple { border-left: 6px solid var(--purple); }

  .pill-row {
    display: flex;
    flex-wrap: wrap;
    gap: 12px;
    margin-top: 16px;
  }

  .pill {
    background: rgba(78,205,196,0.12);
    border: 1px solid rgba(78,205,196,0.35);
    color: var(--teal);
    padding: 5px 18px;
    border-radius: 20px;
    font-size: 24px;
  }

  .flow-box {
    background: rgba(0,0,0,0.3);
    border: 1px solid rgba(78,205,196,0.2);
    border-radius: 10px;
    padding: 18px 24px;
    margin: 14px 0;
    font-family: 'Courier New', monospace;
    font-size: 24px;
    color: var(--teal);
    line-height: 1.8;
  }

  .flow-arrow {
    color: var(--gold);
    margin: 0 6px;
  }

  .key-val {
    display: flex;
    justify-content: space-between;
    padding: 10px 0;
    border-bottom: 1px solid rgba(255,255,255,0.05);
    font-size: 26px;
  }

  .key-val:last-child { border-bottom: none; }

  .kv-key { color: var(--text-dim); }
  .kv-val { color: var(--teal); font-family: 'Courier New', monospace; }

  .highlight-bar {
    background: linear-gradient(90deg, rgba(201,168,76,0.15), rgba(201,168,76,0.05));
    border-left: 5px solid var(--gold);
    padding: 16px 20px;
    border-radius: 0 6px 6px 0;
    margin: 14px 0;
    font-size: 26px;
    line-height: 1.5;
    font-style: italic;
  }

  .badge {
    display: inline-block;
    padding: 3px 14px;
    border-radius: 5px;
    font-size: 22px;
    font-weight: 700;
    letter-spacing: 0.5px;
    text-transform: uppercase;
    vertical-align: middle;
    margin-left: 10px;
  }

  .badge-complete { background: rgba(46,204,113,0.2); color: var(--green); border: 1px solid rgba(46,204,113,0.4); }
  .badge-partial  { background: rgba(230,126,34,0.2); color: #e67e22; border: 1px solid rgba(230,126,34,0.4); }
  .badge-pending  { background: rgba(144,144,176,0.15); color: var(--text-dim); border: 1px solid rgba(144,144,176,0.3); }

  .two-col-inner {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 20px;
    margin-top: 10px;
  }

  .footer-band {
    background: var(--bg-panel);
    border-top: 3px solid rgba(201,168,76,0.3);
    padding: 18px 120px;
    display: flex;
    justify-content: space-between;
    align-items: center;
    flex-shrink: 0;
  }

  .footer-left  { color: var(--text-dim); font-size: 24px; }
  .footer-right { color: var(--text-dim); font-size: 24px; text-align: right; }
---

<div class="header-band">

# BARD

<div class="subtitle">Behaviourally Adaptive Reactive Dialogue</div>
<div class="subtitle" style="font-size:26px; margin-top:4px; color:#c9a84c; opacity:0.8;">Erimentha — An LLM-Driven RPG Demo &nbsp;·&nbsp; A local language model rewrites NPC dialogue every in-game night based on what the player did that day</div>

<div class="tag-row">
  <span class="tag">Godot 4.6</span>
  <span class="tag">GDScript</span>
  <span class="tag">Python 3 Pipeline</span>
  <span class="tag">Ollama · Gemma 4 E4B</span>
  <span class="tag">Local GPU Inference</span>
  <span class="tag">Academic Capstone 2026</span>
</div>

</div>

<div class="body-grid">

<!-- ═══ COLUMN 1 — LLM PIPELINE + NPC MEMORY ═══ -->
<div class="col">

<div class="card card-accent-teal">

## The LLM Pipeline

Every night a **Python subprocess** reads the day's game state and prompts a locally-running LLM to write fresh dialogue for each named NPC — no cloud, no API keys, no internet required.

<div class="flow-box">
  Player sleeps at Inn<br>
  <span class="flow-arrow">→</span> <code>end_day()</code> writes <code>game_state.json</code><br>
  <span class="flow-arrow">→</span> Godot spawns <code>end_of_day.py</code> subprocess<br>
  <span class="flow-arrow">→</span> Pipeline reads kills, bounties, flags, NPC memory<br>
  <span class="flow-arrow">→</span> Ollama (Gemma 4 E4B) generates dialogue JSON<br>
  <span class="flow-arrow">→</span> Validates schema → LLM repair if malformed → fallback<br>
  <span class="flow-arrow">→</span> Writes <code>dialogue/{npc_id}_day{N}.json</code><br>
  <span class="flow-arrow">→</span> LLM extracts one NPC recollection fact<br>
  <span class="flow-arrow">→</span> Writes <code>pipeline_ready.flag</code><br>
  <span class="flow-arrow">→</span> Godot detects flag → reloads dialogue → go to town
</div>

Godot polls for sentinel flag files every 3 seconds — no blocking threads. A progress bar animates as each NPC is processed. The pipeline writes `pipeline_ready.flag`, `pipeline_failed.flag`, or `pipeline_crashed.flag` depending on outcome.


</div>

<div class="card card-accent-gold">

## NPC Memory System

NPCs don't just react to today — they *remember*. After generating each NPC's dialogue, the pipeline makes a second LLM call to extract one subjective recollection and appends it to `game_state.json`. Future prompts inject these facts, building narrative persistence across days.

<div class="highlight-bar">
"Aerin returned today with slime cores — seven of them. She mentioned the pack was larger than expected."
<div style="color:var(--text-dim); font-size:22px; margin-top:6px; font-style:normal;">— Example recollection stored in npc_facts after Day 3</div>
</div>

**Context injected into every NPC prompt:** kill reports for all four monster families · active and completed bounty status · `met_*` and `first_bounty_*` interaction flags · all stored recollection facts · circulating rumors from the Chronicle · town lore + NPC personality variant

</div>

</div>

<!-- ═══ COLUMN 2 — CHRONICLE + BOUNTY ═══ -->
<div class="col">

<div class="card card-accent-green">

## Chronicle Pipeline

Triggered with **Ctrl+R** in town — does not advance the day. Reads the full `monsters_killed_history` and generates a narrative chronicle of the week's events, then derives **rumors** from the player's notable deeds. Rumors are injected into all future end-of-day prompts, giving NPCs indirect awareness of events they didn't witness directly.

<div class="key-val"><span class="kv-key">Rumor attribution</span><span class="kv-val">75% named · 25% anonymous</span></div>
<div class="key-val"><span class="kv-key">Rumor pool cap</span><span class="kv-val">10 entries (oldest pruned)</span></div>
<div class="key-val"><span class="kv-key">Output</span><span class="kv-val">chronicles/week_N.json · rumors.json</span></div>

</div>

<div class="card card-accent-red">

## Bounty System

Contracts are scoped to specific monster types and zones — giving the LLM rich, precise data to reference each night when generating NPC dialogue.

<div class="flow-box">
  <code>bounty_pool.json</code> — 36 static contracts<br>
  <span class="flow-arrow">→</span> Daily refresh: min(day, 3) contracts shown<br>
  <span class="flow-arrow">→</span> Player accepts → tracked in active_bounties<br>
  <span class="flow-arrow">→</span> Zone kills auto-increment the counter<br>
  <span class="flow-arrow">→</span> Turn in at Guild Commander → earn Scripts<br>
  <span class="flow-arrow">→</span> end_day() writes completed data → LLM reads it
</div>

<div class="two-col-inner">
<div>
<div class="key-val"><span class="kv-key">Small</span><span class="kv-val" style="color:var(--green);">10 Scripts</span></div>
<div class="key-val"><span class="kv-key">Medium</span><span class="kv-val" style="color:var(--gold);">25 Scripts</span></div>
<div class="key-val"><span class="kv-key">Large</span><span class="kv-val" style="color:#e67e22;">50 Scripts</span></div>
</div>
<div>
<div class="key-val"><span class="kv-key">Zone A</span><span class="kv-val">Orcs + Plants</span></div>
<div class="key-val"><span class="kv-key">Zone B</span><span class="kv-val">Vampires</span></div>
<div class="key-val"><span class="kv-key">Zone C</span><span class="kv-val">Slimes</span></div>
</div>
</div>

</div>

</div>

<!-- ═══ COLUMN 3 — TECH STACK + DIALOGUE ═══ -->
<div class="col">

<div class="card card-accent-purple">

## Technology Stack

<div class="key-val"><span class="kv-key">Game Engine</span><span class="kv-val">Godot 4.6 · GDScript</span></div>
<div class="key-val"><span class="kv-key">LLM Runtime</span><span class="kv-val">Ollama — local GPU inference</span></div>
<div class="key-val"><span class="kv-key">LLM Model</span><span class="kv-val">Gemma 4 E4B</span></div>
<div class="key-val"><span class="kv-key">Pipeline</span><span class="kv-val">Python 3 (subprocess IPC)</span></div>
<div class="key-val"><span class="kv-key">Interchange</span><span class="kv-val">JSON + sentinel flag files</span></div>
<div class="key-val"><span class="kv-key">UI Architecture</span><span class="kv-val">100% GDScript · signal-driven</span></div>
<div class="key-val"><span class="kv-key">Resolution</span><span class="kv-val">1920×1080 · Forward+ renderer</span></div>


</div>

<div class="card card-accent-teal">

## Dialogue Architecture

LLM-generated content is surgically **merged** with hardcoded role menus at runtime — preserving reliability while the LLM controls all narrative content.

<div class="highlight-bar" style="font-size:25px; font-style:normal;">
  <strong>Hardcoded:</strong> Sleep · Buy Axe · Upgrade Weapons · Bounty Board · Turn In · Goodbye<br>
  <strong>LLM-generated:</strong> greeting node + all branching conversation trees
</div>

Validation enforces: `greeting` + `farewell` required, no broken `next` references, no dead-end cycles. A failed validation triggers an **LLM repair call** before falling back to the previous day's file, then to static fallbacks in `pipeline/fallbacks/`.

<div class="key-val"><span class="kv-key">World generation</span><span class="kv-val">world_gen.py — run once</span></div>
<div class="key-val"><span class="kv-key">NPC variants per role</span><span class="kv-val">3 personality variants (A/B/C)</span></div>
<div class="key-val"><span class="kv-key">Named NPCs</span><span class="kv-val">Innkeeper · Blacksmith · Guild Commander</span></div>

</div>

</div>

</div>

<div class="footer-band">
  <div class="footer-left">
    Bradley Charles · Capstone Project 2026<br>
    Godot 4.6 · Python 3 · Ollama · Gemma 4 E4B
  </div>
  <div style="text-align:center; color:var(--gold); font-family:'Cinzel',serif; font-size:28px; letter-spacing:3px; opacity:0.6;">
    ── BARD · Erimentha ──
  </div>
  <div class="footer-right">
    Local LLM · No Cloud Dependencies<br>
    All dialogue generated nightly on-device
  </div>
</div>
