#!/usr/bin/env python3
"""
TrueLORE Design Lab — Logo Generation Pipeline

Run modes:
  python logo_design_lab.py              # generate gallery with mock data
  python logo_design_lab.py --live       # use real APIs (requires config)

Outputs:
  results.json   — structured iteration data
  gallery.html   — open in browser to view
"""

import json
import os
import random
import math
import hashlib
import argparse
from pathlib import Path

PROJECT_DIR = Path(__file__).parent
DATA_FILE = PROJECT_DIR / "results.json"
GALLERY_FILE = PROJECT_DIR / "gallery.html"

AGENTS = [
    {"name": "Apple",       "prompt": "Evaluate for simplicity, iconic quality, Apple-level restraint."},
    {"name": "ArtDirector", "prompt": "Evaluate composition, typography, balance."},
    {"name": "Turrell",     "prompt": "Evaluate light, depth, emotional resonance."},
    {"name": "Retro",       "prompt": "Evaluate pixel authenticity and clarity."},
    {"name": "Critic",      "prompt": "Be brutally honest. Reject mediocrity."},
]

results = []


# ─── STORAGE ────────────────────────────────────────────────

def save():
    DATA_FILE.write_text(json.dumps(results, indent=2))


# ─── MOCK PROVIDERS ─────────────────────────────────────────

MOCK_PROMPTS = [
    'Minimalist wordmark "TrueLORE" with the O as a glowing Carolina blue portal radiating soft cream light, '
    "James Turrell gradient backdrop, Wes Anderson centered symmetry, subtle SNES pixel texture on letterforms, "
    "clean sans-serif, dark navy background, logo design",

    '"TrueLORE" logotype, the O is a luminous circular portal emitting Carolina blue and warm cream rays, '
    "Turrell-inspired ambient light halo, perfectly symmetrical Wes Anderson framing, fine 16-bit pixel grid overlay, "
    "Apple-level simplicity, matte black background, vector logo",

    'Iconic "TrueLORE" logo, glowing portal O with Carolina blue core fading to cream edges, '
    "Turrell light installation feel, retro SNES pixel grid at micro scale, Wes Anderson pastel accents, "
    "geometric balance, ultra-clean, dark slate background",

    '"TrueLORE" brand mark, portal O emits volumetric Carolina blue light with cream bloom, '
    "deep Turrell color field gradient behind text, pixel-perfect SNES-era detailing on serifs, "
    "Wes Anderson symmetry and color palette, refined and minimal",

    'Premium "TrueLORE" wordmark, O as radiant portal disc in Carolina blue to cream gradient, '
    "atmospheric Turrell glow, 16-bit pixel noise texture, Wes Anderson centered layout with pastel accents, "
    "Apple design language, negative space, dark background",

    '"TrueLORE" — the O is a perfectly round glowing gate, Carolina blue center with cream light spill, '
    "Turrell-style ambient field, retro pixel rendering on edges, Wes Anderson color harmony, "
    "iconic simplicity, suitable for app icon and print",

    'Refined "TrueLORE" logo, luminous O portal casting Carolina blue and cream beams outward, '
    "Turrell light depth, subtle SNES dithering pattern, balanced Wes Anderson composition, "
    "modern yet nostalgic, obsessively minimal, dark navy canvas",

    '"TrueLORE" final form — glowing O portal with Carolina blue/cream radiance, '
    "Turrell immersive light, pixel-perfect retro craft, Anderson symmetry, Apple restraint, "
    "timeless logo, dark background, world-class brand identity",
]

MOCK_FEEDBACK = {
    "Apple": [
        "Too many elements competing for attention. Simplify.",
        "Getting cleaner. The portal glow is nice but the pixel texture fights the minimalism.",
        "Strong restraint here. The O portal reads clearly at small sizes.",
        "Almost there — the cream bloom is slightly too warm. Cool it down.",
        "This has the quiet confidence of a great mark. Approved.",
    ],
    "ArtDirector": [
        "Typography needs more breathing room. Kerning is tight on the 'LO' pair.",
        "Better spacing. The symmetry is landing but the baseline feels heavy.",
        "Composition is solid. The portal O anchors the wordmark well.",
        "Good balance. Consider slightly reducing the glow radius for print.",
        "Publication-ready composition. The hierarchy is clear.",
    ],
    "Turrell": [
        "The light feels applied, not emanated. It should come from within.",
        "Better depth now — the gradient has real dimensionality.",
        "The blue-to-cream transition is getting emotional. Keep pushing.",
        "This has presence. The light feels like it occupies space.",
        "Transcendent. The O feels like looking into something infinite.",
    ],
    "Retro": [
        "The pixel grid is too subtle — I can barely see the SNES influence.",
        "Better. The dithering on the portal edge reads as authentic 16-bit.",
        "Clean pixel work. It honors the aesthetic without being costumey.",
        "The retro texture and modern form are in harmony now.",
        "Perfect fusion — this could be a title screen AND an app icon.",
    ],
    "Critic": [
        "Mediocre. I've seen a hundred glowing-letter logos. Where's the soul?",
        "Improving but still generic. The Turrell reference is surface-level.",
        "Now we're getting somewhere. The portal O actually means something.",
        "Solid work. A few more refinements and this escapes the forgettable zone.",
        "Fine. I'll allow it. This has genuine character.",
    ],
}


def generate_logo_svg(iteration, score):
    """Generate an inline SVG logo placeholder that evolves with each iteration."""
    seed = iteration * 137
    rng = random.Random(seed)

    # Colors evolve: earlier = rougher, later = more refined
    progress = min(iteration / 7, 1.0)
    blue_r, blue_g, blue_b = 74, 144, 226       # Carolina blue
    cream_r, cream_g, cream_b = 255, 253, 235    # Cream
    bg_lightness = int(11 + progress * 6)

    glow_radius = 30 + int(progress * 40)
    glow_opacity = 0.3 + progress * 0.4
    portal_r = 28 + int(progress * 12)

    # Pixel grid density increases with iteration
    pixel_count = 3 + int(progress * 12)
    pixels_svg = ""
    for _ in range(pixel_count):
        px = rng.randint(20, 280)
        py = rng.randint(20, 280)
        ps = rng.randint(2, 5)
        po = round(rng.uniform(0.05, 0.15 + progress * 0.1), 2)
        pixels_svg += f'<rect x="{px}" y="{py}" width="{ps}" height="{ps}" fill="#{cream_r:02x}{cream_g:02x}{cream_b:02x}" opacity="{po}"/>'

    # Letter spacing improves with iteration
    text_x = 150
    letter_spacing = max(0, int(8 - progress * 6))

    svg = f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 300 300" width="300" height="300">
  <rect width="300" height="300" fill="hsl(224, 30%, {bg_lightness}%)" rx="12"/>
  {pixels_svg}
  <defs>
    <radialGradient id="glow{iteration}">
      <stop offset="0%" stop-color="rgb({blue_r},{blue_g},{blue_b})" stop-opacity="{round(glow_opacity, 2)}"/>
      <stop offset="60%" stop-color="rgb({cream_r},{cream_g},{cream_b})" stop-opacity="{round(glow_opacity * 0.4, 2)}"/>
      <stop offset="100%" stop-color="rgb({cream_r},{cream_g},{cream_b})" stop-opacity="0"/>
    </radialGradient>
    <radialGradient id="portal{iteration}">
      <stop offset="0%" stop-color="rgb({blue_r},{blue_g},{blue_b})"/>
      <stop offset="100%" stop-color="rgb({cream_r},{cream_g},{cream_b})"/>
    </radialGradient>
  </defs>
  <circle cx="{text_x}" cy="140" r="{glow_radius}" fill="url(#glow{iteration})"/>
  <circle cx="{text_x}" cy="140" r="{portal_r}" fill="url(#portal{iteration})" opacity="0.9"/>
  <circle cx="{text_x}" cy="140" r="{portal_r - 8}" fill="hsl(224, 30%, {bg_lightness}%)" opacity="0.5"/>
  <text x="{text_x}" y="148" text-anchor="middle" fill="white" font-family="SF Pro Display, Helvetica Neue, Arial, sans-serif"
        font-size="36" font-weight="300" letter-spacing="{letter_spacing}">
    True<tspan fill="rgb({blue_r},{blue_g},{blue_b})" font-weight="600">L</tspan><tspan font-weight="600" fill="rgb({cream_r},{cream_g},{cream_b})">O</tspan><tspan fill="rgb({blue_r},{blue_g},{blue_b})" font-weight="600">RE</tspan>
  </text>
  <text x="{text_x}" y="240" text-anchor="middle" fill="rgba(255,255,255,0.25)" font-family="monospace" font-size="9">
    iteration {iteration} · score {score}
  </text>
</svg>'''
    return svg


def mock_gen_prompt(iteration, prev="", feedback=""):
    idx = min(iteration, len(MOCK_PROMPTS) - 1)
    return MOCK_PROMPTS[idx]


def mock_critique(iteration):
    """Scores trend upward with some noise, simulating iterative improvement."""
    agent_data = []
    scores = []

    for a in AGENTS:
        base = 5.5 + iteration * 0.45
        noise = random.uniform(-0.5, 0.5)
        score = round(min(max(base + noise, 4.0), 10.0), 1)
        scores.append(score)

        fb_list = MOCK_FEEDBACK[a["name"]]
        fb_idx = min(iteration, len(fb_list) - 1)

        agent_data.append({
            "agent": a["name"],
            "score": score,
            "feedback": fb_list[fb_idx],
        })

    avg = round(sum(scores) / len(scores), 2)
    return avg, agent_data


# ─── BADGES ─────────────────────────────────────────────────

def badge(score):
    if score >= 9:  return "\U0001f947 GOLD"
    if score >= 8:  return "\U0001f948 SILVER"
    if score >= 7:  return "\U0001f949 BRONZE"
    return ""


# ─── MAIN LOOP ──────────────────────────────────────────────

def run(n=8):
    random.seed(42)
    prompt = mock_gen_prompt(0)

    for i in range(n):
        score, critiques = mock_critique(i)
        svg = generate_logo_svg(i, score)

        entry = {
            "iteration": i,
            "prompt": prompt,
            "svg": svg,
            "score": score,
            "badge": badge(score),
            "critiques": critiques,
        }

        results.append(entry)
        save()

        print(f"  Iteration {i}: score {score} {badge(score)}")

        if score >= 8.7:
            print(f"  Target reached at iteration {i}!")
            break

        fb = [c["feedback"] for c in critiques]
        prompt = mock_gen_prompt(i + 1, prompt, fb)

    build_gallery()
    print(f"\n  Gallery → {GALLERY_FILE}")
    print(f"  Data    → {DATA_FILE}")


# ─── GALLERY ────────────────────────────────────────────────

def build_gallery():
    cards_html = ""
    for r in results:
        # Encode SVG as data URI
        import base64
        svg_b64 = base64.b64encode(r["svg"].encode()).decode()
        img_src = f"data:image/svg+xml;base64,{svg_b64}"

        critiques_html = ""
        for c in r["critiques"]:
            critiques_html += (
                f'<div class="critique">'
                f'<span class="agent-name">{c["agent"]}</span>'
                f'<span class="agent-score">{c["score"]}</span>'
                f'<p>{c["feedback"]}</p>'
                f'</div>'
            )

        badge_html = f'<span class="badge">{r["badge"]}</span>' if r["badge"] else ""

        cards_html += f'''
    <div class="card" data-score="{r['score']}" data-iteration="{r['iteration']}">
      <div class="card-img">
        <img src="{img_src}" alt="Iteration {r['iteration']}"/>
      </div>
      <div class="card-body">
        <div class="score-row">
          <span class="score">{r['score']}</span>
          {badge_html}
          <span class="iteration">#{r['iteration']}</span>
        </div>
        <details>
          <summary>Prompt</summary>
          <p class="prompt-text">{r['prompt']}</p>
        </details>
        <details>
          <summary>Critiques ({len(r['critiques'])} agents)</summary>
          <div class="critiques">{critiques_html}</div>
        </details>
      </div>
    </div>'''

    html = f'''<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8"/>
<meta name="viewport" content="width=device-width, initial-scale=1.0"/>
<title>TrueLORE Design Lab</title>
<style>
  :root {{
    --bg: #0b0f1a;
    --card-bg: #111827;
    --card-hover: #1a2234;
    --blue: #4a90e2;
    --cream: #fffde8;
    --text: #e2e8f0;
    --text-dim: #64748b;
    --gold: #fbbf24;
    --silver: #94a3b8;
    --bronze: #d97706;
    --radius: 12px;
  }}

  * {{ margin: 0; padding: 0; box-sizing: border-box; }}

  body {{
    background: var(--bg);
    color: var(--text);
    font-family: -apple-system, BlinkMacSystemFont, "SF Pro Display", "Segoe UI", Roboto, sans-serif;
    padding: 40px 24px;
    min-height: 100vh;
  }}

  .container {{
    max-width: 1400px;
    margin: 0 auto;
  }}

  header {{
    text-align: center;
    margin-bottom: 48px;
  }}

  h1 {{
    font-size: 2.4rem;
    font-weight: 200;
    letter-spacing: 6px;
    margin-bottom: 8px;
  }}

  h1 .highlight {{
    color: var(--blue);
    font-weight: 600;
  }}

  .subtitle {{
    color: var(--text-dim);
    font-size: 0.95rem;
    letter-spacing: 2px;
    text-transform: uppercase;
  }}

  .controls {{
    display: flex;
    justify-content: center;
    gap: 10px;
    margin-bottom: 36px;
    flex-wrap: wrap;
  }}

  .controls button {{
    background: var(--card-bg);
    color: var(--text);
    border: 1px solid rgba(255,255,255,0.08);
    padding: 10px 20px;
    border-radius: 8px;
    cursor: pointer;
    font-size: 0.85rem;
    letter-spacing: 0.5px;
    transition: all 0.2s;
  }}

  .controls button:hover,
  .controls button.active {{
    background: var(--blue);
    color: white;
    border-color: var(--blue);
  }}

  .stats {{
    display: flex;
    justify-content: center;
    gap: 40px;
    margin-bottom: 36px;
  }}

  .stat {{
    text-align: center;
  }}

  .stat-value {{
    font-size: 2rem;
    font-weight: 600;
    color: var(--blue);
  }}

  .stat-label {{
    font-size: 0.75rem;
    color: var(--text-dim);
    text-transform: uppercase;
    letter-spacing: 1px;
    margin-top: 4px;
  }}

  .grid {{
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
    gap: 24px;
  }}

  .card {{
    background: var(--card-bg);
    border-radius: var(--radius);
    overflow: hidden;
    border: 1px solid rgba(255,255,255,0.04);
    transition: transform 0.2s, box-shadow 0.2s;
  }}

  .card:hover {{
    transform: translateY(-4px);
    box-shadow: 0 12px 40px rgba(74, 144, 226, 0.15);
  }}

  .card-img {{
    padding: 16px 16px 0;
  }}

  .card-img img {{
    width: 100%;
    border-radius: 8px;
    display: block;
  }}

  .card-body {{
    padding: 16px;
  }}

  .score-row {{
    display: flex;
    align-items: center;
    gap: 10px;
    margin-bottom: 12px;
  }}

  .score {{
    font-size: 1.6rem;
    font-weight: 700;
    color: var(--cream);
  }}

  .badge {{
    font-size: 0.85rem;
    padding: 2px 8px;
    border-radius: 4px;
    background: rgba(251, 191, 36, 0.15);
    color: var(--gold);
  }}

  .iteration {{
    margin-left: auto;
    color: var(--text-dim);
    font-size: 0.8rem;
    font-family: monospace;
  }}

  details {{
    margin-top: 8px;
  }}

  summary {{
    cursor: pointer;
    color: var(--blue);
    font-size: 0.85rem;
    padding: 6px 0;
    user-select: none;
  }}

  summary:hover {{
    color: var(--cream);
  }}

  .prompt-text {{
    font-size: 0.8rem;
    color: var(--text-dim);
    line-height: 1.5;
    padding: 8px;
    background: rgba(0,0,0,0.3);
    border-radius: 6px;
    margin-top: 4px;
  }}

  .critiques {{
    margin-top: 4px;
  }}

  .critique {{
    padding: 8px;
    margin-bottom: 6px;
    background: rgba(0,0,0,0.2);
    border-radius: 6px;
    border-left: 3px solid var(--blue);
  }}

  .agent-name {{
    font-weight: 600;
    font-size: 0.8rem;
    color: var(--blue);
    margin-right: 8px;
  }}

  .agent-score {{
    font-size: 0.75rem;
    color: var(--text-dim);
    font-family: monospace;
  }}

  .critique p {{
    font-size: 0.8rem;
    color: var(--text-dim);
    margin-top: 4px;
    line-height: 1.4;
  }}

  .progress-bar {{
    display: flex;
    justify-content: center;
    gap: 4px;
    margin-bottom: 36px;
  }}

  .progress-dot {{
    width: 40px;
    height: 6px;
    border-radius: 3px;
    background: var(--card-bg);
    position: relative;
    overflow: hidden;
  }}

  .progress-dot .fill {{
    height: 100%;
    border-radius: 3px;
    transition: width 0.3s;
  }}

  footer {{
    text-align: center;
    margin-top: 60px;
    padding: 20px;
    color: var(--text-dim);
    font-size: 0.75rem;
    letter-spacing: 1px;
  }}
</style>
</head>
<body>

<div class="container">

<header>
  <h1>True<span class="highlight">LORE</span> Design Lab</h1>
  <p class="subtitle">Iterative Logo Generation Pipeline</p>
</header>

<div class="stats">
  <div class="stat">
    <div class="stat-value">{len(results)}</div>
    <div class="stat-label">Iterations</div>
  </div>
  <div class="stat">
    <div class="stat-value">{max(r["score"] for r in results)}</div>
    <div class="stat-label">Best Score</div>
  </div>
  <div class="stat">
    <div class="stat-value">{round(sum(r["score"] for r in results) / len(results), 1)}</div>
    <div class="stat-label">Avg Score</div>
  </div>
  <div class="stat">
    <div class="stat-value">{len(AGENTS)}</div>
    <div class="stat-label">Agents</div>
  </div>
</div>

<div class="progress-bar">
  {"".join(f'<div class="progress-dot"><div class="fill" style="width:{min(r["score"]/10*100,100)}%;background:{"var(--gold)" if r["score"]>=9 else "var(--blue)" if r["score"]>=7 else "var(--text-dim)"}"></div></div>' for r in results)}
</div>

<div class="controls">
  <button onclick="sortBy('score')" class="active">Sort by Score</button>
  <button onclick="sortBy('iteration')">Sort by Iteration</button>
  <button onclick="filterMin(8)">Show &ge; 8</button>
  <button onclick="filterMin(7)">Show &ge; 7</button>
  <button onclick="filterMin(0)">Show All</button>
</div>

<div id="grid" class="grid">
{cards_html}
</div>

<footer>
  TrueLORE Design Lab &middot; {len(results)} iterations &middot; {len(AGENTS)} critique agents
</footer>

</div>

<script>
function sortBy(key) {{
  let cards = Array.from(document.querySelectorAll('.card'));
  cards.sort((a, b) => {{
    if (key === 'score') return parseFloat(b.dataset.score) - parseFloat(a.dataset.score);
    return parseInt(a.dataset.iteration) - parseInt(b.dataset.iteration);
  }});
  let grid = document.getElementById('grid');
  grid.innerHTML = '';
  cards.forEach(c => grid.appendChild(c));
  document.querySelectorAll('.controls button').forEach(b => b.classList.remove('active'));
  event.target.classList.add('active');
}}

function filterMin(min) {{
  document.querySelectorAll('.card').forEach(c => {{
    c.style.display = parseFloat(c.dataset.score) >= min ? '' : 'none';
  }});
  document.querySelectorAll('.controls button').forEach(b => b.classList.remove('active'));
  event.target.classList.add('active');
}}
</script>

</body>
</html>'''

    GALLERY_FILE.write_text(html)


# ─── CLI ────────────────────────────────────────────────────

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="TrueLORE Design Lab")
    parser.add_argument("-n", type=int, default=8, help="Number of iterations (default: 8)")
    parser.add_argument("--live", action="store_true", help="Use real MCP APIs (not yet implemented)")
    args = parser.parse_args()

    if args.live:
        print("Live mode requires MCP provider configuration.")
        print("Set up Midjourney, Figma, and LLM providers first.")
        raise SystemExit(1)

    print("TrueLORE Design Lab")
    print("=" * 40)
    run(n=args.n)
