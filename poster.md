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
    font-size: 26px;
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
    font-size: 100px;
    font-weight: 900;
    letter-spacing: 14px;
    margin: 0;
    text-shadow: 0 0 60px rgba(201,168,76,0.5);
  }

  h2 {
    font-family: 'Cinzel', serif;
    color: var(--gold);
    font-size: 30px;
    font-weight: 700;
    letter-spacing: 3px;
    margin: 0 0 16px 0;
    border-bottom: 2px solid var(--gold);
    padding-bottom: 8px;
    text-transform: uppercase;
  }

  h3 {
    font-family: 'Cinzel', serif;
    color: var(--gold-light);
    font-size: 24px;
    font-weight: 700;
    margin: 12px 0 6px 0;
    letter-spacing: 1px;
  }

  p { margin: 5px 0; line-height: 1.5; }

  ul { margin: 6px 0; padding-left: 28px; }
  li { margin: 5px 0; line-height: 1.4; }

  strong { color: var(--gold-light); }

  code {
    background: rgba(201,168,76,0.15);
    color: var(--teal);
    padding: 2px 7px;
    border-radius: 4px;
    font-size: 0.82em;
    font-family: 'Courier New', monospace;
  }

  .header-band {
    background: linear-gradient(135deg, #0a0a1a 0%, #1a1230 40%, #0d0d1a 100%);
    border-bottom: 5px solid var(--gold);
    padding: 32px 120px 26px;
    text-align: center;
    flex-shrink: 0;
  }

  .subtitle {
    color: var(--text-dim);
    font-size: 26px;
    letter-spacing: 5px;
    text-transform: uppercase;
    margin-top: 6px;
  }

  .team-line {
    color: var(--text-light);
    font-size: 24px;
    margin-top: 10px;
    letter-spacing: 1px;
  }

  .team-line span { color: var(--gold); font-family: 'Cinzel', serif; }

  .abstract-line {
    color: var(--text-dim);
    font-size: 23px;
    margin-top: 8px;
    font-style: italic;
    max-width: 2800px;
    margin-left: auto;
    margin-right: auto;
    line-height: 1.5;
  }

  .tag-row {
    display: flex;
    justify-content: center;
    gap: 16px;
    margin-top: 14px;
    flex-wrap: wrap;
  }

  .tag {
    background: rgba(201,168,76,0.12);
    border: 2px solid rgba(201,168,76,0.4);
    color: var(--gold);
    padding: 5px 20px;
    border-radius: 30px;
    font-size: 21px;
    letter-spacing: 1px;
  }

  .body-grid {
    display: grid;
    grid-template-columns: 1fr 1fr 1fr;
    gap: 26px;
    padding: 26px 52px;
    flex: 1;
    min-height: 0;
  }

  .col {
    display: flex;
    flex-direction: column;
    gap: 22px;
    min-height: 0;
  }

  .col .card { flex: 1; }

  .card {
    background: var(--bg-card);
    border: 1px solid rgba(201,168,76,0.2);
    border-radius: 12px;
    padding: 26px 30px;
  }

  .card-accent-teal   { border-left: 6px solid var(--teal); }
  .card-accent-gold   { border-left: 6px solid var(--gold); }
  .card-accent-red    { border-left: 6px solid var(--red); }
  .card-accent-green  { border-left: 6px solid var(--green); }
  .card-accent-purple { border-left: 6px solid var(--purple); }

  .flow-box {
    background: rgba(0,0,0,0.3);
    border: 1px solid rgba(78,205,196,0.2);
    border-radius: 8px;
    padding: 14px 18px;
    margin: 12px 0;
    font-family: 'Courier New', monospace;
    font-size: 21px;
    color: var(--teal);
    line-height: 1.75;
  }

  .flow-arrow { color: var(--gold); margin: 0 5px; }

  .key-val {
    display: flex;
    justify-content: space-between;
    padding: 8px 0;
    border-bottom: 1px solid rgba(255,255,255,0.05);
    font-size: 24px;
  }

  .key-val:last-child { border-bottom: none; }
  .kv-key { color: var(--text-dim); }
  .kv-val { color: var(--teal); font-family: 'Courier New', monospace; }

  .highlight-bar {
    background: linear-gradient(90deg, rgba(201,168,76,0.15), rgba(201,168,76,0.05));
    border-left: 5px solid var(--gold);
    padding: 13px 16px;
    border-radius: 0 6px 6px 0;
    margin: 12px 0;
    font-size: 23px;
    line-height: 1.5;
  }

  /* Architecture diagram */
  .arch-row {
    display: flex;
    align-items: center;
    gap: 8px;
    margin: 8px 0;
  }

  .arch-box {
    flex: 1;
    border: 2px solid;
    border-radius: 8px;
    padding: 10px 6px;
    text-align: center;
    font-size: 20px;
    font-weight: 700;
    font-family: 'Cinzel', serif;
    letter-spacing: 0.5px;
  }

  .arch-sub {
    font-family: 'Courier New', monospace;
    font-size: 17px;
    font-weight: 400;
    color: var(--text-dim);
    margin-top: 3px;
    letter-spacing: 0;
  }

  .ab-teal   { border-color: var(--teal);   color: var(--teal); }
  .ab-gold   { border-color: var(--gold);   color: var(--gold); }
  .ab-purple { border-color: var(--purple); color: var(--purple); }
  .ab-red    { border-color: var(--red);    color: var(--red); }
  .ab-green  { border-color: var(--green);  color: var(--green); }

  .arch-conn { color: var(--gold); font-size: 26px; flex-shrink: 0; }

  .arch-loop-label {
    text-align: center;
    color: var(--text-dim);
    font-size: 19px;
    font-family: 'Courier New', monospace;
    margin: 2px 0 6px;
    border-top: 1px dashed rgba(78,205,196,0.3);
    padding-top: 6px;
  }

  /* Screenshots */
  .ss-grid {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 14px;
    margin-top: 12px;
  }

  .ss-item img {
    width: 100%;
    border-radius: 8px;
    border: 1px solid rgba(201,168,76,0.25);
    display: block;
  }

  .ss-caption {
    color: var(--text-dim);
    font-size: 19px;
    text-align: center;
    margin-top: 6px;
  }

  /* QR Code */
  .qr-block {
    display: flex;
    align-items: center;
    gap: 36px;
    margin-top: 14px;
  }

  .qr-block img {
    width: 260px;
    height: 260px;
    border-radius: 8px;
    flex-shrink: 0;
  }

  .qr-text { flex: 1; }

  .footer-band {
    background: var(--bg-panel);
    border-top: 3px solid rgba(201,168,76,0.3);
    padding: 16px 120px;
    display: flex;
    justify-content: space-between;
    align-items: center;
    flex-shrink: 0;
  }

  .footer-left  { color: var(--text-dim); font-size: 22px; }
  .footer-right { color: var(--text-dim); font-size: 22px; text-align: right; }
---

<div class="header-band">

# BARD

<div class="subtitle">Behaviourally Adaptive Reactive Dialogue</div>
<div class="team-line"><span>Bradley Charles</span> &nbsp;·&nbsp; Supervisor: <span>Taylor Papke</span> &nbsp;·&nbsp; Academic Capstone 2026</div>
<div class="abstract-line">A Godot 4 RPG in which a locally-running LLM rewrites every NPC's dialogue each in-game night based on what the player did that day — no cloud, no API keys, no internet required.</div>

<div class="tag-row">
  <span class="tag">Godot 4.6</span>
  <span class="tag">GDScript</span>
  <span class="tag">Python 3 Pipeline</span>
  <span class="tag">Ollama · Gemma 4 E4B</span>
  <span class="tag">Local GPU Inference</span>
  <span class="tag">No Cloud Dependencies</span>
</div>

</div>

<div class="body-grid">

<!-- ═══ COLUMN 1 — OVERVIEW & ARCHITECTURE ═══ -->
<div class="col">

<div class="card card-accent-gold">

## Project Overview

**BARD** investigates whether a locally-running LLM can create the *illusion of memory* in NPC dialogue without cloud infrastructure. The player hunts monsters, completes bounties, and sleeps at the inn. Every night, a Python pipeline reads the day's events and prompts Ollama to write fresh, context-aware dialogue for each named NPC before morning.

The academic focus is the **LLM pipeline** — not the gameplay. The bounty system, combat, and economy exist to feed the model meaningful, structured context.

</div>

<div class="card card-accent-teal">

## Key Features

- **Nightly dialogue regeneration** — every NPC speaks fresh every morning
- **NPC memory** — recollections extracted each night, injected into future prompts
- **Rumor propagation** — Chronicle pipeline derives town rumors from kill history
- **Local inference only** — Ollama + Gemma 4 E4B, no API keys required
- **Robust fallback chain** — retry → LLM repair → previous day → static fallback
- **Full bounty loop** — 36 contracts across 4 monster families feed the LLM context
- **Dynamic world gen** — `world_gen.py` bootstraps lore, NPC names & personalities

</div>

<div class="card card-accent-purple">

## System Architecture

<div class="arch-row">
  <div class="arch-box ab-teal">Godot 4<div class="arch-sub">SceneManager</div></div>
  <div class="arch-conn">→</div>
  <div class="arch-box ab-gold">game_state<div class="arch-sub">.json</div></div>
  <div class="arch-conn">→</div>
  <div class="arch-box ab-purple">Python<div class="arch-sub">end_of_day.py</div></div>
  <div class="arch-conn">→</div>
  <div class="arch-box ab-red">Ollama<div class="arch-sub">Gemma 4 E4B</div></div>
</div>
<div class="arch-loop-label">↓ &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; ↓</div>
<div class="arch-row">
  <div class="arch-box ab-teal">Godot 4<div class="arch-sub">Reload Dialogue</div></div>
  <div class="arch-conn">←</div>
  <div class="arch-box ab-green">Flag File<div class="arch-sub">pipeline_ready</div></div>
  <div class="arch-conn">←</div>
  <div class="arch-box ab-gold">dialogue<div class="arch-sub">day_N.json</div></div>
  <div class="arch-conn">←</div>
  <div class="arch-box ab-red">Validate<div class="arch-sub">+ Repair</div></div>
</div>

<p style="color:var(--text-dim); font-size:21px; margin-top:14px;">Godot polls for flag files every 3 s — no blocking threads. IPC is entirely JSON + sentinel files.</p>

</div>

</div>

<!-- ═══ COLUMN 2 — THE LLM PIPELINE ═══ -->
<div class="col">

<div class="card card-accent-teal">

## The LLM Pipeline

Every night a **Python subprocess** reads the day's game state and prompts a locally-running LLM to write fresh dialogue for each named NPC.

<div class="flow-box">
  Player sleeps at Inn<br>
  <span class="flow-arrow">→</span> <code>end_day()</code> writes <code>game_state.json</code><br>
  <span class="flow-arrow">→</span> Godot spawns <code>end_of_day.py</code> subprocess<br>
  <span class="flow-arrow">→</span> Pipeline reads kills, bounties, flags, NPC memory<br>
  <span class="flow-arrow">→</span> Ollama (Gemma 4 E4B) generates dialogue JSON<br>
  <span class="flow-arrow">→</span> Validates schema → LLM repair if malformed → fallback<br>
  <span class="flow-arrow">→</span> Writes <code>dialogue/{npc_id}_day{N}.json</code><br>
  <span class="flow-arrow">→</span> LLM extracts one NPC recollection → appends to state<br>
  <span class="flow-arrow">→</span> Writes <code>pipeline_ready.flag</code><br>
  <span class="flow-arrow">→</span> Godot detects flag → reloads dialogue → go to town
</div>

</div>

<div class="card card-accent-gold">

## NPC Memory & Chronicle

**Memory:** After generating each NPC's dialogue, a second LLM call extracts one subjective recollection and appends it to `game_state.json`. Future prompts inject these facts, building narrative persistence across days.

<div class="highlight-bar" style="font-style:italic;">
"Aerin returned with slime cores — seven of them. She said the pack was larger than expected."
<div style="color:var(--text-dim); font-size:19px; margin-top:4px; font-style:normal;">— Example recollection stored after Day 3</div>
</div>

**Chronicle (Ctrl+R):** Reads full kill history, generates a weekly narrative, then derives rumors (75% named, 25% anonymous) injected into all future NPC prompts — giving NPCs awareness of events they didn't witness.

</div>

<div class="card card-accent-red">

## Dialogue Architecture

LLM content is **merged** with hardcoded role menus at runtime — the LLM controls narrative; the engine controls system reliability.

<div class="highlight-bar" style="font-size:22px; font-style:normal;">
  <strong>Hardcoded:</strong> Sleep · Shop · Bounty Board · Turn In · Goodbye<br>
  <strong>LLM-generated:</strong> greeting node + all branching conversation trees
</div>

Validation enforces `greeting` + `farewell` nodes, no broken `next` refs. Failure triggers an LLM repair call, then falls back to the previous day's file, then to `pipeline/fallbacks/`.

<div class="key-val"><span class="kv-key">NPC variants per role</span><span class="kv-val">3 personalities (A/B/C)</span></div>
<div class="key-val"><span class="kv-key">Named NPCs</span><span class="kv-val">Innkeeper · Blacksmith · Guild Commander</span></div>

</div>

</div>

<!-- ═══ COLUMN 3 — IN ACTION + TECH ═══ -->
<div class="col">

<div class="card card-accent-green">

## The Game in Action

<div class="ss-grid">
  <div class="ss-item">
    <img src="ss_dialogue.png">
    <div class="ss-caption">LLM-generated NPC dialogue in Thornwall</div>
  </div>
  <div class="ss-item">
    <img src="ss_bounty.png">
    <div class="ss-caption">Bounty Board — 36 contracts across 4 zones</div>
  </div>
</div>

</div>

<div class="card card-accent-purple">

## Technology Stack

<div class="key-val"><span class="kv-key">Game Engine</span><span class="kv-val">Godot 4.6 · GDScript</span></div>
<div class="key-val"><span class="kv-key">LLM Runtime</span><span class="kv-val">Ollama — local GPU</span></div>
<div class="key-val"><span class="kv-key">LLM Model</span><span class="kv-val">Gemma 4 E4B</span></div>
<div class="key-val"><span class="kv-key">Pipeline</span><span class="kv-val">Python 3 subprocess</span></div>
<div class="key-val"><span class="kv-key">IPC</span><span class="kv-val">JSON + sentinel flag files</span></div>
<div class="key-val"><span class="kv-key">UI Architecture</span><span class="kv-val">100% GDScript · signal-driven</span></div>
<div class="key-val"><span class="kv-key">Resolution</span><span class="kv-val">1920×1080 · Forward+ renderer</span></div>

</div>

<div class="card card-accent-gold">

## Source Code

<div class="qr-block">
  <img src="qr_code.png">
  <div class="qr-text">
    <div style="font-family:'Cinzel',serif; color:var(--gold); font-size:26px; margin-bottom:10px;">GitHub Repository</div>
    <div style="font-family:'Courier New',monospace; color:var(--teal); font-size:22px; margin-bottom:16px;">github.com/BradleyCharles/BARD</div>
    <div style="color:var(--text-dim); font-size:21px; line-height:1.5;">Full source including Godot project, Python pipeline, NPC archetypes, and dialogue fallbacks.</div>
  </div>
</div>

</div>

</div>

</div>

<div class="footer-band">
  <div class="footer-left">
    Bradley Charles · Supervisor: Taylor Papke<br>
    Capstone Project 2026
  </div>
  <div style="text-align:center; color:var(--gold); font-family:'Cinzel',serif; font-size:26px; letter-spacing:3px; opacity:0.6;">
    ── BARD · Erimentha ──
  </div>
  <div class="footer-right">
    Godot 4.6 · Python 3 · Ollama · Gemma 4 E4B<br>
    Local LLM · No Cloud Dependencies
  </div>
</div>
