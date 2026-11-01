# Story review: ABC-1 Core-banking Postgres database in the ABC Bank account

Round 2 · 2026-11-01

## Gate

The orchestrator reads this block. Keep it valid JSON and keep the keys exactly.

```json
{
  "key": "ABC-1",
  "round": 2,
  "score": 81,
  "threshold": 80,
  "verdict": "NEEDS_INFO",
  "blocking": ["B4"],
  "criteria": {"C1": 10, "C2": 16, "C3": 13, "C4": 12, "C5": 10, "C6": 10, "C7": 5, "C8": 5},
  "questions": 6
}
```

The score is above the threshold, but one blocking issue (B4) remains, so the verdict is NEEDS_INFO.

## Scores

| # | Criterion | Score | Max | Evidence (quoted from the story) | Gaps |
|---|-----------|-------|-----|----------------------------------|------|
| C1 | Intent and context | 10 | 10 | "**As** the ABC Bank data owner, **I want** a Postgres database for core banking … **so that** the bank's customer and transaction data has a home that the Offers Platform can later receive changes from through DMS." Context cites "`docs/00-roadmap.md` §1 and Phase 2 in §4" (checked: roadmap §1 "ABC Bank core banking on RDS Postgres; change data capture with DMS"; Phase 2 section exists). "The database is a development environment for a portfolio build, not production." | None. |
| C2 | Requirements | 16 | 20 | R1–R7. Destroy boundary is now stated: "The FND resources persist between sessions. ABC-1's Terraform is separate from them: its `terraform destroy` removes only what ABC-1 creates." R4 "An engineer can connect to it with `psql` from their laptop"; access constraint "Access through IAM Identity Center–based roles only". | (-4) Still unstated: which database user the engineer connects as in R4/AC2, how that user authenticates (master user with the AWS-stored password, IAM database authentication, other), and which Identity Center role is used. FND-1's engineering role is described as able to "connect to RDS" but its listed permissions ("run Terraform for RDS, networking, KMS use, S3 state, DMS; connect to RDS") do not mention reading the AWS-stored secret or whatever the access path needs. (The destroy-boundary conflict with AGENTS.md is handled as B4, not deducted here.) |
| C3 | Acceptance criteria | 13 | 25 | AC1–AC10, each with a concrete check, e.g. AC3 "`SHOW wal_level;` returns `logical`", AC4 "`PubliclyAccessible: false` …", AC8 "no RDS instance, RDS snapshot or EC2 instance with this story's tags remains". | (-4) R6 "sized for development and for loading scale factor 10 … a few GB" still has no criterion, and "a few GB" is not a testable value. (-4) AC8 still checks only RDS instances, RDS snapshots and EC2 instances, while R5 says "one command removes it", the cost row includes "any access path", and FND-4 says hourly-billed parts such as "ABC-1's engineer access path" are created and destroyed by ABC-1 (FND-4 puts interface endpoints, e.g. for Systems Manager, out of its scope as hourly-billed). Such resources would not be caught by AC8. (-4) The network and access constraint ("no IAM users, no long-lived access keys, no SSH keys, no NAT gateway"; "Access through IAM Identity Center–based roles only") still has no criterion; AC4 covers only public reachability. |
| C4 | Constraints | 12 | 15 | All AGENTS.md checklist items are addressed in the Constraints table, including personal data ("No data in this story. From ABC-2 on the database holds (synthetic) personal data"), PCI ("Not applicable"), encryption ("Storage and backups encrypted with the ABC Bank customer-managed KMS key"), cost ("A 3-hour session, including any access path, costs under $1"), downstream ("Must meet AWS DMS's prerequisites for a PostgreSQL CDC source"). | (-3) Unchanged from round 1: encryption covers only "storage and backups". The AWS-stored admin password (R7) and any exported database logs are also data at rest, and AGENTS.md says "data at rest uses the ABC Bank account's customer-managed KMS keys". FND-3's key policy lets "Secrets Manager" use the key, which suggests the intent, but ABC-1 does not state it. |
| C5 | Scope boundaries | 10 | 10 | "Out of scope": tables and schema (ABC-2, ABC-3), generator and loading (ABC-4, ABC-5), "DMS endpoints and tasks", "High availability (Multi-AZ), read replicas, backup tuning, production sizing", "Deploying from GitHub Actions", "The Phase 1 foundations themselves (VPC, KMS key, Terraform remote state, Identity Center)". | None. |
| C6 | Dependencies and inputs | 10 | 10 | "Depends on": FND-1 (account, Identity Center administrator and engineering roles), FND-2 (state storage), FND-3 (KMS key "looked up by alias"), FND-4 (private network "looked up by name or tag"), FND-5 (cost-allocation tags for AC9). | None. Confirmed: all five exist as draft stories in `workspace-stories/` (FND-1.md to FND-5.md), and each delivers what ABC-1 says it does (FND-3 R5 alias lookup, FND-4 R4 lookup by name or tag, FND-5 R4 tag activation, FND-2/3/4 each require that destroying another root leaves them in place). `gh issue list -R Lakshmi100/abc-bank --state all` returns no issues, so none is an issue yet; as drafts they count as other stories. The round 1 implied dependencies (the account, tag activation) are now listed. The engineering role's permission coverage is raised under C2/Q2. |
| C7 | Free of design | 5 | 5 | Design-like items carry reasons: "Amazon RDS" (roadmap decision), "Terraform under `infra/`" (AGENTS.md), `wal_level` `logical` (DMS CDC prerequisite), "generated and stored by AWS" (so the password never appears in repo, outputs or plan), FND lookups "by alias" / "by name or tag" (FND-3 R5, FND-4 R4). | None deducted; see "Design detail to confirm". |
| C8 | Open questions resolved | 5 | 5 | "## Open questions — None." No TBDs. | No contradiction inside the story text itself. The conflict between the story's separate Terraform and AGENTS.md is B4. |
| | **Total** | **81** | **100** | | |

## Blocking issues
| # | Issue | Where in the story |
|---|-------|--------------------|
| B4 | The story requires ABC-1's Terraform to be destroyable on its own, separate from the FND-2/3/4 resources that live in the same `abc-bank` repo and the same ABC Bank account. That needs a second Terraform root (or state) for the account, but AGENTS.md's coding standard says "one root per account under `infra/`" (and the roadmap says "one state per account"). AC1 itself refers to "the ABC Bank Terraform root", singular. With one root, `terraform destroy` (R5, AC8) would also remove the VPC, schedule the KMS key for deletion, and could touch the state bucket. FND-2, FND-3 and FND-4 also assume several `abc-bank` roots ("Destroying any other `abc-bank` Terraform root"). | "Depends on": "ABC-1's Terraform is separate from them: its `terraform destroy` removes only what ABC-1 creates."; AC1 "`terraform apply` in the ABC Bank Terraform root"; AC8 "`terraform destroy` completes without errors" |

## Questions for the story owner
Ordered by points recovered, largest first. B4 is listed first because it blocks the gate.

| # | Resolves | Question | Why it matters |
|---|----------|----------|----------------|
| Q1 | B4 | How should ABC-1's separate teardown fit AGENTS.md's "one root per account under `infra/`"? Realistic options: (a) amend AGENTS.md (and note the roadmap's "one state per account") to allow one root per component within the account, e.g. persistent foundations vs per-session core banking; (b) keep one root and define how per-session resources are destroyed without touching FND resources; (c) something else. AC1's "the ABC Bank Terraform root" should then match. | The architect cannot lay out `infra/` without breaking either the story or AGENTS.md, and the tester cannot write AC1/AC8 without knowing which root they run in. FND-2/3/4 depend on the same answer. |
| Q2 | C2 | For AC2, which database user does the engineer connect as, how does it authenticate (master user with the AWS-stored password, IAM database authentication, other), and which Identity Center role is used? Does FND-1's engineering role need to grant anything beyond "connect to RDS" (e.g. reading the stored secret, starting the access path)? | This decides IAM policies, secret access and the AC2 test steps. If FND-1's role lacks a needed permission, AC2 fails for a reason outside this story. |
| Q3 | C3 | What pass/fail check proves R6 ("sized for … scale factor 10 … a few GB")? Options: a minimum allocated storage in GB; a load target checked later in ABC-5; or restate R6 as a constraint bounded by the <$1 session cost, with no criterion. | As written the tester has nothing to test and the architect must invent the storage size. |
| Q4 | C3 | Should AC8 say that no billable resource carrying this story's tags remains after `terraform destroy` (covering, for example, interface endpoints, Elastic IPs, secrets, log groups), rather than only RDS instances, RDS snapshots and EC2 instances? | FND-4 makes ABC-1 responsible for its hourly-billed access path, and AGENTS.md's done list says "nothing billable is left". AC8 as written would miss such resources. |
| Q5 | C3 | Should there be an acceptance criterion for the network and access constraint, e.g. "this story creates no IAM users, IAM access keys, EC2 key pairs or NAT gateways"? | The constraint is stated but untested, so the tester would skip it or invent the check. |
| Q6 | C4 | Must the AWS-stored admin password (and any database logs exported to CloudWatch, if any) be encrypted with the ABC Bank customer-managed KMS key, or is the AWS-managed key acceptable for those? | AGENTS.md says data at rest uses the customer-managed keys; the story covers only "storage and backups". This affects the secret's configuration and could add a criterion next to AC5. |

## Nice to know
- R7/AC6 list the repo, `terraform output` and plan output, but not Terraform state. "Generated and stored by AWS" should keep the password out of state; naming state in AC6 would close the gap explicitly, especially since FND-2 encrypts state with the AWS-managed S3 key.
- Tag values (`data-product`, `environment`, `owner`, `cost-center`) are not given; AC7 only checks non-empty values, so the architect will choose them.
- The PostgreSQL major version is not pinned; AC2 accepts any DMS-supported version. Consider matching the version used in Spike 2 (CDC) if that spike happens.
- Process: the story is still a draft (`needs-approval`, "not yet an issue") and `Lakshmi100/abc-bank` has no issues. AGENTS.md says stories are approved (label `approved`) before `/story` runs, and the key `ABC-1` assumes it becomes issue #1. FND-2 to FND-4 will also be `abc-bank` issues, so the real ABC-1 issue number may differ.
- AGENTS.md says real-AWS tests run "only when the story says so". AC1–AC9 clearly need the ABC Bank account; saying so explicitly removes doubt for the tester.
- AC9 allows "an estimate if the data is not available yet". Cost Explorer only shows tag data from after activation (FND-5) and lags by up to a day; the story could name the estimate method (e.g. hourly prices × hours run).
- ABC-1 may not be the first `abc-bank` story to add code (FND-2/3/4 also live in `infra/`). Whichever comes first must add the `Makefile` AGENTS.md requires; AC10 does not mention it.
- The database owner role and extensions in `core_banking` are not stated; probably for ABC-2 to decide.

## Design detail to confirm
- "A managed PostgreSQL database (Amazon RDS)": keep as a constraint (roadmap §1 decision).
- "The admin password is generated and stored by AWS": a mechanism. The stated reason (never in repo, outputs or plan) is the real constraint; confirm whether AWS-managed generation is required or one way to meet it.
- AC3 `wal_level = logical`: keep (DMS CDC prerequisite).
- "no SSH keys" in the access constraint: implies an access path without SSH; confirm it is a constraint (AGENTS.md "no long-lived access keys") rather than a design choice.
- KMS key "looked up by alias" and network "looked up by name or tag": keep; they match FND-3 R5 and FND-4 R4.
- AC7 "Resource Groups Tagging API" and AC9 "Cost Explorer by tag": test methods; fine to keep.

## Earlier questions
Round 1 questions and whether the round 2 story answers them.

| Round 1 | Resolves | Status | Notes |
|---------|----------|--------|-------|
| Q1 | B3, C6 | Answered | Foundations are now FND-1 to FND-4, all draft stories in `workspace-stories/`. B3 cleared. |
| Q2 | C6 | Answered | The account (FND-1) and cost-allocation tag activation (FND-5) are listed. |
| Q3 | C2 | Answered, but raises B4 | Destroy boundary stated ("removes only what ABC-1 creates"; FND resources persist). Achieving it conflicts with AGENTS.md's one root per account: new Q1. |
| Q4 | C2 | Not answered | Database user, authentication and role for AC2 still unstated: new Q2. |
| Q5 | C3 | Not answered | R6 still has no criterion: new Q3. |
| Q6 | C3 | Not answered | AC8 unchanged: new Q4. |
| Q7 | C3 | Not answered | No criterion for the network and access constraint: new Q5. |
| Q8 | C4 | Not answered | Encryption still "storage and backups" only: new Q6. |
