# Resurface — Architecture Overview

This document describes the system architecture of Resurface at an MVP level.  

The goal is to ship a fast, stable, on-device-first experience with minimal friction and predictable behaviour.

---

# 1. Principles

### 1. On-Device First

Classification, scoring, and resurfacing run locally for:

- privacy,

- speed,

- offline resilience,

- lower system complexity.

### 2. Frictionless Capture

Saving content should be:

- fast,

- context-aware,

- less annoying than the alternatives.

### 3. One Good Suggestion

Resurface surfaces:

- one Food item at meal windows,

- one Body item at workout windows,

- one Mind item at reflection windows,

- one Reading item at morning/commute windows.

No feed, no browse-first design.  

You act or dismiss.

---

# 2. High-Level Architecture

```text

            ┌──────────────────┐

            │  User Action      │

            │  (Share / Quick)  │

            └─────────┬────────┘

                      │

               Capture Layer

                      │

             ┌────────▼────────┐

             │  CaptureEvent    │

             └────────┬────────┘

                      │

           Processing Pipeline

                      │

     ┌────────────────▼────────────────┐

     │ FeatureExtractor → FeatureVector│

     └────────────────┬────────────────┘

                      │

               TaggingService

                      │

          simple model (MVP1)

                      │

             ClassificationResult

                      │

               StorageManager

                      │

                 StoredItem

                      │

                BehaviourEngine

                      │

                    Widget

Capture → features → classify → store → score → resurface.

⸻

3. Capture Layer

Two entrypoints:

A. Share Extension (Primary)

Most universal, most structured.

Provides:

	•	URL,

	•	text,

	•	sometimes metadata,

	•	source app bundle ID.

B. Quick Save Shortcut (Optional)

Bound manually by user to Back Tap or other triggers.

The Shortcut logic:

	1.	Try to get Safari frontmost URL

	2.	Else, get clipboard text

	3.	Call QuickSaveIntent(url:text:)

Shortcut → AppIntent → CaptureEvent.

Why not screenshot monitoring?

	•	Privacy concerns.

	•	Too much noise.

	•	Heavy to process.

	•	Unreliable across apps.

Resurface prioritises intentional saving.

⸻

4. Processing Layer

4.1 FeatureExtractor

Turns a CaptureEvent into a FeatureVector using:

	•	domain,

	•	source bundle ID,

	•	time bucket,

	•	day of week,

	•	snippet,

	•	flags (units, reps, quotes, reading markers).

No OCR by default.

OCR is a stub (Vision) but never automatically invoked.

Edge cases handled:

	•	Missing URL → domain = nil

	•	Missing text → snippet = ""

	•	Missing app → bundle = nil

4.2 TaggingService

For MVP1:

	•	simple linear model or logistic regression (tiny, fast, 100% on-device).

Goal:

Infer category (recipe/workout/quote/reading/none) + stack (food/body/mind/reading/other).

**Reading Category Detection**:
- Reading content is recognized based on:
  - Domain signals (news sites, blog platforms, newsletter domains).
  - Content markers (keywords like "article", "newsletter", "today's news").
  - Source app context (reading apps, news apps).
- Reading items map to the `.reading` stack, which has its own time windows
  optimized for longer-form content consumption.

Confidence is clamped to 0–1.

⸻

5. Storage Layer

Core Data (MVP1)

Backed by SQLite but gives:

	•	typed objects,

	•	automatic schema handling,

	•	low boilerplate,

	•	easy integration with SwiftUI and WidgetKit.

StoredItem fields:

	•	id

	•	createdAt

	•	category

	•	stack

	•	triggerType

	•	url

	•	textSnippet

	•	state

	•	timesDismissed

	•	timesActedOn

	•	lastShownAt

	•	lastActionAt

Error handling:

	•	No hard failures.

	•	Log & gracefully ignore corrupt/partial events.

	•	Always return empty array on fetch failure.

⸻

6. Behaviour Engine

Scores items to decide "what should appear in the widget right now?"

Inputs:

	•	[StackType]

	•	timestamp

	•	all stored items

Signals:

	•	Freshness boost

	•	Time-window relevance

	•	Recently-shown penalty (strong)

	•	Dismissal penalty

	•	Acted-on boost

	•	"No suggestion" if all scores sub-threshold

**Time Windows by Stack**:
- **Food**: Evening windows (dinner planning time).
- **Body**: Morning and afternoon windows (workout times).
- **Mind**: Morning windows (reflection time).
- **Reading**: Early morning and commute windows (when users have time for longer content).

These are simple defaults for MVP and can be made user-configurable later.

Output:

	•	At most one item per window.

Performance:

	•	Very cheap: linear scan over items.

⸻

7. Widgets

The widget pulls from:

	•	StorageManager → all items

	•	BehaviourEngine → best item for window

Widget displays:

	•	snippet or title

	•	stack icon

	•	main action button

	•	dismiss button

User actions update state:

	•	acted → increases timesActedOn

	•	dismissed → increases timesDismissed → lowers future score

⸻

8. Error Handling Strategy

	•	Capture layer must never block UI or crash on invalid data.

	•	Processing avoids heavy synchronous operations.

	•	Classification always returns a safe result (.none) if uncertain.

	•	Storage writes are wrapped in do/catch, with logging on failure.

	•	BehaviourEngine tolerates empty or malformed items.

⸻

9. Performance Strategy

	•	Use lightweight domain types (struct).

	•	Keep text snippets trimmed to small sizes.

	•	Avoid large ML models — MVP uses linear/logistic classifier.

	•	Avoid auto OCR — runs only when explicitly requested.

	•	Core Data fetches limited and cheap.

	•	Widget timeline pre-computed, not recomputed every second.

⸻

10. MVP Boundary

❌ No feed

❌ No editing of items

❌ No screenshot OCR

❌ No cloud sync

❌ No browsing UI

✅ Frictionless saving

✅ On-device classification

✅ On-device resurfacing

✅ Widget-first experience

---

