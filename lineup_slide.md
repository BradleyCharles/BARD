---
marp: true
theme: default
paginate: false
style: |
  @font-face {
    font-family: 'Almendra';
    src: url('fonts/almendra.regular.ttf');
    font-weight: 400;
  }
  @font-face {
    font-family: 'Almendra';
    src: url('fonts/almendra.bold.ttf');
    font-weight: 700;
  }
  @font-face {
    font-family: 'Xolonium';
    src: url('fonts/Xolonium-Regular.ttf');
    font-weight: 400;
  }

  section {
    width: 1920px;
    height: 1080px;
    padding: 0;
    margin: 0;
    display: flex;
    flex-direction: row;
    align-items: stretch;
    overflow: hidden;
    background: radial-gradient(ellipse at 20% 50%, #e8d9b8 0%, #d4c49a 50%, #c4b080 100%);
    font-family: 'Almendra', serif;
  }

  .left-panel {
    width: 58%;
    flex-shrink: 0;
    position: relative;
    overflow: hidden;
    border-right: 3px solid #8b6914;
    box-shadow: inset -20px 0 40px rgba(0,0,0,0.4), inset 0 0 80px rgba(0,0,0,0.25);
  }

  .left-panel img {
    width: 100%;
    height: 100%;
    object-fit: cover;
    object-position: center top;
    display: block;
  }


  .right-panel {
    flex: 1;
    display: flex;
    align-items: center;
    justify-content: center;
    padding: 36px 40px 36px 24px;
  }

  .dialogue-box {
    background: rgba(10, 8, 4, 0.91);
    border: 2px solid #8b6914;
    border-radius: 5px;
    padding: 34px 40px 30px;
    width: 100%;
    box-shadow:
      0 0 0 1px rgba(201,168,76,0.15),
      0 0 40px rgba(0,0,0,0.6),
      inset 0 0 60px rgba(0,0,0,0.4);
    position: relative;
  }

  .dialogue-box::before {
    content: '';
    position: absolute;
    inset: 4px;
    border: 1px solid rgba(139,105,20,0.25);
    border-radius: 3px;
    pointer-events: none;
  }

  .project-title {
    font-family: 'Almendra', serif;
    font-weight: 700;
    font-size: 52px;
    color: #c9a84c;
    letter-spacing: 6px;
    margin: 0 0 4px 0;
    text-shadow: 0 0 20px rgba(201,168,76,0.4);
  }

  .project-subtitle {
    font-family: 'Xolonium', sans-serif;
    font-size: 15px;
    color: #9090b0;
    letter-spacing: 2px;
    text-transform: uppercase;
    margin-bottom: 16px;
  }

  .gold-rule {
    border: none;
    border-top: 1px solid #8b6914;
    margin: 0 0 20px 0;
  }

  .bullet-list {
    list-style: none;
    padding: 0;
    margin: 0 0 20px 0;
  }

  .bullet-list li {
    font-family: 'Almendra', serif;
    font-size: 21px;
    color: #e0d8c8;
    padding: 9px 0;
    border-bottom: 1px solid rgba(139,105,20,0.18);
    display: flex;
    align-items: flex-start;
    gap: 10px;
    line-height: 1.4;
  }

  .bullet-list li:last-child {
    border-bottom: none;
  }

  .bullet-list li::before {
    content: '▸';
    color: #c9a84c;
    flex-shrink: 0;
    margin-top: 1px;
  }

  .name-line {
    font-family: 'Xolonium', sans-serif;
    font-size: 15px;
    color: #c9a84c;
    letter-spacing: 2px;
    text-transform: uppercase;
    border-top: 1px solid rgba(139,105,20,0.4);
    padding-top: 14px;
    margin-top: 4px;
    display: flex;
    justify-content: space-between;
  }
---

<div class="left-panel">
  <img src="ss_dialogue.png">
</div>

<div class="right-panel">
<div class="dialogue-box">

<div class="project-title">BARD</div>
<div class="project-subtitle">Behaviourally Adaptive Reactive Dialogue</div>
<hr class="gold-rule">

<ul class="bullet-list">
  <li>A local LLM rewrites every NPC's dialogue each in-game night based on the day's events</li>
  <li>Python pipeline reads kills, bounties &amp; flags — then prompts Ollama (Gemma 4 E4B)</li>
  <li>NPC memory system extracts recollections nightly and injects them into future prompts</li>
  <li>Chronicle pipeline derives town rumors from kill history and spreads them to all NPCs</li>
  <li>Full fallback chain — retry, LLM repair, previous day's file, then static fallback</li>
  <li>No cloud, no API keys — all inference runs locally on GPU via Ollama</li>
</ul>

<div class="name-line">
  <span>Bradley Charles</span>
  <span>Capstone 2026</span>
</div>

</div>
</div>
