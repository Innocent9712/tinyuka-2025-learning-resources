# Exercise: Build a Multi-Stage CI/CD Pipeline with GitHub Actions

## What you're starting with

Pick **any small app you already have** — the Notes App or Task Tracker API you Dockerized in the container exercise, the app in `cicd-hands-on/app`, or something new you write yourself. It needs to have:

- At least a handful of automated tests
- A working `Dockerfile`

If it doesn't have both yet, add them first — this exercise is about the pipeline, not the app.

The pipeline you built in `cicd-hands-on` runs tests on push. That's a CI pipeline. This exercise takes it the rest of the way to a **CD pipeline**: security gates, artifact publishing, and environment-gated deployment — the kind of workflow a real team would run, and a direct, hands-on follow-up to the Shift-Left material (`shift-left.pdf`) on where security gates belong in a pipeline.

---

## Goal

By the end, a push to `main` should automatically test, security-scan, and build+publish your app as a container image, then deploy it to a `staging` environment — with `production` deployment gated behind a manual approval step, not another push.

---

## Requirements

### 1. Triggers

- Run on `push` to `main` and on every `pull_request` targeting `main`.
- Also support a manual `workflow_dispatch` trigger.

### 2. Job 1 — Lint & Test

- Install dependencies (with caching — don't reinstall from scratch every run).
- Run your linter (if you have one) and your test suite.
- Use a **matrix build** across at least two versions of your runtime (e.g. two Node or Python versions) to confirm the app isn't accidentally version-locked.

### 3. Job 2 — Security Scan

This is the Shift-Left tie-in — recall the SAST/dependency-scanning material.

- Add a **dependency vulnerability scan** (`npm audit`, `pip-audit`, or Snyk's free tier — your choice).
- Add a **static code analysis** step (GitHub's CodeQL action is the easiest free option).
- The job must **fail the build** on any high/critical finding — don't just log it and move on. If your tool of choice doesn't fail on findings by default, configure it to.
- This job should run in parallel with Job 1, not after it — there's no dependency between linting and scanning.

### 4. Job 3 — Build & Push

- Only runs if Jobs 1 and 2 both pass, and only on pushes to `main` (not on PRs — you don't want to publish an image for every branch).
- Build the Docker image and tag it with **both** the git SHA and a `latest` tag.
- Push it to a registry — GitHub Container Registry (`ghcr.io`) is the path of least friction since it uses your existing GitHub auth, but Docker Hub is fine too.
- Registry credentials must come from GitHub **secrets**, never hardcoded.

### 5. Job 4 — Deploy to Staging

- Runs automatically after Job 3 succeeds.
- Use a GitHub **Environment** named `staging`.
- You don't need real infrastructure to deploy to — simulate the deploy (e.g. `curl` a webhook, SSH to a free-tier VM, or simply echo the image tag that "would" be deployed and write it to a file as an artifact). What matters is that the job is environment-scoped and depends on the earlier jobs.

### 6. Job 5 — Deploy to Production

- Uses a GitHub Environment named `production` with a **required reviewer** configured (Settings → Environments → protection rules) — the job must pause and wait for manual approval before running, every time.
- Trigger it either from a version tag push (`v*.*.*`) or from `workflow_dispatch` — not from an ordinary `main` push. Production deploys should be a deliberate action, not automatic.

### 7. Secrets & Environments

- `staging` and `production` should be separate GitHub Environments, each with their own secrets (even if the values happen to be the same for this exercise) — this is what makes the approval gate possible in the first place.

### 8. Status badge

- Add a build status badge to your app's README so pipeline health is visible at a glance.

---

## Suggested workflow

1. Get Jobs 1 and 2 working and green on their own before adding anything else — confirm the matrix build and the security scan both actually fail when you intentionally break something (a failing test, a deliberately vulnerable dependency).
2. Add Job 3 and confirm the image actually lands in the registry — pull it down locally and run it to prove it's real, the same way you did in the Docker exercise.
3. Add the `staging` deploy job and confirm it only fires after a successful build.
4. Set up the `production` Environment's required-reviewer rule in GitHub's UI, then add Job 5 and confirm it genuinely blocks on approval — don't just take GitHub's word for it, trigger a run and watch it pause.
5. Wire up the status badge last.

## Deliverable

A GitHub repo containing the app, its `Dockerfile`, and `.github/workflows/`, with a README explaining the pipeline stages, how to trigger a production deploy, and a screenshot or log excerpt showing the production job paused on manual approval.

## Submitting your work for review

   Use Pull Requests (PRs) to present your changes incrementally. Follow this branching strategy:

   ```
   feature/name-of-the-feature -> review -> main
   ```

   - Create a **feature branch** for each piece of work (e.g. `feature/security-scan-job`, `feature/staging-deploy`).
   - When a feature is complete, merge it into a **`review`** branch.
   - Once you're ready for feedback, open a PR from `review` → `main` and request a review.
   - Reviews will be provided as comments on that PR. You can address feedback on new fix/feature branches, merge them into the open PR, and request another round of review — or merge directly to `main` if you prefer.

   When submitting, provide links to your PRs so the progression of changes is easy to follow.
