# Story review: FND-2 Terraform state storage for the ABC Bank account

Round 2 · 2026-11-01

## Gate

The orchestrator reads this block. Keep it valid JSON and keep the keys exactly.

```json
{
  "key": "FND-2",
  "round": 2,
  "score": 96,
  "threshold": 80,
  "verdict": "READY",
  "blocking": [],
  "criteria": {"C1": 10, "C2": 20, "C3": 21, "C4": 15, "C5": 10, "C6": 10, "C7": 5, "C8": 5},
  "questions": 1
}
```

## Scores

| # | Criterion | Score | Max | Evidence (quoted from the story) | Gaps |
|---|-----------|-------|-----|----------------------------------|------|
| C1 | Intent and context | 10 | 10 | "As the engineer building ABC Bank's infrastructure ... so that state survives between sessions and laptops, and two runs can't corrupt it"; Context quotes the roadmap standard ("one state bucket per account, with separate Terraform roots for long-lived foundations and per-session resources"), confirmed verbatim at `workspace-docs/00-roadmap.md` line 38; source draft path given; dependants named ("FND-3, FND-4, ABC-1 onwards") | None |
| C2 | Requirements | 20 | 20 | R1 "stored in S3 in the ABC Bank account, in `us-east-1`"; R2 "the second waits or fails with a lock error"; R3 "Earlier versions of each state file are kept"; R4 "created by its own Terraform root, `infra/bootstrap/`, documented in `infra/README.md` ... the bootstrap's own state is moved into it"; R5 "Destroying any other `abc-bank` Terraform root never removes it"; access, TLS and encryption rules in Constraints | None that would change design or tests. The round 1 gaps (bootstrap's own state; bootstrap as a separate root) are now answered by R4 and by AGENTS.md "Terraform roots". |
| C3 | Acceptance criteria | 21 | 25 | AC1–AC9 are pass/fail with concrete commands and expected results: AC2a "`terraform state list` in `infra/bootstrap/` works from a fresh clone"; AC3 "fails with a state-lock error"; AC7a "`s3:GetObject` and `s3:PutObject` on state allowed for the administrator and engineering roles, and denied for any other role ... apart from `OrganizationAccountAccessRole` and AWS service-linked roles"; AC8 "leaves the state bucket and every other root's state file in place"; AC8a "under $0.50" | (1) The Network and access constraint says `OrganizationAccountAccessRole` "for recovery, can read or write state", but no criterion checks that it is allowed. AC7a only exempts it from the deny check. A bucket policy with an explicit deny could lock out the recovery role and still pass every criterion. (-4) |
| C4 | Constraints | 15 | 15 | All seven AGENTS.md rows: Personal data ("resource identifiers and connection details, not personal data"); PCI ("Not applicable"); Network and access ("never public", named roles only, TLS required); Encryption (AWS-managed S3 key, with reason: FND-3 "not yet available when state is first created"); Cost ("Long-lived root ... under $0.50 per month; the PR states the expected monthly cost"); Tagging ("four cost tags"); Downstream ("Not applicable") | None. The round 1 DoD gap is answered: AGENTS.md now has a long-lived-root DoD (monthly cost in PR, `terraform plan` clean), and the story declares a long-lived root. |
| C5 | Scope boundaries | 10 | 10 | Out of scope: "State storage for the management and Offers Platform accounts", "Switching state encryption to the customer-managed key", "CI access to state (GitHub Actions OIDC)" | None |
| C6 | Dependencies and inputs | 10 | 10 | "FND-1: the ABC Bank account and the administrator and engineering roles." | Confirmed: FND-1 exists as a draft story (`workspace-stories/FND-1.md`). Its R4 gives the engineering role "read and write the ABC Bank Terraform state bucket"; its R6 covers `OrganizationAccountAccessRole` in the ABC Bank account. No GitHub issues exist yet (`gh issue list -R Lakshmi100/abc-bank --state all` returns none). Dependants FND-3, FND-4 and ABC-1 list FND-2. `infra/` does not exist yet, as expected. |
| C7 | Free of design | 5 | 5 | `infra/bootstrap/` is the path AGENTS.md "Terraform roots" names; the bootstrap root "because it has to exist before any other root can use it"; AWS-managed key with reason; TLS "so state is encrypted in transit as well as at rest"; lock store left to design ("any lock store if the design uses one") | No design choice without a reason; see "Design detail to confirm" |
| C8 | Open questions resolved | 5 | 5 | "Open questions: None." No TBDs. The proposed default (TLS-only access) is scored as a stated requirement. | No contradiction that changes a test (see Nice to know for two wording mismatches) |
| | **Total** | **96** | **100** | | |

## Blocking issues
| # | Issue | Where in the story |
|---|-------|--------------------|
| | None. B1: no TBD, open question or contradiction. B2: every criterion is testable. B3: FND-1 exists as a draft story. B4: nothing forbidden; the encryption exception to AGENTS.md's customer-managed-key rule is stated with a reason. B5: no hourly-billed resources (S3, and at most an on-demand lock store). B6: no customer, account, card or transaction data. | |

## Questions for the story owner
Ordered by points recovered, largest first.

| # | Resolves | Question | Why it matters |
|---|----------|----------|----------------|
| Q1 | C3 | Should a criterion check that `OrganizationAccountAccessRole` can read and write state (for example, `simulate-principal-policy` shows `s3:GetObject` and `s3:PutObject` allowed for it)? | The constraint makes it the recovery path, but AC7a only leaves it out of the deny check. A tight bucket policy could lock it out, and no test would catch that before it is needed. |

## Nice to know

- **Service-linked roles:** AC7a exempts "AWS service-linked roles" from the deny check, but the Network and access constraint lists only the administrator, engineering and `OrganizationAccountAccessRole` roles. The criterion is looser than the constraint. The wording could match.
- **Lock access for the engineering role:** FND-1 R4 grants the engineering role access to "the ABC Bank Terraform state bucket" only. If the design uses a separate lock store (e.g. a DynamoDB table) and not S3-native locking, FND-1 gives that role no access to it. AC7a checks only `GetObject`/`PutObject`. The lock mechanism, and any matching FND-1 change, are for the architect to settle.
- **AC6 always passes:** S3 encrypts every new object at rest by default. AC6 cannot fail unless someone sets a stricter setting, so it adds little beyond what is already stated. Also, "AWS-managed S3 key" can mean SSE-S3 or SSE-KMS with `aws/s3`. Both are accepted, but naming one would make the later switch to the customer-managed key clearer. (Carried over from round 1.)
- **No owner for the customer-managed-key switch:** both FND-2 and FND-3 list it as out of scope, so no story owns it yet. (Carried over.)
- **Wait or fail:** R2 allows the second run to "wait or fail", and AC3 requires a failure. AC3 settles the test. (Carried over.)
- **Version retention and restore:** how long earlier state versions are kept is not stated (indefinitely by implication; the cost is negligible). No criterion or README step covers an actual restore; AC4 checks only that versions exist. (Carried over.)
- **Destroying the bootstrap itself:** R5 protects the bucket from destroys of other roots, but does not say whether destroying `infra/bootstrap/` itself should be blocked. (Carried over.)
- **Region:** `us-east-1` (R1) has no criterion; it is easy to check by inspection. (Carried over.)
- **Clean plan after apply:** AGENTS.md's long-lived-root DoD ("`terraform plan` shows no changes after apply") has no matching criterion here. The DoD applies anyway. FND-1 has it as AC13.

## Design detail to confirm

- **Access enforced through the bucket policy** (AC5 "the bucket policy denies requests that don't use TLS"; AC7a "with the bucket policy"). The reasons (TLS in transit, only named roles) are stated. Keep it as a constraint, or reword the criteria so the architect can choose where access is enforced.
- **`infra/bootstrap/` documented in `infra/README.md`** (R4). AGENTS.md names this path, and a reason is given. Keep.
- **AWS-managed S3 key** (Encryption). A reason is given. Keep.

## Earlier questions

| Round 1 | Question (short) | Status |
|---------|------------------|--------|
| Q1 (C2) | Where does the bootstrap's own state live? | **Answered.** R4: "the bootstrap's own state is moved into it, so no state is kept only on a laptop"; checked by AC2a. |
| Q2 (C2) | Is the bootstrap an allowed second root, where does it live, and is the test root a throwaway? | **Answered.** R4 names `infra/bootstrap/`; AGENTS.md "Terraform roots" now allows bootstrap, long-lived and session roots in one state bucket; AC2: "throwaway test root (created for this check and deleted after)". |
| Q3 (C3) | Which criterion proves that only the administrator and engineering roles can read or write state? | **Answered.** AC7a added. A remaining gap on the recovery role is raised as round 2 Q1. |
| Q4 (C4) | How does the destroy / session-cost DoD apply to a bucket that must persist? | **Answered.** AGENTS.md DoD now separates session roots from long-lived roots; the story's Cost row declares a long-lived root, and AC8a requires the monthly cost in the PR. |

Round 1 design detail "TLS-only bucket policy appears only in a criterion" is also resolved: TLS is now in the Network and access constraint with its reason, and is a proposed default for the approver to confirm.
