# Story review: ABC-1 Core-banking Postgres database in the ABC Bank account

Round 1 · 2026-11-01

## Gate

The orchestrator reads this block. Keep it valid JSON and keep the keys exactly.

```json
{
  "key": "ABC-1",
  "round": 1,
  "score": 67,
  "threshold": 80,
  "verdict": "NEEDS_INFO",
  "blocking": ["B3"],
  "criteria": {"C1": 10, "C2": 12, "C3": 13, "C4": 12, "C5": 10, "C6": 0, "C7": 5, "C8": 5},
  "questions": 8
}
```

## Scores

| # | Criterion | Score | Max | Evidence (quoted from the story) | Gaps |
|---|-----------|-------|-----|----------------------------------|------|
| C1 | Intent and context | 10 | 10 | "**As** the ABC Bank data owner, **I want** a Postgres database for core banking … **so that** the bank's customer and transaction data has a home that the Offers Platform can later receive changes from through DMS." Context cites "`docs/00-roadmap.md` §1 and Phase 2 in §4" (checked: roadmap §1 "ABC Bank core banking on RDS Postgres; change data capture with DMS", §4 Phase 2). "ABC-2 to ABC-5 … build on it." | None. |
| C2 | Requirements | 12 | 20 | R1–R7, e.g. R5 "One command creates everything this story needs, and one command removes it."; R4 "An engineer can connect to it with `psql` from their laptop"; R7 "The admin password is generated and stored by AWS." | (-4) What "one command removes it" may remove is undefined: AGENTS.md requires "one root per account under `infra/`", and the Phase 1 VPC, KMS key and state backend for this account would plausibly sit in that same root, so `terraform destroy` (AC8) could take them with it. (-4) R4/AC2 do not say which database user the engineer connects as, how that user authenticates (master password from the AWS-stored secret, IAM database auth, other), or which Identity Center permission set is allowed to. |
| C3 | Acceptance criteria | 13 | 25 | AC1–AC10, each with a concrete check, e.g. AC3 "`SHOW wal_level;` returns `logical`", AC4 "`PubliclyAccessible: false`, and no security group … allows inbound traffic from `0.0.0.0/0` or `::/0`". | (-4) R6 "sized for development and for loading scale factor 10 … a few GB" has no criterion; "a few GB" is not a testable value. (-4) AC8 checks only "no RDS instance, RDS snapshot or EC2 instance" remains, but R5 says one command removes everything, AGENTS.md's done list says "nothing billable is left", and the cost row says "including any access path": without a NAT gateway an access path may use other hourly-billed resources (e.g. interface endpoints) that AC8 would not catch. (-4) The network and access constraint ("no IAM users, no long-lived access keys, no SSH keys, no NAT gateway"; "Access through IAM Identity Center–based roles only") has no criterion. |
| C4 | Constraints | 12 | 15 | Constraints table covers every AGENTS.md checklist item: personal data ("No data in this story … encryption and access rules apply from creation"), PCI ("Not applicable"), network and access, encryption ("Storage and backups encrypted with the ABC Bank customer-managed KMS key"), cost ("created per working session and destroyed after … under $1"), tagging, downstream ("Must meet AWS DMS's prerequisites for a PostgreSQL CDC source"). Scale: R6. | (-3) Encryption covers only "storage and backups". The AWS-generated admin password (R7) is also data at rest, and AGENTS.md says "data at rest uses the ABC Bank account's customer-managed KMS keys"; the story does not say which key protects the stored secret (or any logs the database exports). |
| C5 | Scope boundaries | 10 | 10 | "Out of scope": tables and schema (ABC-2, ABC-3), generator and loading (ABC-4, ABC-5), DMS endpoints and tasks, Multi-AZ/replicas/backup tuning/production sizing, GitHub Actions deploys, "The Phase 1 foundations themselves". | None that would change design or tests (see Nice to know). |
| C6 | Dependencies and inputs | 0 | 10 | "Phase 1 foundations in the ABC Bank account: VPC with private subnets, the ABC Bank customer-managed KMS key, Terraform remote state, and Identity Center access. **These are not yet stories.**" | (-12, floored at 0) None of the four listed dependencies could be confirmed: the repo has no `infra/` or other code, `gh issue list -R Lakshmi100/abc-bank --state all` returns no issues, and the roadmap schedules Phase 1 for Nov 2 – Nov 8 (not started). Implied but not listed: the ABC Bank AWS account itself (roadmap Spike 1; no spike write-up in `workspace-docs/spikes/`), and user-defined cost-allocation tags activated for Cost Explorer, which AC9's "Cost Explorer by tag" needs. |
| C7 | Free of design | 5 | 5 | Design-like items each carry a reason: "Amazon RDS" (roadmap decision), "Terraform under `infra/`" (AGENTS.md), `wal_level` `logical` (DMS CDC prerequisite), "generated and stored by AWS" (so the password "never appears in the repo, in Terraform outputs, or in plan output"). | None deducted; see "Design detail to confirm". |
| C8 | Open questions resolved | 5 | 5 | "## Open questions — None." No TBDs. | No explicit contradiction in the story text. The destroy-scope ambiguity is under C2. |
| | **Total** | **67** | **100** | | |

## Blocking issues
| # | Issue | Where in the story |
|---|-------|--------------------|
| B3 | The listed dependencies (Phase 1 VPC with private subnets, customer-managed KMS key, Terraform remote state, Identity Center access) do not exist and are not stories. The story says so itself, and the repo has no GitHub issues. | "Depends on": "**These are not yet stories.**"; AC1 "In an ABC Bank account that has the Phase 1 foundations" |

## Questions for the story owner
Ordered by points recovered, largest first.

| # | Resolves | Question | Why it matters |
|---|----------|----------|----------------|
| Q1 | B3, C6 | For each Phase 1 foundation ABC-1 relies on (VPC with private subnets, ABC Bank customer-managed KMS key, Terraform remote state, Identity Center access), which story or issue delivers it, and in which repo? Must each one be done before ABC-1 starts? | AC1 cannot pass without them. Until they exist as stories, the gate is blocked and the architect cannot know the names, IDs or outputs (subnet IDs, key ARN, state backend) to build against. |
| Q2 | C6 | Does ABC-1 also depend on (a) the ABC Bank AWS account from Spike 1 still existing, and (b) user-defined cost-allocation tags being activated for Cost Explorer (needed for AC9's "Cost Explorer by tag")? If so, add them to "Depends on" with their source. | They are implied but not listed. Tag activation is done at the billing/management level and takes time to show data, so AC9 could fail for a reason outside this story. |
| Q3 | C2 | Will the Phase 1 foundations for this account live in the same ABC Bank Terraform root as this database (AGENTS.md: "one root per account")? If so, what must `terraform destroy` in R5/AC8 remove, and what must survive it (VPC, KMS key, state backend)? | If they share a root, a plain `terraform destroy` would also delete the VPC and schedule the KMS key for deletion. The architect would have to guess the teardown boundary, and the tester the AC8 scope. |
| Q4 | C2 | For AC2, which database user does the engineer connect as, and how does that user authenticate (e.g. the master user with the AWS-stored password, or IAM database authentication)? Which Identity Center permission set may get the credentials or path? | This decides the IAM policies, secret access and test steps for AC2. The tester would otherwise have to ask "connect as whom?". |
| Q5 | C3 | What pass/fail check proves R6 ("sized for … scale factor 10 … a few GB")? Options: a minimum allocated storage in GB; a load-time target checked later in ABC-5; or restate R6 as a constraint bounded by the <$1 session cost, with no criterion. | As written, the tester has nothing to test and the architect must invent the storage size. |
| Q6 | C3 | Should AC8 say that no billable resource carrying this story's tags remains after `terraform destroy` (covering, for example, interface endpoints, Elastic IPs, secrets, log groups), rather than only RDS instances, RDS snapshots and EC2 instances? | R5 and AGENTS.md's done list ("nothing billable is left") are broader than AC8. An access path without a NAT gateway may use hourly-billed resources that AC8 would miss. |
| Q7 | C3 | Should there be an acceptance criterion for the network and access constraint, e.g. "no IAM users, IAM access keys, EC2 key pairs or NAT gateways are created by this story"? | The constraint is stated but untested, so the tester would either skip it or invent the check. |
| Q8 | C4 | Must the AWS-stored admin password (and any database logs exported to CloudWatch, if any) be encrypted with the ABC Bank customer-managed KMS key, or is the AWS-managed key acceptable for those? | AGENTS.md says data at rest uses the customer-managed keys. The story covers only "storage and backups", so the architect would have to guess the key for the secret, which also affects the key policy. |

## Nice to know
- Tag values are not given (`data-product`, `environment`, `owner`, `cost-center`). AC7 only checks for non-empty values, so the architect will choose the values unless the story or a Phase 1 tagging policy names them.
- The PostgreSQL major version is not pinned. AC2 accepts any version DMS supports. Consider stating whether it should match the version used in Spike 2 (CDC).
- Process: the story is a draft (`needs-approval`, "not yet an issue"), and `Lakshmi100/abc-bank` has no issues. AGENTS.md says stories are approved (label `approved`) before `/story` runs, and the key `ABC-1` assumes it becomes issue #1. This does not affect design or tests, but the orchestrator may want approval before design.
- AGENTS.md says real-AWS tests run "only when the story says so". AC1–AC9 clearly require the real ABC Bank account. Saying so explicitly would remove any doubt for the tester.
- AC9 allows "an estimate if the data is not available yet" because Cost Explorer data lags. The story could name the estimate method (e.g. hourly prices × hours run).
- This is the first story adding code. AGENTS.md requires that story to add a `Makefile` with `make test` and `make lint`. AC10 covers `terraform fmt`/`validate` but does not mention the Makefile.
- The database owner role and any extensions in `core_banking` are not stated. These are probably for ABC-2 to decide.

## Design detail to confirm
- "A managed PostgreSQL database (Amazon RDS)": keep as a constraint (roadmap §1 decision).
- "The admin password is generated and stored by AWS": a mechanism choice. The stated reason (never in repo, outputs or plan) is the real constraint; confirm whether AWS-managed generation is required or just one way to meet it.
- AC3 `wal_level = logical`: keep (DMS CDC prerequisite).
- "no SSH keys" in the access constraint: implies an access path without SSH; confirm this is a constraint (AGENTS.md "no long-lived access keys") rather than a design choice.
- AC7 "Resource Groups Tagging API" and AC9 "Cost Explorer by tag": test methods; fine to keep.

## Earlier questions
None (round 1).
