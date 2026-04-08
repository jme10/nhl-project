from mcp import Midjourney, Figma, LLM, Filesystem
import json

mj = Midjourney()
llm = LLM(provider="claude")
fs = Filesystem()
figma = Figma()

PROJECT = "TrueLORE_Design_Lab"
DATA_FILE = f"{PROJECT}/results.json"

AGENTS = [
    {"name": "Apple", "prompt": "Evaluate for simplicity, iconic quality, Apple-level restraint."},
    {"name": "ArtDirector", "prompt": "Evaluate composition, typography, balance."},
    {"name": "Turrell", "prompt": "Evaluate light, depth, emotional resonance."},
    {"name": "Retro", "prompt": "Evaluate pixel authenticity and clarity."},
    {"name": "Critic", "prompt": "Be brutally honest. Reject mediocrity."}
]

results = []


# --- STORAGE ---
def save():
    fs.write(DATA_FILE, json.dumps(results, indent=2))


# --- PROMPT GEN ---
def gen_prompt(prev="", feedback=""):
    return llm.generate(f"""
Create a Midjourney prompt for a world-class logo.

Brand: TrueLORE

Requirements:
- "O" is a glowing portal (Carolina blue + cream)
- Blend Turrell light, Wes Anderson symmetry, SNES pixel aesthetic
- Must feel Apple-level

Previous:
{prev}

Feedback:
{feedback}

Return ONLY prompt.
""")


# --- IMAGE GEN ---
def gen_image(prompt):
    return mj.generate(prompt + " --v 6 --style raw --q 2 --ar 1:1")


# --- CRITIQUE ---
def critique(url):
    agent_data = []
    scores = []

    for a in AGENTS:
        res = llm.generate(f"""
{a['prompt']}

Evaluate this logo: {url}

Return JSON:
{{
 "score": 1-10,
 "feedback": "short critique"
}}
""")
        agent_data.append(res)
        scores.append(res["score"])

    avg = sum(scores) / len(scores)

    return avg, agent_data


# --- BADGES ---
def badge(score):
    if score >= 9: return "🥇 GOLD"
    if score >= 8: return "🥈 SILVER"
    if score >= 7: return "🥉 BRONZE"
    return ""


# --- LOOP ---
def run(n=10):
    prompt = gen_prompt()

    for i in range(n):
        img = gen_image(prompt)
        score, critiques = critique(img.url)

        entry = {
            "iteration": i,
            "prompt": prompt,
            "image": img.url,
            "score": score,
            "badge": badge(score),
            "critiques": critiques
        }

        results.append(entry)
        save()

        if score >= 8.7:
            break

        fb = [c["feedback"] for c in critiques]
        prompt = gen_prompt(prompt, fb)

    build_gallery()
    export_figma()


# --- GALLERY ---
def build_gallery():
    html = """
<html>
<head>
<title>TrueLORE Design Lab</title>
<style>
body { background:#0b0f1a; color:white; font-family:sans-serif; }
.grid { display:flex; flex-wrap:wrap; gap:20px; }
.card { width:280px; background:#111827; padding:12px; border-radius:10px; }
img { width:100%; border-radius:8px; }
.score { font-size:18px; font-weight:bold; }
button { margin:5px; }
</style>

<script>
function sortByScore() {
 let cards = Array.from(document.querySelectorAll('.card'));
 cards.sort((a,b)=>b.dataset.score - a.dataset.score);
 let grid = document.getElementById('grid');
 grid.innerHTML='';
 cards.forEach(c=>grid.appendChild(c));
}

function filter(min) {
 let cards = document.querySelectorAll('.card');
 cards.forEach(c=>{
   c.style.display = (c.dataset.score >= min) ? 'block' : 'none';
 });
}
</script>

</head>
<body>

<h1>TrueLORE Logo Lab</h1>

<button onclick="sortByScore()">Sort by Score</button>
<button onclick="filter(8)">Show ≥ 8</button>
<button onclick="filter(0)">Show All</button>

<div id="grid" class="grid">
"""

    for r in results:
        html += f"""
<div class="card" data-score="{r['score']}">
<img src="{r['image']}"/>
<div class="score">{round(r['score'],2)} {r['badge']}</div>

<details>
<summary>Prompt</summary>
<p>{r['prompt']}</p>
</details>

<details>
<summary>Critiques</summary>
{"".join([f"<p>{c['feedback']}</p>" for c in r['critiques']])}
</details>

<button onclick="window.open('{r['image']}','_blank')">Expand</button>

</div>
"""

    html += "</div></body></html>"

    fs.write(f"{PROJECT}/gallery.html", html)


# --- FIGMA ---
def export_figma():
    file = figma.create_file(PROJECT)

    frame = figma.create_frame(
        file_id=file.id,
        name="Top Logos",
        width=2000,
        height=1400
    )

    top = sorted(results, key=lambda x: x["score"], reverse=True)[:6]

    x,y=0,0
    for r in top:
        figma.add_image(
            file_id=file.id,
            frame_id=frame.id,
            image_url=r["image"],
            x=x,y=y,
            width=300,height=300
        )
        x+=320
        if x>1600:
            x=0
            y+=320

    print("Figma:", file.url)


run()
