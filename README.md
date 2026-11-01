# Offers Platform Workspace

Home base for **Customer Spend Analytics v3**: a card-linked offers platform between ABC Bank and merchants. This repo holds the project-wide docs, the story drafts, and the shared GitHub setup. The code lives in the repos listed below.

> All companies, people, and figures in this project are fictional or illustrative.

## Repositories

| Repo | What it holds |
|---|---|
| [`offers-platform-workspace`](https://github.com/Lakshmi100/offers-platform-workspace) (this one) | Roadmap, business problem, architecture, ADRs, spike write-ups, story drafts, issue templates, shared labels |
| [`aws-foundations`](https://github.com/Lakshmi100/aws-foundations) | Organization-wide AWS setup shared by every project: the organization and its accounts, Identity Center, budgets and anomaly alerts, the organization CloudTrail trail |
| [`abc-bank`](https://github.com/Lakshmi100/abc-bank) | The bank's side: Terraform for the ABC Bank account, core-banking Postgres schema, synthetic data generator, DMS CDC, file exchange |
| [`customer-spend-analytics`](https://github.com/Lakshmi100/customer-spend-analytics) | The Offers Platform (v1/v2 code, evolving into v3): intake, lakehouse, dbt, offers, attribution, orchestration |

The list lives in [`repos.yaml`](repos.yaml). Add a new repo there and re-run the bootstrap script.

## Getting started

```bash
git clone https://github.com/Lakshmi100/offers-platform-workspace.git
cd offers-platform-workspace
./scripts/bootstrap.sh        # clones every repo in repos.yaml into ./repos/ (or pulls if already there)
```

`repos/` is git-ignored. Each child repo keeps its own history; this repo only knows where they are.

## Layout

```
docs/
  00-roadmap.md             # phases, timeline, decisions
  01-business-problem.md    # the business case and constraints
  adr/                      # architecture decision records
  spikes/                   # spike write-ups
  reference/                # source material
stories/drafts/             # stories awaiting approval, before they become issues
scripts/
  bootstrap.sh              # clone/pull all repos
  sync-labels.sh            # apply .github/labels.yml to every repo
.github/
  ISSUE_TEMPLATE/story.yml  # story form (copy into each code repo)
  labels.yml                # one label set for all repos
repos.yaml                  # repo manifest
```

## How work is tracked

Stories are **GitHub Issues** made from the Story template, in the repo where the code will land. Project-wide work (docs, ADRs) goes in this repo.

| Agile idea | GitHub |
|---|---|
| Story | Issue from the Story template, label `story` |
| Epic / phase | Milestone per phase (Phase 0 – Phase 7) |
| Estimate, sprint, status | Fields on the **Offers Platform v3** Project board |

**Approval flow.** Every story needs the approver's sign-off before work starts.

1. Draft it in `stories/drafts/` (or open it directly as an issue).
2. The issue opens with label `needs-approval`, assigned to the approver.
3. The approver comments with changes. The story is revised until they approve.
4. On approval: remove `needs-approval`, add `approved`, move to **Approved** on the board.

Board columns: **Draft → In review → Approved → In progress → Done**.
