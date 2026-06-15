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
    font-size: 110px;
    font-weight: 900;
    letter-spacing: 12px;
    margin: 0;
    text-shadow: 0 0 60px rgba(201,168,76,0.5);
  }

  h2 {
    font-family: 'Cinzel', serif;
    color: var(--gold);
    font-size: 34px;
    font-weight: 700;
    letter-spacing: 3px;
    margin: 0 0 18px 0;
    border-bottom: 2px solid var(--gold);
    padding-bottom: 8px;
    text-transform: uppercase;
  }

  h3 {
    font-family: 'Cinzel', serif;
    color: var(--gold-light);
    font-size: 26px;
    font-weight: 700;
    margin: 14px 0 8px 0;
    letter-spacing: 1px;
  }

  p {
    margin: 6px 0;
    line-height: 1.5;
  }

  ul {
    margin: 6px 0;
    padding-left: 28px;
  }

  li {
    margin: 4px 0;
    line-height: 1.4;
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
    padding: 48px 120px 36px;
    text-align: center;
    flex-shrink: 0;
  }

  .subtitle {
    color: var(--text-dim);
    font-size: 28px;
    letter-spacing: 5px;
    text-transform: uppercase;
    margin-top: 10px;
  }

  .tag-row {
    display: flex;
    justify-content: center;
    gap: 20px;
    margin-top: 22px;
    flex-wrap: wrap;
  }

  .tag {
    background: rgba(201,168,76,0.12);
    border: 2px solid rgba(201,168,76,0.4);
    color: var(--gold);
    padding: 6px 22px;
    border-radius: 30px;
    font-size: 22px;
    letter-spacing: 1px;
  }

  .body-grid {
    display: grid;
    grid-template-columns: 1fr 1fr 1fr;
    gap: 28px;
    padding: 28px 56px;
    flex: 1;
    min-height: 0;
  }

  .col {
    display: flex;
    flex-direction: column;
    gap: 24px;
    min-height: 0;
  }

  .card {
    background: var(--bg-card);
    border: 1px solid rgba(201,168,76,0.2);
    border-radius: 12px;
    padding: 28px 32px;
    flex-shrink: 0;
  }

  .card-accent-teal   { border-left: 5px solid var(--teal); }
  .card-accent-gold   { border-left: 5px solid var(--gold); }
  .card-accent-red    { border-left: 5px solid var(--red); }
  .card-accent-green  { border-left: 5px solid var(--green); }
  .card-accent-purple { border-left: 5px solid var(--purple); }

  .pill-row {
    display: flex;
    flex-wrap: wrap;
    gap: 10px;
    margin-top: 14px;
  }

  .pill {
    background: rgba(78,205,196,0.12);
    border: 1px solid rgba(78,205,196,0.35);
    color: var(--teal);
    padding: 4px 16px;
    border-radius: 20px;
    font-size: 22px;
  }

  .pill-gold {
    background: rgba(201,168,76,0.12);
    border: 1px solid rgba(201,168,76,0.35);
    color: var(--gold);
  }

  .pill-green {
    background: rgba(46,204,113,0.12);
    border: 1px solid rgba(46,204,113,0.35);
    color: var(--green);
  }

  .flow-box {
    background: rgba(0,0,0,0.3);
    border: 1px solid rgba(78,205,196,0.2);
    border-radius: 8px;
    padding: 16px 20px;
    margin: 12px 0;
    font-family: 'Courier New', monospace;
    font-size: 22px;
    color: var(--teal);
    line-height: 1.7;
  }

  .flow-arrow {
    color: var(--gold);
    margin: 0 5px;
  }

  .stat-grid {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 12px;
    margin-top: 14px;
  }

  .stat-item {
    background: rgba(0,0,0,0.25);
    border-radius: 6px;
    padding: 10px 14px;
    text-align: center;
  }

  .stat-val {
    color: var(--gold-light);
    font-size: 52px;
    font-weight: 700;
    font-family: 'Cinzel', serif;
    display: block;
  }

  .stat-lbl {
    color: var(--text-dim);
    font-size: 18px;
    display: block;
    text-transform: uppercase;
    letter-spacing: 1px;
    margin-top: 4px;
  }

  .mob-family {
    display: flex;
    align-items: center;
    gap: 16px;
    padding: 10px 0;
    border-bottom: 1px solid rgba(255,255,255,0.05);
  }

  .mob-family:last-child { border-bottom: none; }

  .mob-dot {
    width: 18px;
    height: 18px;
    border-radius: 50%;
    flex-shrink: 0;
  }

  .dot-teal   { background: var(--teal); }
  .dot-orange { background: #e67e22; }
  .dot-green  { background: var(--green); }
  .dot-purple { background: var(--purple); }

  .mob-info { flex: 1; }
  .mob-name { color: var(--text-light); font-size: 24px; font-weight: 700; }
  .mob-zone { color: var(--text-dim); font-size: 20px; margin-top: 2px; }

  .key-val {
    display: flex;
    justify-content: space-between;
    padding: 8px 0;
    border-bottom: 1px solid rgba(255,255,255,0.04);
    font-size: 24px;
  }

  .key-val:last-child { border-bottom: none; }

  .kv-key { color: var(--text-dim); }
  .kv-val { color: var(--teal); font-family: 'Courier New', monospace; }

  .timeline-item {
    display: flex;
    gap: 18px;
    margin-bottom: 16px;
    align-items: flex-start;
  }

  .timeline-num {
    background: var(--gold);
    color: #000;
    width: 40px;
    height: 40px;
    border-radius: 50%;
    display: flex;
    align-items: center;
    justify-content: center;
    font-weight: 700;
    font-size: 20px;
    flex-shrink: 0;
    margin-top: 2px;
  }

  .timeline-text {
    font-size: 24px;
    line-height: 1.4;
  }

  .highlight-bar {
    background: linear-gradient(90deg, rgba(201,168,76,0.15), rgba(201,168,76,0.05));
    border-left: 5px solid var(--gold);
    padding: 14px 18px;
    border-radius: 0 6px 6px 0;
    margin: 12px 0;
    font-size: 24px;
    line-height: 1.5;
  }

  .badge {
    display: inline-block;
    padding: 2px 12px;
    border-radius: 4px;
    font-size: 20px;
    font-weight: 700;
    letter-spacing: 0.5px;
    text-transform: uppercase;
    vertical-align: middle;
    margin-left: 8px;
  }

  .badge-complete { background: rgba(46,204,113,0.2); color: var(--green); border: 1px solid rgba(46,204,113,0.4); }
  .badge-partial  { background: rgba(230,126,34,0.2); color: #e67e22; border: 1px solid rgba(230,126,34,0.4); }
  .badge-pending  { background: rgba(144,144,176,0.15); color: var(--text-dim); border: 1px solid rgba(144,144,176,0.3); }

  .footer-band {
    background: var(--bg-panel);
    border-top: 3px solid rgba(201,168,76,0.3);
    padding: 20px 120px;
    display: flex;
    justify-content: space-between;
    align-items: center;
    flex-shrink: 0;
  }

  .footer-left  { color: var(--text-dim); font-size: 22px; }
  .footer-right { color: var(--text-dim); font-size: 22px; text-align: right; }
---

<!-- Poster slide: 4K 16:9 (3840×2160) -->

<div class="header-band">

# BARD

<div class="subtitle">Behaviourally Adaptive Reactive Dialogue</div>
<div class="subtitle" style="font-size:24px; margin-top:6px; color:#c9a84c; opacity:0.7;">Erimentha — An LLM-Driven RPG Demo</div>

<div class="tag-row">
  <span class="tag">Godot 4.6</span>
  <span class="tag">GDScript</span>
  <span class="tag">Python 3 Pipeline</span>
  <span class="tag">Ollama · Gemma 4 E4B</span>
  <span class="tag">Local GPU Inference</span>
  <span class="tag">Academic Capstone 2025</span>
</div>

</div>

<div class="body-grid">

<!-- ═══ COLUMN 1 — THE GAME ═══ -->
<div class="col">

<div class="card card-accent-gold">

## Overview

**BARD** is an academic RPG demonstrating how a locally-running Large Language Model can generate unique, context-aware NPC dialogue each in-game day — creating the illusion that the world *remembers* what you did.

<div class="highlight-bar">
  Hunt monsters. Complete bounties. Sleep at the inn. Wake to NPCs who remember yesterday.
</div>

<div class="stat-grid">
  <div class="stat-item">
    <span class="stat-val">3</span>
    <span class="stat-lbl">Named NPCs</span>
  </div>
  <div class="stat-item">
    <span class="stat-val">12</span>
    <span class="stat-lbl">Enemy Types</span>
  </div>
  <div class="stat-item">
    <span class="stat-val">4</span>
    <span class="stat-lbl">Boss Encounters</span>
  </div>
  <div class="stat-item">
    <span class="stat-val">36</span>
    <span class="stat-lbl">Bounty Contracts</span>
  </div>
</div>

</div>

<div class="card card-accent-teal">

## Core Gameplay Loop

<div class="timeline-item">
  <div class="timeline-num">1</div>
  <div class="timeline-text"><strong>Hunt</strong> — Travel to Ashfield and clear monster-infested zones to fulfil bounty contracts</div>
</div>
<div class="timeline-item">
  <div class="timeline-num">2</div>
  <div class="timeline-text"><strong>Turn In</strong> — Return to Thornwall and claim your reward in Scripts from the Guild Commander</div>
</div>
<div class="timeline-item">
  <div class="timeline-num">3</div>
  <div class="timeline-text"><strong>Spend</strong> — Buy and upgrade weapons at the Blacksmith using Scripts and Slime Goop</div>
</div>
<div class="timeline-item">
  <div class="timeline-num">4</div>
  <div class="timeline-text"><strong>Sleep</strong> — Rest at the Inn to end the day and trigger the nightly LLM pipeline</div>
</div>
<div class="timeline-item" style="margin-bottom:0;">
  <div class="timeline-num">5</div>
  <div class="timeline-text"><strong>Repeat</strong> — Wake to NPCs who remember yesterday's kills, bounties, and deeds</div>
</div>

</div>

<div class="card card-accent-purple">

## Enemy Roster

<div class="mob-family">
  <div class="mob-dot dot-teal"></div>
  <div class="mob-info">
    <div class="mob-name">Slimes <span style="color:var(--text-dim); font-size:20px; font-weight:400;">· Zone C</span></div>
    <div class="mob-zone">Pack AI · Passive-until-hit · Aggressive-on-sight · Boss at 10 kills</div>
  </div>
</div>
<div class="mob-family">
  <div class="mob-dot dot-orange"></div>
  <div class="mob-info">
    <div class="mob-name">Orcs <span style="color:var(--text-dim); font-size:20px; font-weight:400;">· Zone A</span></div>
    <div class="mob-zone">Charger AI · Telegraphed rush attack · Boss at 10 kills</div>
  </div>
</div>
<div class="mob-family">
  <div class="mob-dot dot-green"></div>
  <div class="mob-info">
    <div class="mob-name">Plants <span style="color:var(--text-dim); font-size:20px; font-weight:400;">· Zone A</span></div>
    <div class="mob-zone">Creeper AI · Starburst AOE boss · Boss at 10 kills</div>
  </div>
</div>
<div class="mob-family">
  <div class="mob-dot dot-purple"></div>
  <div class="mob-info">
    <div class="mob-name">Vampires <span style="color:var(--text-dim); font-size:20px; font-weight:400;">· Zone B</span></div>
    <div class="mob-zone">Stalker AI · Orbit-and-dash · Life-drain boss at 20 kills</div>
  </div>
</div>

</div>

</div>

<!-- ═══ COLUMN 2 — THE LLM PIPELINE ═══ -->
<div class="col">

<div class="card card-accent-teal">

## The LLM Pipeline

The academic heart of BARD. Every night a **Python subprocess** reads the day's game state and prompts a locally-running LLM to write fresh dialogue for each NPC — no cloud, no API keys.

<div class="flow-box">
  Player sleeps at Inn<br>
  <span class="flow-arrow">→</span> <code>end_day()</code> writes <code>game_state.json</code><br>
  <span class="flow-arrow">→</span> Godot spawns <code>end_of_day.py</code> subprocess<br>
  <span class="flow-arrow">→</span> Pipeline reads kills, bounties, flags, NPC memory<br>
  <span class="flow-arrow">→</span> Ollama (Gemma 4 E4B) generates dialogue JSON<br>
  <span class="flow-arrow">→</span> Validates schema → repairs if malformed → fallback<br>
  <span class="flow-arrow">→</span> Writes <code>dialogue/{npc_id}_day{N}.json</code><br>
  <span class="flow-arrow">→</span> LLM extracts one NPC recollection fact<br>
  <span class="flow-arrow">→</span> Writes <code>pipeline_ready.flag</code><br>
  <span class="flow-arrow">→</span> Godot detects flag → reloads dialogue → go to town
</div>

Godot polls for sentinel flag files every 3 seconds — no blocking, no threads. A 400 px progress bar animates as each NPC is processed.

<div class="pill-row">
  <span class="pill">Ollama HTTP API</span>
  <span class="pill">3× retry logic</span>
  <span class="pill">JSON schema validation</span>
  <span class="pill">LLM-based repair</span>
  <span class="pill">Fallback chain</span>
  <span class="pill">180 s timeout</span>
</div>

</div>

<div class="card card-accent-gold">

## NPC Memory System

NPCs don't just react to today — they *remember*. After generating dialogue, the pipeline makes a second LLM call to extract one subjective recollection and appends it to `game_state.json`. Future prompts inject these facts, building narrative persistence across days.

<div class="highlight-bar">
  <em>"Aerin returned today with slime cores — seven of them. She mentioned the pack was larger than expected."</em>
  <div style="color:var(--text-dim); font-size:20px; margin-top:6px;">— Example recollection stored after Day 3</div>
</div>

**Context injected into every NPC prompt:** kill reports, bounty status, interaction flags, stored recollections, circulating rumors, world lore, and the NPC's personality variant.

</div>

<div class="card card-accent-green">

## Chronicle Pipeline

Triggered with **Ctrl+R** in town. Reads the full kill history and generates a narrative chronicle of the week — then derives **rumors** from the player's notable deeds. Rumors are injected into future end-of-day prompts, giving NPCs indirect awareness of events.

<div class="key-val"><span class="kv-key">Rumor attribution</span><span class="kv-val">75% named · 25% anonymous</span></div>
<div class="key-val"><span class="kv-key">Rumor pool cap</span><span class="kv-val">10 entries max</span></div>
<div class="key-val"><span class="kv-key">Output</span><span class="kv-val">chronicles/week_N.json + rumors.json</span></div>

</div>

</div>

<!-- ═══ COLUMN 3 — TECHNICAL ═══ -->
<div class="col">

<div class="card card-accent-purple">

## Technology Stack

<div class="key-val"><span class="kv-key">Game Engine</span><span class="kv-val">Godot 4.6 · GDScript</span></div>
<div class="key-val"><span class="kv-key">LLM Runtime</span><span class="kv-val">Ollama (local GPU)</span></div>
<div class="key-val"><span class="kv-key">LLM Model</span><span class="kv-val">Gemma 4 E4B</span></div>
<div class="key-val"><span class="kv-key">Pipeline</span><span class="kv-val">Python 3</span></div>
<div class="key-val"><span class="kv-key">IPC</span><span class="kv-val">JSON + flag files</span></div>
<div class="key-val"><span class="kv-key">Resolution</span><span class="kv-val">1920×1080 · Forward+ renderer</span></div>
<div class="key-val"><span class="kv-key">UI Architecture</span><span class="kv-val">100% GDScript · signal-driven</span></div>

### Development Status

<div style="margin-top:10px; font-size:24px; line-height:2;">
Environment Setup <span class="badge badge-complete">Done</span><br>
Godot Foundations <span class="badge badge-complete">Done</span><br>
Game State Architecture <span class="badge badge-complete">Done</span><br>
LLM Pipeline <span class="badge badge-partial">In Progress</span><br>
Combat &amp; Monsters <span class="badge badge-partial">Partial</span><br>
Dialogue Delivery <span class="badge badge-partial">Partial</span><br>
Polish &amp; Demo Prep <span class="badge badge-pending">Pending</span>
</div>

</div>

<div class="card card-accent-red">

## Bounty System

Contracts are scoped to specific monster types and zones — giving the LLM rich, precise data to reference each night.

<div class="flow-box">
  <code>bounty_pool.json</code> (36 static contracts)<br>
  <span class="flow-arrow">→</span> Daily refresh: min(day, 3) shown per day<br>
  <span class="flow-arrow">→</span> Player accepts → tracked in active_bounties<br>
  <span class="flow-arrow">→</span> Kills in zone increment counter automatically<br>
  <span class="flow-arrow">→</span> Turn in at Guild Commander → earn Scripts<br>
  <span class="flow-arrow">→</span> end_day() writes completed data → LLM reads it
</div>

<div class="key-val"><span class="kv-key">Small contract</span><span class="kv-val" style="color:var(--green);">10 Scripts</span></div>
<div class="key-val"><span class="kv-key">Medium contract</span><span class="kv-val" style="color:var(--gold);">25 Scripts</span></div>
<div class="key-val"><span class="kv-key">Large contract</span><span class="kv-val" style="color:#e67e22;">50 Scripts</span></div>

</div>

<div class="card card-accent-teal">

## Dialogue Architecture

LLM-generated content is surgically **merged** with hardcoded role menus at runtime — preserving system reliability while the LLM controls all narrative content.

<div class="highlight-bar" style="font-size:22px;">
  Hardcoded: Sleep · Shop · Bounty Board · Goodbye<br>
  LLM-generated: <strong>greeting node + all branching conversation</strong>
</div>

Validation enforces: `greeting` + `farewell` required, no broken `next` references. Failed validation triggers an LLM repair call before falling back to the previous day's file.

</div>

</div>

</div>

<div class="footer-band">
  <div class="footer-left">
    Bradley Charles · Capstone Project 2025<br>
    Godot 4.6 · Python 3 · Ollama · Gemma 4 E4B
  </div>
  <div style="text-align:center; color:var(--gold); font-family:'Cinzel',serif; font-size:26px; letter-spacing:3px; opacity:0.6;">
    ── BARD · Erimentha ──
  </div>
  <div class="footer-right">
    Local LLM · No Cloud Dependencies<br>
    All dialogue generated nightly on-device
  </div>
</div>
