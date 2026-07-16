# Exercise: Architecture Diagram Design

## Context

In Advanced Topics you practiced *reading* a 3-tier architecture diagram — one was handed to you, already labeled, and you answered questions about it. This exercise flips that: you design one yourself, for two small systems.

You are **not** expected to be a system design expert — nobody doing this exercise is. You're expected to take the 3-tier model you already learned (Presentation / Application / Data) and the vocabulary below, and apply them to a slightly different situation than the textbook example. This README walks through a full worked example first, so you can see exactly what "done" looks like before you attempt your own.

Use whatever diagramming tool you're comfortable with — [Excalidraw](https://excalidraw.com) is the easiest to pick up with no account needed, [draw.io / diagrams.net](https://app.diagrams.net) has ready-made AWS icon shapes, or you can write a diagram directly in Mermaid inside a markdown file (GitHub renders it automatically). Pick whichever gets you drawing fastest — the tool doesn't matter, the labeling does.

---

## Read this first: a glossary of the pieces you'll be arranging

You don't need to memorize AWS's entire catalogue. For this exercise you'll only ever be reaching for a handful of these:

| Term | What it actually is, in one sentence |
|---|---|
| **CDN** (Content Delivery Network) | A network of servers close to users that caches and serves static files (images, JS, CSS) so requests don't have to travel all the way to your origin server. |
| **Load Balancer (ALB)** | A component that sits in front of multiple copies of your app and spreads incoming requests across them, so no single server gets overwhelmed. |
| **Cache** (e.g. Redis/ElastiCache) | A fast, in-memory store that sits *in front of* your database, holding copies of frequently-read data so you don't hit the database for the same query over and over. |
| **Read replica** | A read-only copy of your primary database that stays in sync with it. You point read-heavy queries at the replica so they don't compete with writes on the primary. |
| **Message queue / stream** (e.g. SQS, Kafka, Kinesis) | A buffer that sits between something producing data quickly and something processing it — the producer drops a message in and moves on immediately; the processor reads at its own pace. This is what lets a system absorb a burst of incoming data without falling over. |
| **Object storage** (e.g. S3) | Storage for files (images, uploaded documents, backups) — not a database, just a place to durably keep blobs of data. |
| **Serverless function** (e.g. Lambda) | A small piece of code that runs in response to an event (a file upload, a queue message) without you managing a server for it to live on. |

If a scenario needs something not on this list, a one-line description of what it does is enough — you don't need to know every configuration option, just what role it plays.

---

## Worked example: "QuickNotes" — a simple note-taking app

Before you touch the two scenarios below, walk through this one with me. It's simpler than either of your assignments, but it shows you the *process* of getting from a plain-English description to a labeled diagram.

**The scenario, in plain English:** A few thousand users write and read short text notes. Reads and writes happen at roughly the same rate, nothing is bursty, and a note doesn't need to appear instantly for other users — a few seconds of delay is fine.

**Step 1 — name the three tiers with real technology, not generic labels:**

- **Presentation tier:** users hit a **CloudFront CDN** (caches the static frontend — HTML/JS/CSS) which forwards dynamic requests to an **Application Load Balancer**.
- **Application tier:** the ALB spreads requests across 2+ copies of a **Node.js/Express API running on ECS Fargate**.
- **Data tier:** the API reads and writes to a single **PostgreSQL RDS instance**. Nothing here needs a cache or a replica — the read/write ratio is even and nothing is latency-critical, so a single database is the *simplest thing that works*, and simplest-that-works is a legitimate design decision, not a cop-out.

**Step 2 — number one request's journey:**

1. User's browser requests the app → hits CloudFront.
2. CloudFront serves the static frontend directly from its cache; the frontend calls the API.
3. API call reaches the ALB.
4. ALB forwards it to one of the Fargate tasks.
5. The Fargate task queries/writes to RDS.
6. Response flows back the same path in reverse.

**Step 3 — one failure-mode sentence:** "If the RDS instance goes down, both reads and writes fail immediately — there's no cache or replica to fall back on, so this is a single point of failure the team has consciously accepted for this app's scale."

**Step 4 — the tradeoff, in plain language:** "We didn't add a cache or read replica because reads and writes happen at similar rates and nothing here is latency-sensitive — adding either would be complexity with no real payoff at this scale. If usage grew 100x and reads started dominating, a cache would be the first thing to add."

That's the whole exercise, once, end to end. Notice what made it easy: the scenario told us the read/write pattern and the latency tolerance, and every design choice traced back to one of those two facts. Your two scenarios below work the same way — the "constraints" paragraph in each one is doing the heavy lifting; your job is to notice what it's implying and draw accordingly.

---

## Goal

Produce a labeled architecture diagram plus short written answers (a paragraph or two each — not an essay) for each of the two scenarios below.

---

## Scenario 1 (required) — "TinyLinks": a URL Shortener

Extremely read-heavy: for every link created, expect tens of thousands of redirect lookups. Writes (creating a short link) are rare and not latency-sensitive; reads (following a short link) must be near-instant at high volume.

**Hints to get you started:**
- Reread the glossary entries for **cache** and **read replica** — this scenario exists specifically to make you choose between (or combine) them. Ask yourself: if the same 5 popular links get clicked a million times, does it make sense to hit the database a million times?
- Think about what happens if a link posted on social media suddenly goes viral. Where does that burst of traffic physically land first in your diagram?

## Scenario 2 (required) — "PulseBoard": an IoT Sensor Dashboard

Thousands of devices push a small sensor reading every few seconds. Nothing needs to be processed synchronously — the dashboard just needs to reflect readings within a few seconds of arrival — but the ingestion tier must absorb bursts without dropping data or blocking the devices sending it.

**Hints to get you started:**
- Reread the glossary entry for **message queue / stream**. This scenario exists specifically to make you use one. Ask yourself: if 5,000 devices all send a reading in the same second, and your database can only comfortably handle 500 writes/second, what needs to sit between them so nothing gets dropped?
- It's fine — expected, even — for this diagram to have a component between "ingestion" and "database" that Scenario 1's diagram didn't need. That difference *is* the point of the exercise.

## Scenario 3 (stretch, optional) — "ShopCart": an E-commerce Checkout

Only attempt this once you're comfortable with Scenarios 1 and 2 — it's harder because it mixes both patterns in one system. Catalog browsing is read-heavy and can tolerate eventual consistency (a product page being a few seconds stale is fine). Checkout/payment cannot — it needs strong consistency and must never double-charge a customer, even under retries.

**Hint:** this scenario doesn't need a brand-new concept — it needs you to notice that *different parts of the same system* can make different tradeoffs. Where in your diagram does the "can be a little stale" part meet the "must be exactly right" part?

---

## Requirements (apply to each scenario you attempt)

Use the worked example above as your template — each of these maps directly to one of its four steps.

### 1. All three tiers, named concretely

Don't write "Web Servers" — write "ECS Fargate service running the Flask app, behind an ALB," the way the worked example did. Every box should name an actual technology or AWS/cloud service, not a generic category. If you're unsure which specific service to name, picking any reasonable one (AWS, GCP, or Azure equivalent) and stating it is enough — this isn't a test of AWS trivia.

### 2. A numbered request-flow

Like Step 2 in the worked example: pick one representative request (e.g. "user visits a short link" for TinyLinks) and number the arrows 1, 2, 3... showing exactly how it moves through the system and back.

### 3. One failure-mode sentence

Like Step 3: for at least one component, write one sentence on what breaks (or doesn't) if it goes down.

### 4. One tradeoff paragraph

Like Step 4: 3-5 sentences on the one or two decisions that were actually driven by *this scenario's* constraints — not a generic description of the whole diagram. If you're stuck, finish this sentence: "I added/changed ___ instead of the simpler option because the scenario said ___."

### 5. Cross-cutting concerns (optional but encouraged)

If you have time, note on the diagram (a legend or a short list is fine) where security, observability/monitoring, and CI/CD deployment would touch each tier — the same three concerns from the Advanced Topics notes. This is a bonus, not a blocker — don't let it stop you from submitting the core diagram.

---

## Suggested workflow

1. Re-read the worked example once more, and make sure you could explain each of its four steps back in your own words before starting your own.
2. For Scenario 1, write the one-sentence version of "what's the bottleneck this system will actually hit at scale?" before you draw anything. For TinyLinks, that sentence is basically given to you in the scenario description — find it.
3. Draw Scenario 1. Do the numbered request-flow and failure-mode sentence before the tradeoff paragraph — it's much easier to explain a decision once it's already on the page.
4. Do the same for Scenario 2, and explicitly compare it against Scenario 1 afterward: what stayed the same, and what had to change because of the different traffic pattern?
5. Only move on to Scenario 3 if you have time and want the extra practice — it is genuinely optional.

## Deliverable

Exported diagram images (PNG/SVG, or Mermaid source if you went that route) for each scenario attempted, plus a README with, for each scenario: the numbered request-flow, the failure-mode sentence(s), and the tradeoff paragraph.

## Submitting your work for review

   Use Pull Requests (PRs) to present your changes incrementally. Follow this branching strategy:

   ```
   feature/name-of-the-feature -> review -> main
   ```

   - Create a **feature branch** for each piece of work (e.g. `feature/tinylinks-diagram`, `feature/pulseboard-diagram`).
   - When a feature is complete, merge it into a **`review`** branch.
   - Once you're ready for feedback, open a PR from `review` → `main` and request a review.
   - Reviews will be provided as comments on that PR. You can address feedback on new fix/feature branches, merge them into the open PR, and request another round of review — or merge directly to `main` if you prefer.

   When submitting, provide links to your PRs so the progression of changes is easy to follow.
