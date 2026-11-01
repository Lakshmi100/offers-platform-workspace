# Story review: FND-2 Terraform state storage for the ABC Bank account

Round 1 · 2026-11-01

## Gate

The orchestrator reads this block. Keep it valid JSON and keep the keys exactly.

```json
{
  "key": "FND-2",
  "round": 1,
  "score": 85,
  "threshold": 80,
  "verdict": "READY",
  "blocking": [],
  "criteria": {"C1": 10, "C2": 12, "C3": 21, "C4": 12, "C5": 10, "C6": 10, "C7": 5, "C8": 5},
  "questions": 4
}
```

## Scores

| # | Criterion | Score | Max | Evidence (quoted from the story) | Gaps |
|---|-----------|-------|-----|----------------------------------|------|
| C1 | Intent and context | 10 | 10 | "As the engineer building ABC Bank's infrastructure ... so that state survives between sessions and laptops, and two runs can't corrupt it"; Context quotes roadmap §1 ("remote state in S3 and locking; one state per account", confirmed at `workspace-docs/00-roadmap.md` line 38); source draft path given | None |
| C2 | Requirements | 12 | 20 | R1 "stored in S3 in the ABC Bank account, in `us-east-1`"; R2 "the second waits or fails with a lock error"; R3 "Earlier versions of each state file are kept"; R4 "created by a small bootstrap step that is documented in `infra/README.md`"; R5 "Destroying any other `abc-bank` Terraform root never removes it" | (1) Where the bootstrap step's own Terraform state lives is not stated. R1 says state for "every `abc-bank` Terraform root" is in S3, but the bootstrap creates the bucket, and AGENTS.md forbids committing Terraform state, so local state would be lost between laptops (the problem this story solves). (2) The story implies several Terraform roots in `infra/` (bootstrap code in AC9, a "test root" in AC2/AC8, "any other `abc-bank` Terraform root" in R5), but AGENTS.md's Terraform standard is "one root per account under `infra/`". The story does not say whether the bootstrap is an allowed second root or where it lives. |
| C3 | Acceptance criteria | 21 | 25 | AC1–AC9 are pass/fail with concrete commands and expected results (e.g. AC3 "fails with a state-lock error", AC5 "all four public-access blocks enabled", AC8 "leaves the state bucket and its other state files in place") | (1) Constraint "only the ABC Bank administrator and engineering roles (FND-1) can read or write state" has no criterion. AC5 covers public access and TLS, not access by other principals in the account. |
| C4 | Constraints | 12 | 15 | All seven AGENTS.md rows present: Personal data ("resource identifiers and connection details, not personal data"), PCI ("Not applicable"), Network and access, Encryption (AWS-managed key, with reason), Cost ("Persistent ... under $0.50 per month"), Tagging ("four cost tags"), Downstream ("Not applicable") | (1) AGENTS.md's definition of done says: "For stories that create AWS resources: `terraform destroy` was run, nothing billable is left, and the session's cost is in the PR." This story creates a persistent, billable bucket that must never be destroyed, and does not say how that DoD item applies (exempt, or what is torn down instead) or whether the session's cost is recorded. |
| C5 | Scope boundaries | 10 | 10 | Out of scope: "State storage for the management and Offers Platform accounts", "Switching state encryption to the customer-managed key", "CI access to state (GitHub Actions OIDC)" | None |
| C6 | Dependencies and inputs | 10 | 10 | "FND-1: the ABC Bank account and the administrator and engineering roles." | FND-1 exists as a draft story (`workspace-stories/FND-1.md`); its R4 gives the engineering role "S3 state" access. No GitHub issues exist yet (`gh issue list -R Lakshmi100/abc-bank` returns none). No unlisted implied dependency found. Dependants FND-3, FND-4 and ABC-1 all list FND-2. |
| C7 | Free of design | 5 | 5 | R4 bootstrap "because it has to exist before any other Terraform can use it"; encryption choice "because ... FND-3 is not yet available"; S3 from the roadmap standard | No design choice without a reason that affects scoring; see "Design detail to confirm" |
| C8 | Open questions resolved | 5 | 5 | "Open questions: None." No TBDs | No internal contradiction (R2 allows "waits or fails"; AC3 picks "fails", which is a narrowing, not a contradiction) |
| | **Total** | **85** | **100** | | |

## Blocking issues
| # | Issue | Where in the story |
|---|-------|--------------------|
| | None. B1: no TBD or open question. B2: nine testable criteria. B3: FND-1 exists as a draft story. B4: nothing forbidden (the encryption exception is stated with a reason; see Nice to know). B5: no hourly-billed resources (S3 only). B6: no customer, account, card or transaction data. | |

## Questions for the story owner
Ordered by points recovered, largest first.

| # | Resolves | Question | Why it matters |
|---|----------|----------|----------------|
| Q1 | C2 | Where does the bootstrap step's own Terraform state live once the bucket exists? Realistic options: moved into the new bucket after the first apply, kept local and never committed (accepting it can be lost), or no Terraform state at all (e.g. a CLI script). | R1 says every `abc-bank` root keeps state in S3, and AGENTS.md forbids committing state. The architect would have to guess, and the tester cannot check R1 for the bootstrap. |
| Q2 | C2 | Is the bootstrap an allowed second Terraform root in the ABC Bank account, despite AGENTS.md's "one root per account under `infra/`"? If yes, where does it live, and is the "test root" in AC2/AC8 a throwaway that is not committed? | Decides the `infra/` layout that FND-3, FND-4 and ABC-1 copy (AGENTS.md: "the first story in each folder sets its pattern"). It also decides whether the reviewer flags a standards breach. |
| Q3 | C3 | What acceptance criterion proves that only the ABC Bank administrator and engineering roles can read or write state? For example: which principal, doing what, gets access denied. | The access constraint is the bucket's main security control, and state may hold connection details. Without a criterion the tester has nothing to check it against, and the architect may rely on IAM defaults alone. |
| Q4 | C4 | How does AGENTS.md's DoD item ("`terraform destroy` was run, nothing billable is left, and the session's cost is in the PR") apply to this persistent bucket? Is the bucket exempt, so that only test roots are destroyed? Should the PR record the session's cost? | Without an answer the reviewer will find the DoD unmet by design, and the implementer will not know what to tear down or report. |

## Nice to know

- R2 allows the second run to "wait or fail"; AC3 requires a failure. AC3 settles the test, but the wording could match (a lock timeout would turn a failure into a wait).
- "AWS-managed S3 key" can mean SSE-S3 (S3-managed keys) or SSE-KMS with the `aws/s3` key. AC6 accepts either, so the architect can choose. Stating which would make the later switch to the customer-managed key clearer.
- The encryption row is a stated exception to AGENTS.md's "data at rest uses the ABC Bank account's customer-managed KMS keys". The reason is sound (FND-3 depends on FND-2), but the approver should accept it on purpose. Also, the follow-up switch to the customer-managed key is out of scope in both FND-2 and FND-3, so no story owns it yet.
- How long earlier state versions are kept is not stated (indefinitely by implication). The cost is negligible at this size.
- R3's purpose is "so a damaged state can be restored", but no criterion or README step covers an actual restore. AC4 checks only that versions exist.
- AC7 checks only the bucket's tags, but the tagging constraint covers "any other resource" (e.g. a lock table, if the design uses one). Tag values are not defined anywhere, which matches FND-3, FND-4 and ABC-1.
- R5 protects the bucket from destroys of other roots, but does not say whether destroying the bootstrap itself must be blocked.
- The `us-east-1` region (R1) and the "$0.50 per month" cost limit have no acceptance criterion. Both are easy to check by inspection.

## Design detail to confirm

- **TLS-only bucket policy** (AC5: "the bucket policy denies requests that don't use TLS"). It appears only in an acceptance criterion, with no requirement or constraint behind it. Keep it as a security constraint (and add it to Network and access with its reason), or leave it to the architect.
- **Bootstrap documented in `infra/README.md`** (R4). A reason is given ("it has to exist before any other Terraform can use it"). Keep.
- **AWS-managed S3 key** (Encryption). A reason is given. Keep (see Nice to know).

## Earlier questions

First round; none.
