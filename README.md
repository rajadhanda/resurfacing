# Resurface

Resurface is an iOS app that makes the meaningful parts of your digital life easy to save — and even easier to act on later.

You see a recipe, a workout, a quote, a mindset idea, an article, a product tip. You think "this is useful… for future me."  

Resurface captures that moment and brings it back *at the right time* in the day, without feeds, noise, or habit-breaking friction.

### Why it exists

Most "save for later" tools just store things.  

Resurface stores things **and decides when they're actually helpful**, resurfacing a single good suggestion per time window — food, body, mind, reading.

---

## What it does

### 1. Frictionless Capture

You can save content in two ways:

- **Share Sheet** → "Save to Resurface"  

  Works in Safari, Chrome, TikTok, Instagram, YouTube, blogs — anything with a URL or text.

- **Quick Save Shortcut** (optional)  

  Power users can bind it to Back Tap or a custom gesture. It grabs:

  - current Safari URL (if available),

  - or the clipboard text,

  - and sends it directly to the app.

No screenshots required. No inbox clutter.

---

### 2. On-Device Intelligence

Everything runs locally:

- **Feature Extraction**  

  Domain, snippet, time-of-day bucket, app source, keyword flags.

- **Classification (Food / Body / Mind / Reading / Other)**  

  Lightweight on-device model (starting with a simple linear model, upgradable later).

- **Storage**  

  A clean on-device database stores items with simple lifecycle states:

  - fresh,

  - acted,

  - dismissed.

---

### 3. Smart Resurfacing

The Resurface widget shows *one* item per stack per window — not a feed.

### The Four Stacks

Resurface organizes content into four main stacks:

- **Food** – recipes / cooking ideas  
  Surfaces during meal planning windows (typically evening).

- **Body** – workouts / physical routines  
  Surfaces during workout windows (typically morning or afternoon).

- **Mind** – quotes / mindset / reflection  
  Surfaces during reflection windows (typically morning).

- **Reading** – news / articles / long-form reading  
  Surfaces during morning windows and commute windows when users have time for deeper content consumption.

A scoring model chooses the most relevant item using signals like:

- freshness,

- context,

- repeated dismissals,

- recently-shown penalty (strong),

- past interactions.

The result: resurfacing that nudges, not nags.

---

## Project Structure (Short Overview)

```text

Resurface/

├── README.md

├── ARCHITECTURE.md

├── ResurfaceApp/                  # main app target

├── ResurfaceShareExtension/       # share-sheet save flow

└── ResurfaceWidgets/              # WidgetKit integration

⸻

MVP Focus

The first milestone is simple:

	•	Save → classify → store → resurface.

	•	Clean domain types.

	•	Minimal UI (just widgets + a debug screen).

	•	Zero cloud dependency.

	•	Zero OCR until later versions.

Once the pipeline is stable, we iterate fast on:

	•	nicer UI,

	•	more signals,

	•	richer structured extraction,

	•	better widget adaptivity.

⸻

Status

Currently building:

Domain types → capture flow → classification stub → storage layer.

Next:

Behaviour engine → widget integration.

