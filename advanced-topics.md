# Advanced Topics — Class Notes
**Cloud Engineering Programme | Month 4, Week 1 **

---

## Session Overview

This final session ties together everything covered across the programme. Rather than introducing entirely new tools, the goal is to show how Terraform, Docker, Kubernetes, CI/CD, and Observability fit together as a coherent system. We frame this through two professional disciplines: **Platform Engineering** and **Site Reliability Engineering (SRE)**.

| Part | Topic |
|------|-------|
| 01 | Platform Engineering — The Big Picture |
| 02 | SRE Fundamentals — Running What You Build |
| 03 | Architecture Diagrams — The 3-Tier App |
| 04 | Industry Landscape & Career Context |
| 05 | Open Q&A and Reflection |

---

## Part 01 — Platform Engineering

### What is Platform Engineering?

Platform Engineering is the discipline of building and maintaining the internal infrastructure and tooling that enables development teams to deploy and operate applications reliably and efficiently. The core product is an **Internal Developer Platform (IDP)** — a self-service layer that abstracts away infrastructure complexity so developers can focus on writing code.

### Connecting the Curriculum

Everything you have learned this term is a component of an IDP.

| What you learned | Its role in the platform |
|---|---|
| Terraform (IaC) | Infrastructure layer — provision cloud resources consistently and repeatably |
| Docker | Packaging layer — create portable, reproducible application images |
| Kubernetes | Compute layer — run and auto-scale containers in production |
| CI/CD Pipelines | Delivery layer — move code from commit to production safely |
| Monitoring & Observability | Feedback layer — understand system health and detect failures |

### Internal Developer Platforms in the Wild

**Backstage** (originally by Spotify, now a CNCF project) is a well-known open-source IDP. It provides a developer portal where teams can browse service catalogs, trigger deployments, view documentation, and check system health — all from one interface backed by the tools you have learned.

Key insight: the value of an IDP is not the tools themselves, but the reduction of **cognitive load** on developers. A good platform means a developer does not need to understand Terraform or Kubernetes internals to deploy a service safely.

> **Discussion Question**
> Looking at our curriculum, which layer do you think is hardest to make self-service, and why?

---

## Part 02 — SRE Fundamentals

### What is Site Reliability Engineering?

Site Reliability Engineering (SRE) applies software engineering principles to operations and infrastructure problems. The discipline was established at Google around 2003. Where a traditional operations team focuses on keeping systems running, an SRE team focuses on building systems — and automating processes — that are **reliable by design**.

### The Language of Reliability: SLIs, SLOs, and Error Budgets

| Concept | Definition |
|---|---|
| **SLI — Service Level Indicator** | A measurable signal of how well your service is performing. Examples: request success rate, response latency (p99), availability percentage. An SLI is just a metric. |
| **SLO — Service Level Objective** | A target value for an SLI. Example: "99.9% of requests must succeed" or "p99 latency must stay below 300ms". An SLO is a commitment the team makes to itself (and customers). |
| **Error Budget** | The acceptable amount of unreliability implied by your SLO. At 99.9% availability, your error budget is 0.1% — roughly 43 minutes of downtime per month. A healthy budget means faster feature delivery; an exhausted budget means focus on stability first. |

> **Example:** Instead of "the site is down too often," a team with SLOs can say: "We have consumed 70% of our error budget this month. We should delay the next release and investigate the root cause." That is a precise engineering decision, not a vague complaint.

### Toil and Automation

**Toil** is the SRE term for repetitive, manual, automatable operational work that produces no lasting value. Examples: manually restarting a service, SSH-ing into a server to check a log, running the same deployment script by hand each release.

SREs aim to keep toil below 50% of their working time. Everything in this programme is, in part, a tool for eliminating toil:

- IaC eliminates manual infrastructure provisioning
- CI/CD eliminates manual deployments
- Kubernetes self-healing eliminates manual service restarts

### Incident Management

| Practice | Description |
|---|---|
| **Runbooks** | Step-by-step guides for responding to known failure scenarios. A good runbook answers: what is this alert telling me, what are the likely causes, and what are the steps to resolve it? |
| **On-call rotations** | Distribute responsibility for responding to production alerts across the team. Being on-call is a reality of most cloud engineering roles. |
| **Blameless post-mortems** | Structured reviews after a significant incident. The goal is to understand what happened and what systemic changes will prevent recurrence — not to assign blame to individuals. |

> **Case Study Exercise:** We will walk through a documented AWS outage as a class. For each stage of the incident, consider: Which monitoring tool would have detected this first? What would the runbook entry look like? What would the post-mortem recommend?

> **Discussion Question**
> You are on-call tonight and receive an alert that p99 latency has doubled. What are your first three steps?

---

## Part 03 — Architecture Diagrams

### Why Architecture Diagrams Matter

Architecture diagrams are one of the most important communication tools in a cloud engineering team. They are used to onboard engineers, discuss design decisions, plan infrastructure changes, and document systems for compliance. A good diagram communicates structure and flow clearly — it shows what is relevant to the audience, not everything.

### The 3-Tier Application Model

The 3-tier architecture is the most common pattern for web applications. It separates concerns into three distinct layers.

| Layer | Components | Description & Curriculum Link |
|---|---|---|
| **Tier 1 — Presentation** | CDN, Load Balancer, Web Servers | The layer users interact with. Handles TLS termination, static asset delivery, and traffic distribution. *Curriculum link: your Kubernetes deployments and Docker containers live here.* |
| **Tier 2 — Application** | API Gateway, App Servers, Cache (Redis) | Where business logic runs. The API gateway handles auth and routing; app servers process requests; Redis caches frequently accessed data. *Curriculum link: CI/CD pipelines deliver new code to this tier.* |
| **Tier 3 — Data** | Primary DB, Read Replica, Object Storage | Where data lives persistently. The primary DB handles writes; replicas offload reads; object storage holds files and backups. *Curriculum link: Terraform provisions these resources as infrastructure.* |

### Cross-Cutting Concerns

Some concerns sit outside the three tiers but touch all of them:

- **Monitoring and observability** — metrics, logs, and traces flow from every tier into a centralised platform
- **Security** — IAM roles, encryption, network policies, and secrets management apply at every layer
- **CI/CD** — the pipeline delivers code changes to all three tiers, often in a coordinated sequence

### How to Read an Architecture Diagram

When presented with a diagram in an interview, design review, or onboarding, ask:

1. Where does a user request enter the system?
2. How does data flow from the user to storage and back?
3. What happens if one component fails?
4. Where are the potential bottlenecks?

---

## Part 04 — Industry Landscape & Career Context

### Role Clarity

These titles are used inconsistently across companies, but here is a rough guide to what they tend to mean in practice.

| Role | Core Focus |
|---|---|
| **Cloud Engineer** | Provisioning, managing, and optimising cloud infrastructure |
| **DevOps Engineer** | Bridging development and operations; owns the CI/CD pipeline |
| **Site Reliability Engineer (SRE)** | Reliability and scalability of production systems; on-call |
| **Platform Engineer** | Building the internal platform that other teams build on top of |

In smaller companies one person often fills all four roles. In larger organisations they are distinct teams. All four draw heavily on the skills in this programme.

### Where the Industry is Heading

| Trend | What it means for you |
|---|---|
| **Platform Consolidation** | The era of assembling dozens of individual tools is giving way to integrated platforms. Companies are investing in coherent developer experiences rather than tool sprawl. |
| **FinOps** | Cloud cost management is now a first-class engineering concern. Engineers who can read a cloud bill, attribute spend to teams, and reduce waste are increasingly valuable. |
| **AI-Assisted Operations** | AI tooling is entering the platform and operations space — from AI-assisted code review in CI pipelines to LLM-powered runbook suggestions during incidents. The fundamentals are not replaced; they are amplified. |

### Your First 90 Days

| When | Phase | Focus |
|---|---|---|
| Weeks 1–2 | Onboarding | Read documentation, get access, run existing pipelines. Resist the urge to change things immediately. |
| Weeks 3–6 | First contributions | Small infrastructure changes, fixing toil items, writing a runbook or two. |
| Weeks 7–12 | Increasing autonomy | Take on-call responsibility, contribute to design discussions, propose improvements. |

> **Tip:** The single most valuable thing you can do in your first role is to read the existing Terraform code, understand the CI/CD pipeline end to end, and know what the monitoring dashboards are telling you — before anything goes wrong.

---

## Part 05 — Open Q&A and Reflection

### Structured Reflection Exercise

Take 5 minutes individually, then share with the group:

1. Which topic from the four months would you most like to go deeper on, and why?
2. Which concept felt most abstract to you — and has it become clearer over time?
3. What is one thing you would build or automate if you started a job tomorrow?

---

> **Closing Thought**
>
> You have spent four months learning the tools that professional cloud engineers use every day. The most important thing to carry forward is not any specific tool — tools change. It is the underlying mental model:
>
> *Infrastructure is code. Delivery is automated. Reliability is measured. Platforms exist to make other engineers' lives easier.*
>
> Everything else follows from that.

---

*Cloud Engineering Programme · Advanced Topics · Month 4, Week 1*