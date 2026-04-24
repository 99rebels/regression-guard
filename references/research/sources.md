# Regression Guard — Research Sources

Primary sources used to validate the pain point and inform design decisions.

---

## SWE-CI Paper (March 2026)

**Title:** SWE-CI: Evaluating Agent Capabilities in Maintaining Codebases via Continuous Integration
**Authors:** Researchers from Sun Yat-sen University + Alibaba Group
**arXiv:** https://arxiv.org/html/2603.03823v1
**GitHub:** https://github.com/SKYLENAGE-AI/SWE-CI

### Key Findings
- 100 tasks across 68 active Python repos on GitHub
- Tracks code evolution over average 233 days, 71 consecutive commits
- Most models: zero-regression rate < 25% (break something 3/4 tasks)
- Claude Opus 4.6: 76% zero-regression (best, but still breaks 24%)
- Uses "EvoScore" to track functional correctness across future modifications
- Dual-agent workflow: Architect Agent + Programmer Agent

### Relevance to Regression Guard
- Confirms the problem is real and measurable
- The gap between "fixing a bug" and "maintaining a codebase" is exactly what our Tier 3 deep check addresses
- The alignment check directly addresses agents "solving a different problem than asked"

---

## Lightrun 2026 State of AI-Powered Engineering Report

**Publisher:** Lightrun (survey of 200 senior DevOps/SRE leaders at large enterprises)
**Coverage:** US, UK, EU
**Source:** https://venturebeat.com/technology/43-of-ai-generated-code-changes-need-debugging-in-production-survey-finds/
**Full report:** https://lightrun.com/ebooks/state-of-ai-powered-engineering-2026/

### Key Findings
- 43% of AI code changes need manual debugging in production (after passing QA/staging)
- 0% of respondents "very confident" AI code behaves correctly once deployed
- 88% need 2-3 deployment cycles to verify a single AI fix
- 11% need 4-6 cycles
- Developers spend 38% of their week debugging AI code they didn't write
- 97% of AI SRE agents operate without significant visibility into production
- 0% of organizations have moved AI SRE tools into actual production workflows
- Amazon March 2026 outages: AI-assisted code changes caused 6.3M lost orders

### Relevance to Regression Guard
- "2-3 cycles → 1 cycle" is our primary selling point
- "38% of week lost to debugging" quantifies the time savings
- The 0% confidence figure is our urgency hook
- Amazon example is the cautionary tale for the listing page

---

## Google 2025 DORA Report

**Publisher:** Google Cloud
**Source:** https://cloud.google.com/blog/products/ai-machine-learning/announcing-the-2025-dora-report

### Key Findings
- AI adoption correlates with ~10% increase in code instability
- 30% of developers report little or no trust in AI-generated code

### Relevance to Regression Guard
- Third independent source confirming the problem
- "10% increase in instability" is a conservative framing we can use

---

## Supporting Data Points (from search synthesis, verify before using)

- AI-generated code has 1.7x more total issues than human-written code (source: Coderabbit.ai report)
- 67% of developers report increased debugging time due to AI code generation
- 43% of AI-generated code changes need manual debugging in production (confirmed above — Lightrun)
- 71% of developers refuse to merge AI code without manual review

### Usage Note
These secondary data points should be verified against primary sources before including in Agensi listing or promotional materials. The three primary sources above (SWE-CI, Lightrun, DORA) are solid.
