# Story review: FND-1 AWS organization, accounts and Identity Center access

Round 1 · 2026-11-01

## Gate

The orchestrator reads this block. Keep it valid JSON and keep the keys exactly.

```json
{
  "key": "FND-1",
  "round": 1,
  "score": 34,
  "threshold": 80,
  "verdict": "NEEDS_INFO",
  "blocking": ["B1", "B5", "B6"],
  "criteria": {"C1": 10, "C2": 4, "C3": 7, "C4": 3, "C5": 5, "C6": 0, "C7": 5, "C8": 0},
  "questions": 15
}
```

## Scores

| # | Criterion | Score | Max | Evidence (quoted from the story) | Gaps |
|---|-----------|-------|-----|----------------------------------|------|
| C1 | Intent and context | 10 | 10 | "As the engineer building the Offers Platform, I want the three AWS accounts in one organization, with sign-in through IAM Identity Center, so that every later story has an account to build in…"; Context cites `docs/00-roadmap.md` §1 and §4; source is the draft path. | None. |
| C2 | Requirements | 4 | 20 | Req 1 "with … consolidated billing"; Req 3 "one user for the engineer, protected by MFA"; Req 4 "a day-to-day engineering role … that can do what Phase 2 needs (run Terraform for RDS, networking, KMS use, S3 state, DMS; connect to RDS)"; Constraints "Taggable resources carry `data-product`, `environment`, `owner`, `cost-center`." | (a) Engineering role scope is "what Phase 2 needs": no rule for IAM (creating service roles, `iam:PassRole`), Secrets Manager, EC2 (ABC-1's access path), CloudWatch Logs, KMS key creation vs use only (−4). (b) MFA rule is undefined: every sign-in or only when sign-in context changes; which MFA types are allowed (−4). (c) "consolidated billing" can be read as the Organizations `CONSOLIDATED_BILLING` feature set, which rules out Identity Center delegation, SCPs, tag policies and the FND-5 organization trail; the feature set is not stated (−4). (d) Tag values for shared, organization-wide resources are not given (what `data-product` and `environment` are for the org, accounts, permission sets and state bucket) (−4). |
| C3 | Acceptance criteria | 7 | 25 | AC1–AC10 listed. AC3 "Signing in through the Identity Center portal requires MFA." AC6 "`aws organizations list-accounts` and any Identity Center change are denied." | (a) AC3 is not pass/fail as written: it does not say which sign-in condition must prompt for MFA, and it cannot be checked by `tests/FND-1.sh` (no API reports Identity Center MFA settings) with no stated manual check (−5). (b) AC6 "any Identity Center change" is not a concrete input; the tester must pick calls (−5). (c) Tagging constraint has no criterion (−4). (d) Req 4 engineering role: the "nothing that touches … billing" rule and the Phase 2 capabilities beyond S3 and security groups (RDS, KMS use, DMS, connect to RDS) have no criterion (−4). |
| C4 | Constraints | 3 | 15 | "No IAM users and no access keys in any account, except the management account's root user, which has MFA and is not used day to day."; "The story adds no billable resource beyond what AWS Organizations and Identity Center include at no charge."; tagging and region rows. | AGENTS.md checklist: (a) Access and lock-out: no recovery path if Identity Center or a permission set breaks (root is mentioned, not named as break-glass), and nothing on how the invited Offers Platform account is reached if Identity Center fails (it has no `OrganizationAccountAccessRole` unless one is added) (−3). (b) Cost: the S3 state bucket (Req 6) and any lock store are billable and have no monthly figure (−3). (c) Audit: no statement of effect on the organization CloudTrail trail and log bucket, or "not applicable until FND-5" (−3). (d) Effect on member accounts: the Offers Platform account is existing ("current Phase 2 stack stays until retired", roadmap §1); the story does not say which existing roles, users, workloads or billing in it are reached by joining the organization and by AC7 (−3). Least privilege, no IAM users and tagging are addressed. |
| C5 | Scope boundaries | 5 | 10 | Out of scope list: CloudTrail, budgets, anomaly detection, "tag policy (FND-5)"; member-account state; GitHub Actions OIDC roles; resources inside member accounts. | (a) "tag policy (FND-5)" but FND-5's own out-of-scope list excludes "A tag policy that blocks untagged resources", so no story owns it (roadmap Spike 1 included "a basic tagging policy"). (b) Organizational units and service control policies (roadmap Phase 1 "organization structure") are neither in nor out. A reader could disagree on both (−5). |
| C6 | Dependencies and inputs | 0 | 10 | "The management account exists (the owner signs up for it by hand)."; "The Offers Platform account exists (it does today)."; "The `aws-foundations` repo exists, with the SDLC Factory installed." | Repo confirmed (this working repo). Could not confirm the management account exists (−3) or the Offers Platform account exists (−3); no read-only AWS access from the review. Implied, not listed: (a) owner access to the existing Offers Platform account to accept the organization invitation (and through what credentials, given the no-IAM-users rule) (−5); (b) existing IAM users, access keys and workloads in the Offers Platform account (v1/v2 stack, local Airflow, Snowflake integration) that AC7 and joining the organization would affect (−5). Score floored at 0. |
| C7 | Free of design | 5 | 5 | Req 6 "stored in S3 in the management account, with locking and version history, created by a small bootstrap step"; Req 5 "written down in its `README.md`". | Both trace to roadmap §1 ("remote state in S3 and locking; one state per account") and AGENTS.md layout, so they are constraints with reasons. Locking mechanism, groups vs direct assignment and managed vs custom policies are left to the architect. No deduction. |
| C8 | Open questions resolved | 0 | 5 | "Open questions: None." | Contradictions remain: Cost row ("no billable resource") vs Req 6 (S3 state bucket); Req 5 (management sign-up written in README, so part of this story) vs Depends on (management account already exists); AC7 (no IAM users in the Offers Platform account) vs Out of scope ("Any resources inside … Offers Platform accounts other than Identity Center role assignments") if that account has IAM users today (−5). |
| | **Total** | **34** | **100** | | |

## Blocking issues
| # | Issue | Where in the story |
|---|-------|--------------------|
| B1 | Contradiction: Cost row says the story adds no billable resource, but Req 6 adds an S3 state bucket (billable storage and requests). Also AC7 vs Out of scope for an Offers Platform account that may already have IAM users, and Req 5 vs Depends on for the management account sign-up. | Constraints "Cost"; Requirements 5, 6; AC7; Out of scope; Depends on |
| B5 | Changes Identity Center and permission sets; access checks exist (AC3, AC4) but the story does not say how to recover if Identity Center or a permission set breaks, for the management account or the member accounts. | Requirements 3, 4; Constraints "Network and access" |
| B6 | Adds a recurring cost (S3 state bucket, plus any lock store) without a monthly figure. | Requirement 6; Constraints "Cost" |

## Questions for the story owner
Ordered by points recovered, largest first.

| # | Resolves | Question | Why it matters |
|---|----------|----------|----------------|
| Q1 | C6, C4, C8, B1 | Does the existing Offers Platform account have IAM users, access keys or roles in use today (v1/v2 stack, local Airflow, Snowflake integration), and if so, does this story remove them, replace them, or leave them (and drop that account from AC7)? | AC7 fails or existing workloads break; Out of scope currently forbids touching that account's resources. |
| Q2 | C6 | How does the owner get into the Offers Platform account to accept the organization invitation, and is that a manual README step? | The architect must decide whether invitation acceptance is Terraform or manual, and which credentials it needs. |
| Q3 | B5, C4 | What is the recovery path if Identity Center or a permission set breaks: management root with MFA only, and for member accounts an `OrganizationAccountAccessRole` (to be created in the invited Offers Platform account too) or something else? | Without it the change can lock the owner out of member accounts; AGENTS.md makes this blocking. |
| Q4 | B6, B1, C4 | What is the monthly cost limit for the state bucket and any lock store (FND-2 uses "under $0.50 per month"), so the Cost row can be corrected? | Removes the contradiction and gives the tester a number. |
| Q5 | C3 | For AC6, which specific Identity Center and organization calls must be denied, and which billing call proves "nothing that touches … billing"? | "Any Identity Center change" cannot be tested exhaustively; billing denial has no criterion. |
| Q6 | C3, C2 | Which MFA mode is required (every sign-in, or only when sign-in context changes) and which MFA types are allowed, and may AC3 be checked manually with the result recorded in the PR? | Decides the Identity Center setting and how `tests/FND-1.sh` reports AC3. |
| Q7 | C2, C3 | Exactly which services and actions must the ABC Bank engineering role allow: may it create IAM roles (with `iam:PassRole`) for RDS and DMS, use Secrets Manager, EC2 and CloudWatch Logs, and create KMS keys or only use them? Which of these need an acceptance criterion? | "What Phase 2 needs" forces the architect to guess the policy; FND-3 and ABC-1 depend on it. |
| Q8 | C2 | Should the organization use all features or consolidated billing only? | Consolidated-billing-only blocks the FND-5 organization trail, tag policies and SCPs. |
| Q9 | C2, C3 | What tag values should the organization-wide resources carry (`data-product`, `environment`, `owner`, `cost-center`), and should an acceptance criterion check them? | Code and tests need concrete values; the tagging rule has no criterion. |
| Q10 | C4 | What is this story's effect on the organization CloudTrail trail: not applicable until FND-5, or does it rely on any existing trail in the Offers Platform account? | AGENTS.md audit item. |
| Q11 | C4 | Which existing things in the Offers Platform account change when it joins (billing moves to the management account, default SCP, any existing trail or budgets), and is that acceptable? | AGENTS.md "effect on member accounts" item; the account is live today. |
| Q12 | C5 | Who owns the tag policy: FND-1, FND-5, or nobody for now? FND-5 lists it as out of scope. | Currently no story owns it. |
| Q13 | C5 | Are organizational units and service control policies in or out of scope? | Roadmap Phase 1 lists "organization structure"; a reader could assume either way. |
| Q14 | C8, C6 | Is signing up the management account a prerequisite already done, or a step this story documents in the README? | Req 5 and Depends on say different things. |
| Q15 | C6 | Can you confirm the management account and the Offers Platform account exist today (account IDs need not be shared)? | The review could not check AWS. |

## Nice to know
- AC numbering is out of order (AC10 is listed before AC9); renumber for traceability.
- The Region constraint (`us-east-1`) has no acceptance criterion; AGENTS.md already fixes the region, so this changes nothing.
- Session duration for the administrator and engineering roles is not stated; defaults are fine for a single-engineer build.
- AC5 creates a security group; new accounts have a default VPC in `us-east-1`, but if a later story deletes it the test needs a VPC to target.
- AC10's concurrent `terraform apply` runs against the real organization; the test should make sure the first apply has nothing to change.
- Email addresses for the new ABC Bank account and the Identity Center user go in the untracked `.tfvars` (AGENTS.md); the story need not list them.
- GitHub issue list for `Lakshmi100/aws-foundations` is empty: no issues exist yet, as expected for a draft.

## Design detail to confirm
- S3 for state with locking and version history, bootstrap step: traces to roadmap §1; keep as a constraint.
- Manual steps in `README.md`: matches AGENTS.md layout; keep.
- Administrator role in all three accounts, including the management account: keep, but say it is not used day to day (it can change the organization and Identity Center).

## Earlier questions
Not applicable (round 1).
