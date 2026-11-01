# Story review: FND-5 Cost and audit guardrails for the organization

Round 2 · 2026-11-01

## Gate

The orchestrator reads this block. Keep it valid JSON and keep the keys exactly.

```json
{
  "key": "FND-5",
  "round": 2,
  "score": 87,
  "threshold": 80,
  "verdict": "READY",
  "blocking": [],
  "criteria": {"C1": 10, "C2": 12, "C3": 20, "C4": 15, "C5": 10, "C6": 10, "C7": 5, "C8": 5},
  "questions": 3
}
```

## Scores

| # | Criterion | Score | Max | Evidence (quoted from the story) | Gaps |
|---|-----------|-------|-----|----------------------------------|------|
| C1 | Intent and context | 10 | 10 | "As the engineer paying for this build, I want to be warned before spending passes my monthly limit, and to know who did what in every account, so that a forgotten resource can't run up a bill unnoticed, and every action can be traced." Context quotes `docs/00-roadmap.md` §1, §4, §6 (checked against `workspace-docs/00-roadmap.md`: "alerts at 50%, 80%, and 100% of the monthly posture limit, plus Cost Anomaly Detection", "Lean by default (~$50–100/month)", "a test budget alert fires" all match) and names FND-3 and ABC-1 as consumers. | None. (A wrong AC number in the ABC-1 reference is under Nice to know.) |
| C2 | Requirements | 12 | 20 | R1 "one monthly cost budget for the whole organization (unblended cost), with email alerts when *actual* spend reaches 50%, 80% and 100%"; R2 "$100 (Lean) by default and $300 (Working)"; R3 "daily email summary when an anomaly's cost impact is $10 or more"; R5 "in all regions, with log file validation on ... kept for 90 days, then deleted"; R6 "Earlier versions of log objects are kept, so overwriting or deleting a log leaves the original recoverable"; R7 "Remove an existing trail that only duplicates management events (a second copy is billed). Keep anything else". | (a) R5 and R6 together leave retention of earlier versions open: with versions kept, a 90-day deletion of current objects leaves noncurrent versions (and delete markers) in the bucket. Are earlier versions also deleted after a set time, or kept indefinitely? This changes the lifecycle design, what AC9 checks, and the long-run cost against "under $2 per month" (-4). (b) R7 "only duplicates management events" is not defined for mixed cases: a trail that records management events plus data events or Insights, or one that delivers to CloudWatch Logs / SNS or has something reading its bucket. Whether such a trail is removed, changed to drop management events, or kept (and its billed second copy of management events accepted) changes what is done in a member account and the cost (-4). |
| C3 | Acceptance criteria | 20 | 25 | AC1–AC14 cover R1–R8: budget (AC1–AC3), anomaly detection (AC4), tags (AC5, AC12), trail (AC6–AC8), bucket protection (AC9, AC10), Offers Platform clean-up (AC11), cost (AC13), Terraform checks (AC14). AC3 handles the $0.00 case and is marked MANUAL as `AGENTS.md` allows. AC10 "For the ABC Bank administrator role, `aws iam simulate-principal-policy` shows `cloudtrail:StopLogging`, `cloudtrail:DeleteTrail` and `budgets:ModifyBudget` denied on the organization trail and budget, and `aws cloudtrail describe-trails` from the ABC Bank account shows the organization trail as read-only there." | (a) AC10 is not a reliable pass/fail as written. The ABC Bank administrator role is an administrator in its own account, and its protection from the management account's trail and budget comes from the account boundary, not from a deny in its policies. A simulation of that role's policies is therefore likely to report these actions as allowed unless something adds an explicit deny (a service control policy or a permissions boundary), which the story's Access row says it does not do ("no Identity Center, permission-set or organization-policy changes"). Also, `describe-trails` output has no "read-only" field, so the tester must guess what shows it (for example `IsOrganizationTrail: true` with the management account in the trail ARN) (-5). |
| C4 | Constraints | 15 | 15 | Constraints table rows for every `AGENTS.md` item: Access and lock-out "Not applicable: no Identity Center, permission-set or organization-policy changes"; Least privilege "Only the management account's administrator role can change the budget, the anomaly monitor, the trail or its bucket. Member-account roles cannot reach them."; "No IAM users ... None created."; Cost "under $2 per month in total" with the reason for S3-managed keys; Tagging; Audit; Effect on member accounts; Personal data ".tfvars". | None. (If the answer to Q1 is an explicit deny through a service control policy or permission sets, the Access row stops being "not applicable" and B5 applies; see Q1.) |
| C5 | Scope boundaries | 10 | 10 | "Out of scope: A tag policy that blocks untagged resources (a later `aws-foundations` story); Budgets per account; budget actions that stop resources automatically; Data events in CloudTrail; delivery to CloudWatch Logs or CloudTrail Lake; AWS Config; Security Hub; Encrypting trail logs with a customer-managed KMS key". | None. The tag policy is now consistent with FND-1 ("A tag policy (a later `aws-foundations` story ...)"). |
| C6 | Dependencies and inputs | 10 | 10 | "FND-1: the organization (all features), the management account, CloudTrail trusted access, and `aws-foundations` Terraform state." R4 names FND-1's state bucket as the first tagged billed resource; R8 makes enabling Cost Explorer a manual README step; the alert email is a `.tfvars` input. | None. FND-1 confirmed as a draft story (`workspace-stories/FND-1.md`: R1 "all features ... required by ... FND-5's organization trail", R7 / AC9 CloudTrail trusted access, R9 state bucket). `gh issue list -R Lakshmi100/aws-foundations --state all` returns no issues, as expected for drafts. |
| C7 | Free of design | 5 | 5 | "when one Terraform variable is switched" (reason: switching posture); "Logs are encrypted with S3-managed keys (no KMS key cost)" (reason given); "`guardrails/` root" (matches `AGENTS.md` layout); "S3 bucket in the management account" (matches `AGENTS.md`: everything runs in or is managed from the management account). | No deduction; see Design detail to confirm. |
| C8 | Open questions resolved | 5 | 5 | "Open questions: None." Proposed defaults are stated choices for the approver ("trail in all regions; logs kept 90 days, then deleted; S3-managed encryption for logs; anomaly alerts daily at $10 impact; unblended cost for the budget"). | No TBDs. The retention interplay of R5/R6 is an ambiguity, scored under C2, not a contradiction. |
| | **Total** | **87** | **100** | | |

## Blocking issues
| # | Issue | Where in the story |
|---|-------|--------------------|
| | None. B1: no open questions or contradictions. B2: every criterion can be run (AC10's expected result is questioned under C3). B3: the only dependency, FND-1, is another story. B4: nothing forbidden; removing a duplicate trail in the Offers Platform account is named by the story. B5: as written the story does not change Identity Center, permission sets or organization policies (it would apply if Q1 is answered with a service control policy or permission-set change). B6: recurring cost stated, "under $2 per month". | |

## Questions for the story owner
Ordered by points recovered, largest first.

| # | Resolves | Question | Why it matters |
|---|----------|----------|----------------|
| Q1 | C3 | For AC10, is the protection meant to be the account boundary alone (member-account roles cannot address the management account's trail and budget at all), or an explicit deny (for example a service control policy) so the ABC Bank administrator role's simulation shows "denied"? And what in `describe-trails` from ABC Bank counts as "read-only" (for example `IsOrganizationTrail: true` and the trail ARN in the management account)? | The administrator role's own policies allow everything, so a simulation will likely show "allowed" unless an explicit deny is added. An SCP or permission-set change would contradict the Access row and bring in B5 (how access is checked afterwards and how to recover). Without an answer the tester cannot write a reliable PASS/FAIL line and the architect may add an SCP the story did not ask for. |
| Q2 | C2 | Once a log is overwritten, deleted, or expired by the 90-day rule, how long are its earlier versions kept: deleted after a set number of days (how many), or kept indefinitely? | Decides the lifecycle rule for noncurrent versions and delete markers, what AC9 checks, and whether storage keeps growing against the "$2 per month" limit. |
| Q3 | C2 | In the Offers Platform account, what should happen to a trail that records management events plus something else (data events, Insights), or that delivers to CloudWatch Logs / SNS or has something reading its bucket: remove it, change it to stop recording management events, or keep it as is? | "Only duplicates management events" does not cover these cases. The answer decides what is changed in a member account (and whether anything relying on that trail could break) and whether a billed second copy of management events stays within the $2 limit. |

## Nice to know
- Context says "ABC-1's cost criterion (AC9)"; in `workspace-stories/ABC-1.md` the cost criterion is AC10 (AC9 is the no-IAM-users / no NAT check). Fix the reference.
- R3 does not say who receives the anomaly email; it is presumably the same `.tfvars` address as the budget alerts. AC4 does not check the subscriber.
- R8's README entry for enabling Cost Explorer by hand has no acceptance criterion; it is checked by reading the PR.
- AC8: CloudTrail delivers digest files hourly, so `validate-logs` for "the last hour" right after the trail is created may find nothing to validate. Running it once the trail has been logging for a couple of hours avoids a false FAIL.
- AC7: FND-1's ABC Bank engineering role cannot create S3 buckets, so the test needs the ABC Bank administrator role. Naming the role in AC7 saves the tester a guess.
- AC6 does not check that the trail records both read and write management events (the default). Optional to add.
- `aws ce` API calls in `tests/FND-5.sh` are billed per request (about $0.01 each); negligible but not zero.
- The story is still a draft (`needs-approval`, no GitHub issue yet). It needs approval and an issue before `/story` runs, and its real key comes from the issue number.

## Design detail to confirm
- **AC9 "versioning on"**: one mechanism for R6 "the original recoverable" (S3 Object Lock is another). Keep it as a constraint with a reason, or let the architect choose and check the outcome instead.
- **AC10 "denied" in `simulate-principal-policy`**: implies an explicit deny mechanism; see Q1.
- **AC3 "temporarily set (through Terraform) to $0.01"**: a test method; the reason (no drift afterwards) is given. Fine as is.
- **R1 "unblended cost"**, **R5 "S3-managed keys"**, **R2 "one Terraform variable"**, **R8 "`guardrails/` root"**: requirements or constraints with reasons (approver's stated defaults, no KMS cost, posture switch, `AGENTS.md` layout). Keep.

## Earlier questions
Round 1 (`story-review.round1.md`, score 54, NEEDS_INFO):

| # | Round 1 question (short) | Answered? |
|---|--------------------------|-----------|
| Q1 | CloudTrail trusted access: FND-1 or FND-5? | Yes. FND-1 enables it (FND-1 R7, AC9); FND-5 lists it under Depends on and in the Access row. |
| Q2 | Who enables Cost Explorer; which tagged resources must exist first? | Yes. R8 (manual README step) and R4 (FND-1's state bucket is the first tagged billed resource). |
| Q3 | Criterion for the tagging constraint? | Yes. AC12. |
| Q4 | Who must be unable to delete/overwrite logs; "not public" check; is AC7 the right test? | Mostly. R6, AC9 (versioning, public access block) and AC10 answer it, but AC10's expected result raises a new question (round 2 Q1). |
| Q5 | Encryption at rest criterion; S3-managed or KMS? | Yes. S3-managed keys (Cost row, Proposed defaults), checked in AC9; customer-managed KMS out of scope. |
| Q6 | AC3 when spend is $0.00; how it is reported? | Yes. AC3: limit $0.01, wait until spend is above $0.00, MANUAL inbox check. |
| Q7 | Anomaly threshold, frequency, address? | Yes for threshold ($10 impact) and frequency (daily). Recipient implied only (Nice to know). |
| Q8 | All Regions or `us-east-1`? | Yes. R5 "in all regions"; AC6 multi-region. |
| Q9 | How long are logs kept? | Yes (90 days, then deleted; AC9). Versioning added in R6 raises a follow-up on earlier versions (round 2 Q2). |
| Q10 | Least privilege for budget, monitor, trail; member-account Cost Explorer read? | Yes. Least privilege row, AC10; member accounts see their own costs (FND-1 gives the engineering role Cost Explorer read). |
| Q11 | Existing trails, budgets, monitors in Offers Platform? | Yes. R7 and AC11; the definition of "only duplicates" raises a follow-up (round 2 Q3). |
| Q12 | Per-account budgets, CloudWatch Logs / Lake; tag policy owner? | Yes. All out of scope; tag policy is "a later `aws-foundations` story", now matching FND-1. |

Round 1 nice-to-know items also addressed: default posture ($100) stated in R2; Access and No-IAM-users rows added; AC2 switches back to Lean; AC3 sets the limit back through Terraform; log file validation added (R5, AC8); unblended cost stated.
