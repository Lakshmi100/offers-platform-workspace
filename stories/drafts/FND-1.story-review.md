# Story review: FND-1 AWS organization, accounts and Identity Center access

Round 3 · 2026-11-01

## Gate

The orchestrator reads this block. Keep it valid JSON and keep the keys exactly.

```json
{
  "key": "FND-1",
  "round": 3,
  "score": 87,
  "threshold": 80,
  "verdict": "READY",
  "blocking": [],
  "criteria": {"C1": 10, "C2": 16, "C3": 21, "C4": 15, "C5": 10, "C6": 5, "C7": 5, "C8": 5},
  "questions": 3
}
```

## Scores

| # | Criterion | Score | Max | Evidence (quoted from the story) | Gaps |
|---|-----------|-------|-----|----------------------------------|------|
| C1 | Intent and context | 10 | 10 | "As the engineer building the Offers Platform, I want the three AWS accounts in one organization, with sign-in through IAM Identity Center and no IAM users anywhere, so that every later story has an account to build in…"; Context cites `docs/00-roadmap.md` §1 and §4 and describes the Offers Platform account's IAM users and keys today. | None. |
| C2 | Requirements | 16 | 20 | Req 4 ABC Bank engineering: an explicit "It can:" list incl. Session Manager / EC2 Instance Connect Endpoint, IAM roles "only with the permissions boundary below attached", `iam:PassRole` only for such roles, KMS "use (not create, delete, disable or change the policy of)", state bucket, `rds-db:connect`, Cost Explorer, Tagging API, read-only IAM. Req 4 Offers Platform engineering: "Based on AWS's `PowerUserAccess` (every service except IAM, Organizations and account management), plus creating, updating and deleting IAM roles and instance profiles only with the permissions boundary attached". Req 5 boundary denies listed. Req 3 MFA "at every sign-in, using an authenticator app or security key". Req 10 state bucket rules. | (a) Offers Platform engineering role's denials are stated only in AC7 ("the AC6 list denied"), not in Req 4. `PowerUserAccess` itself allows `sso:*`, billing (`aws-portal:*`) and all `kms:*`, so the role needs explicit denies the requirement does not name. In particular, `kms:ScheduleKeyDeletion` and `kms:PutKeyPolicy` must be denied on which keys: every KMS key in the Offers Platform account (which would stop any v1/v2 Terraform that manages its own keys) or only the ABC Bank key, which is in another account? (−4) |
| C3 | Acceptance criteria | 21 | 25 | AC1–AC16, each with a concrete command or MANUAL line. AC5 lists allowed actions for the ABC Bank role (RDS, EC2, Instance Connect endpoint, SSM, DMS, Secrets Manager, Logs, `rds-db:connect`, tagging, IAM read, `iam:CreateRole` with boundary, real `ce get-cost-and-usage`); AC6 lists denied ones incl. `sso:CreatePermissionSet`, `aws-portal:ModifyBilling`, `organizations:LeaveOrganization`, `iam:PassRole` for a role without the boundary; AC7 Offers Platform role; AC13 state; AC14 tags; AC15 cost. | (a) Req 4 bullets "use … the ABC Bank KMS key" and "read and write the ABC Bank Terraform state bucket" have no criterion here. Both resources are created later (FND-3, FND-2), and those stories check them (FND-3 AC3, FND-2 AC7a), but FND-1 does not say these checks are deferred. The tester can't tell whether `tests/FND-1.sh` must simulate them against expected ARNs or skip them (−4). |
| C4 | Constraints | 15 | 15 | Constraints table: Access and lock-out ("Recovery path as in requirement 7, checked by AC10 and AC11"), Least privilege, No IAM users or long-lived keys, Personal data ("end up in Terraform state; the state bucket's access rules (requirement 10) protect them"), Cost ("under $0.50 per month"), Tagging, Audit, Effect on member accounts, Region. | Every `AGENTS.md` checklist item is addressed. B5 is met (access checked by AC3, AC4, AC10, AC11; recovery in Req 7). B6 is met ("under $0.50 per month"; AC15). |
| C5 | Scope boundaries | 10 | 10 | Out of scope: OUs and non-default SCPs, tag policy, FND-5 guardrails, member-account state, "Narrowing the Offers Platform engineering role below `PowerUserAccess`", GitHub Actions OIDC roles, "Changes to the v1/v2 pipeline beyond switching its credentials". | None. |
| C6 | Dependencies and inputs | 5 | 10 | "Depends on: None in other stories. The manual steps in requirement 9 are part of this story and done by the owner." Context: "its Terraform creates IAM roles (for example Snowflake's S3 access role)". Cross-checked: FND-5 now says "Cost Explorer itself is enabled by FND-1"; FND-2, FND-3, FND-4, ABC-1 list FND-1 as their dependency, consistent with this story. `gh issue list -R Lakshmi100/aws-foundations --state all` returns nothing (draft, as expected). | (a) Implied, not listed: the existing IAM roles that v1/v2 Terraform creates in the Offers Platform account (for example the Snowflake S3 access role, and any Glue or other service roles). They have no permissions boundary, so under Req 4 the Offers Platform engineering role can't update, delete, or `iam:PassRole` them. v1/v2 `terraform apply` with the replacement profile (Req 6) would then fail on those roles, and Out of scope rules out changing the pipeline beyond its credentials (−5). The Offers Platform account itself is accepted on the owner's statement (not checkable here). |
| C7 | Free of design | 5 | 5 | "all features (required by Identity Center and by FND-5's organization trail)"; "Based on AWS's `PowerUserAccess`" (Decision, Nov 1, with narrowing deferred in Out of scope); permissions boundary (holds role creation, reason in Req 5 and FND-3); `OrganizationAccountAccessRole` (recovery path); bootstrap state moved into the bucket; "Checks that something is denied use `aws iam simulate-principal-policy`, never the real call". | Design details carry reasons. Policy structure, how resources from FND-2 and FND-3 are referenced, and the lock mechanism are left to the architect. |
| C8 | Open questions resolved | 5 | 5 | "Open questions: None." "Proposed defaults, for the approver to confirm" scored as stated requirements. | No TBDs. Round 2's contradiction (day-to-day use of a setup-only role) is gone. The AC7 vs `PowerUserAccess` point is scored as a missing rule under C2, not a contradiction: "Based on" allows added denies, and AC7 states the required result. |
| | **Total** | **87** | **100** | | |

## Blocking issues
| # | Issue | Where in the story |
|---|-------|--------------------|

None. B1: no unresolved question or contradiction (round 2's B1 is resolved). B2: every criterion is testable as written. B3: no listed dependency. B4: nothing forbidden; root steps are left to the owner in `README.md` (Req 9). B5: met. B6: met.

## Questions for the story owner
Ordered by points recovered, largest first.

| # | Resolves | Question | Why it matters |
|---|----------|----------|----------------|
| Q1 | C6 | How are the v1/v2 pipeline's existing IAM roles in the Offers Platform account (for example Snowflake's S3 access role) handled under the Offers Platform engineering role, which may change and pass only boundary-carrying roles? The realistic options are: the boundary is attached to them in this story (a v1/v2 Terraform change), changes to them are made with the administrator role, or the breakage is accepted until a later story. | v1/v2 `terraform apply` with the replacement profile would fail during Req 6's wait. The architect and tester otherwise guess, and one option conflicts with "no changes to the v1/v2 pipeline beyond switching its credentials". |
| Q2 | C2 | Which denies does the Offers Platform engineering role carry on top of `PowerUserAccess`: Identity Center (`sso:*`), billing, and KMS key deletion and policy changes? For KMS, do they apply to every key in the Offers Platform account, or only to keys outside the pipeline's own? | `PowerUserAccess` allows all of these, so AC7 fails unless the architect adds denies. A blanket KMS deny could break v1/v2 Terraform that manages its own keys. |
| Q3 | C3 | For the ABC Bank engineering role's KMS-key use and state-bucket read/write (Req 4), does `tests/FND-1.sh` check them (for example by simulating against the expected key alias and bucket name), or are they deferred to FND-3 AC3 and FND-2 AC7a? | The key and bucket don't exist when FND-1 is done. The tester must know whether to write these checks here and against which resource names. |

## Nice to know
- First use of RDS, DMS and EC2 Instance Connect Endpoint in the new ABC Bank account creates service-linked roles. Whether the engineering role gets `iam:CreateServiceLinkedRole` or an administrator pre-creates them is for the architect, but ABC-1 AC1 depends on it.
- AC5 checks `ec2:CreateInstanceConnectEndpoint` but not opening the tunnel (`ec2-instance-connect:OpenTunnel`). It also doesn't check `iam:PassRole` *allowed* for a boundary-carrying role, or role update/delete and instance-profile actions. Each Req 4 bullet still has a criterion.
- `aws-portal:ModifyBilling` is a legacy billing action; AWS now uses fine-grained billing actions. For the ABC Bank role it is denied by default anyway. For the Offers Platform role, the architect should deny the current billing actions too.
- AC8 "every IAM user that existed": once the users are deleted, a script cannot rebuild that list (no organization trail yet), so in practice this is a MANUAL line checked against the inventory from Req 6. "The v2 pipeline's buckets" also needs the bucket names supplied (for example from `.tfvars` or `README.md`).
- AC15 ("The PR states the expected monthly cost") can only be checked by a person, so per `AGENTS.md` it should print MANUAL. The same applies to AC11's README check if it is not grepped.
- Req 9's `README.md` list of manual steps has no criterion of its own; AC11 checks only the recovery steps.
- Req 6 "wait one working session": the duration of a "working session" is not defined. It is a proposed default and affects only timing.
- MFA types in Req 3 (authenticator app or security key) have no check; AC3 MANUAL could confirm them.
- AC5's `aws ce get-cost-and-usage` for the ABC Bank account relies on the default "linked account access" to Cost Explorer. Data can lag up to 24 hours after Cost Explorer is first enabled; "succeeds" holds even with empty results.
- AWS's centralized root access management for member accounts (removing member root credentials) is an alternative to MFA on member root users. The story's choice (MFA, no keys) is stated and testable (AC9).
- `AGENTS.md` requires this first story to add the `Makefile` (`make test`, `make lint`) and `tests/FND-1.sh`; the story need not repeat it.
- `gh issue list -R Lakshmi100/aws-foundations --state all` returns no issues, as expected for a draft.

## Design detail to confirm
- `PowerUserAccess` as the base of the Offers Platform engineering role: keep (owner decision Nov 1, 2026; narrowing deferred in Out of scope).
- Permissions boundary on roles created by engineering roles: keep (stops privilege escalation; FND-3 relies on it).
- `OrganizationAccountAccessRole` created in the invited Offers Platform account: keep (recovery path; FND-2 and FND-3 refer to it).
- S3 state with locking, version history and bootstrap state moved into the bucket: keep (roadmap §1; same pattern as FND-2).
- `simulate-principal-policy` for deny checks: keep (`AGENTS.md`: tests never make risky real calls).

## Earlier questions
| # | Round 2 question (short) | Status |
|---|--------------------------|--------|
| B1 | Day-to-day laptop tools in Offers Platform vs setup-only administrator role | **Resolved:** new Offers Platform engineering role (Req 4, Decision), Least privilege row now "Day-to-day work uses the two engineering roles", AC7, AC8. |
| Q1 | Which permission set the Offers Platform replacement profiles use | **Answered:** Offers Platform engineering, based on `PowerUserAccess` plus boundary-held role creation (Req 4, Req 6). Follow-ups are new Q1 (existing v1/v2 roles) and Q2 (its denies). |
| Q2 | Cost Explorer: FND-1 or FND-5 | **Answered:** FND-1 enables it (Req 8, Req 9 manual step, AC12); FND-5 now says "Cost Explorer itself is enabled by FND-1". |
| Q3 | Limit on IAM roles the engineering role creates | **Answered:** permissions boundary (Req 5); create/update/delete roles and instance profiles and `iam:PassRole` only with it (Req 4); AC5, AC6, AC7. |
| Q4 | Session Manager, Tagging API, IAM read for ABC-1 | **Answered:** all in Req 4; AC5 checks `ssm:StartSession`, `tag:GetResources`, `iam:ListUsers`. |
| Q5 | Criterion for the engineering role's allowed actions and PassRole limit | **Mostly answered:** AC5 and AC6. KMS use and state-bucket access remain (new Q3). |
| Q6 | Billing and Identity Center denies | **Answered:** AC6 lists `sso:CreatePermissionSet`, `aws-portal:ModifyBilling`, `organizations:LeaveOrganization`, `account:CloseAccount` via the simulator. |
| Q7 | Which resources carry the cost tags, and a criterion | **Answered:** AC14 (state bucket and every other taggable resource this story creates). |
| Q8 | Personal data in Terraform state | **Answered:** Constraints "Personal data"; Req 10 (never public, TLS only, encrypted, admin role and root only); AC13. |
