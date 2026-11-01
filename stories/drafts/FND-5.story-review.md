# Story review: FND-5 Cost and audit guardrails for the organization

Round 1 · 2026-11-01

## Gate

The orchestrator reads this block. Keep it valid JSON and keep the keys exactly.

```json
{
  "key": "FND-5",
  "round": 1,
  "score": 54,
  "threshold": 80,
  "verdict": "NEEDS_INFO",
  "blocking": [],
  "criteria": {"C1": 10, "C2": 8, "C3": 9, "C4": 9, "C5": 8, "C6": 0, "C7": 5, "C8": 5},
  "questions": 12
}
```

## Scores

| # | Criterion | Score | Max | Evidence (quoted from the story) | Gaps |
|---|-----------|-------|-----|----------------------------------|------|
| C1 | Intent and context | 10 | 10 | "As the engineer paying for this build, I want to be warned before spending passes my monthly limit, and to know who did what in every account, so that a forgotten resource can't run up a bill unnoticed, and every action can be traced." Context cites `docs/00-roadmap.md` §1, §4 Phase 1, §6 (quotes checked against `workspace-docs/00-roadmap.md`: they match) and ABC-1 AC9. | None. |
| C2 | Requirements | 8 | 20 | R1 "alerts at 50%, 80% and 100% of the limit, sent to the engineer's email address"; R2 "Lean posture ($100) and the Working posture ($300)"; R3 "Cost Anomaly Detection watches the organization's spend by service and sends an email alert"; R5 "An organization CloudTrail trail records management events in all three accounts and stores them in S3 in the management account". | (a) R3: no anomaly threshold (absolute $ or %), alert frequency, or recipient (-4). (b) R5: which Regions the trail covers (all Regions or `us-east-1` only, global service events) is not stated (-4). (c) R5: how long trail logs are kept in S3 (forever, or expire / transition after N days) is not stated (-4). |
| C3 | Acceptance criteria | 9 | 25 | AC1–AC9; AC3 "temporarily setting the limit below current month-to-date spend triggers the 50% notification email within 24 hours"; AC7 "With the ABC Bank administrator role, deleting an object in the trail bucket is denied." | (a) Tagging constraint "Every taggable resource carries the four cost tags" has no criterion, although Out of scope says "tags are checked by each story's acceptance criteria" (-4). (b) "The CloudTrail bucket is not public, and member accounts cannot delete or change its logs" has no criterion for "not public" or "change" (overwrite); AC7 only covers delete, and the ABC Bank admin role has no access to a management-account bucket in any case, so AC7 would pass without any bucket protection (-4). (c) "Trail logs are encrypted at rest" has no criterion (-4). (d) AC3 boundary case missing: in a new organization early in the month, month-to-date spend can be $0.00, so no limit is "below" it and no alert fires; also not stated how AC3 (an inbox check) produces a PASS/FAIL line in `tests/FND-5.sh` (-4). |
| C4 | Constraints | 9 | 15 | Constraints table: personal data, PCI (n/a), network and access, encryption, cost "total under $2 per month", tagging, downstream compatibility "Not applicable". | AGENTS.md checklist: (a) **Least privilege** not addressed: which roles may view or change the budget, anomaly monitor and trail, and that the ABC Bank day-to-day engineering role cannot stop the trail or change the budget (-3). (b) **Effect on member accounts** not addressed: the organization trail reaches all member accounts, and the Offers Platform account already exists and may have its own trail(s), budgets or anomaly monitors (a second copy of management events is billed, which also affects the "$2" limit) (-3). Access/lock-out and "no IAM users or long-lived keys" look not applicable but are not stated (see Nice to know). |
| C5 | Scope boundaries | 8 | 10 | "Out of scope: A tag policy that blocks untagged resources ...; Budget actions that stop resources automatically; Data events in CloudTrail; AWS Config; Security Hub". | Explicit list, but obvious neighbours are not placed: per-account budgets (ABC Bank, Offers Platform), CloudTrail delivery to CloudWatch Logs / CloudTrail Lake. Tag policy: FND-1 says "CloudTrail organization trail, budgets, anomaly detection, tag policy (FND-5)" is out of its scope, while FND-5 puts the tag policy out of scope, so no story owns it (-2). |
| C6 | Dependencies and inputs | 0 | 10 | "Depends on: FND-1: the organization, the management account, and `aws-foundations` Terraform state." FND-1 confirmed as a draft story (`workspace-stories/FND-1.md`); no GitHub issues exist yet in `Lakshmi100/aws-foundations`. | Implied, not listed: (a) An organization trail requires CloudTrail trusted access on the organization (`cloudtrail.amazonaws.com` in the organization's service-access principals). That setting lives on the organization resource FND-1 creates in `organization/`; changing it from `guardrails/` would make the two roots fight and break FND-1's "`terraform plan` shows no changes" (-5). (b) Billing-side prerequisites: Cost Explorer must be enabled in the management account before Cost Anomaly Detection and cost-allocation tag APIs work, and the four tag keys can only be activated once tagged resources have appeared in billing data (up to 24 hours). The story does not say who enables Cost Explorer or which tagged resources must exist first (-5). |
| C7 | Free of design | 5 | 5 | "by changing one Terraform variable" (reason given: switch posture); "stores them in S3 in the management account" (matches AGENTS.md: everything runs in the management account); AC1 "percent of actual spend". | No deduction; see Design detail to confirm. |
| C8 | Open questions resolved | 5 | 5 | "Open questions: None." | No TBDs or contradictions inside the story. (The tag-policy ownership mismatch with FND-1 is scored under C5.) |
| | **Total** | **54** | **100** | | |

## Blocking issues
| # | Issue | Where in the story |
|---|-------|--------------------|
| | None. B5 does not apply (the story does not change Identity Center, permission sets or organization policies as written); B6 does not apply (recurring cost stated as "under $2 per month"). | |

## Questions for the story owner
Ordered by points recovered, largest first.

| # | Resolves | Question | Why it matters |
|---|----------|----------|----------------|
| Q1 | C6 | The organization trail needs CloudTrail trusted access on the organization, which FND-1's `organization/` root owns. Should FND-5 change FND-1's organization code to add it, or should FND-1 enable it (and FND-5 list that as a dependency)? | Otherwise the architect picks a root and risks two roots managing the same attribute, which breaks FND-1's no-drift check. |
| Q2 | C6 | Who enables Cost Explorer in the management account (a manual README step for the owner, or code), and which already-tagged resources (e.g. FND-1's state bucket) must exist in billing data before the four tags can be activated for AC5? | Without this, AC4/AC5 can fail on a fresh organization for reasons outside the code, and the tester cannot tell setup failure from a defect. |
| Q3 | C3 | What acceptance criterion checks the tagging constraint (e.g. every resource this story creates has the four tags with non-empty values)? | The story's own Out of scope says tags are checked by each story's criteria, but none here does. |
| Q4 | C3 | Which principals must be shown unable to delete or overwrite trail logs, and should "not public" be checked (e.g. public access block)? Is AC7 with the ABC Bank admin role (which has no cross-account access to the bucket anyway) the intended test, or should it also cover the management account's day-to-day roles? | AC7 as written passes even with no bucket protection, so it does not prove the constraint. |
| Q5 | C3 | What criterion checks "trail logs are encrypted at rest", and is S3-managed encryption acceptable or must it be a customer-managed KMS key (about $1/month, which counts against the $2 limit)? | The tester has nothing to check, and the answer changes design and cost. |
| Q6 | C3 | What should AC3 do if month-to-date spend is $0.00 (likely in a new organization in early November), and how should `tests/FND-5.sh` report AC3: a manual inbox confirmation, or the budget notification state read through the API? | As written, AC3 may be impossible to run, and an inbox check does not produce a scripted PASS/FAIL line. |
| Q7 | C2 | For Cost Anomaly Detection: what threshold triggers an alert (a dollar amount, a percentage, or both), how often (individual alerts, daily or weekly summary), and to which address? | The subscription cannot be created without a threshold and frequency, and AC4 cannot check them. |
| Q8 | C2 | Should the trail record management events in all Regions (a multi-Region trail, including global service events) or only `us-east-1`? | A resource left running in another Region would go untraced, which is the problem the story describes; this changes the design and AC6. |
| Q9 | C2 | How long must trail logs be kept in S3: indefinitely, or expire or move to cheaper storage after a set number of days? | It decides whether a lifecycle rule exists and what the tester checks, and it affects the long-run cost. |
| Q10 | C4 | Least privilege: which roles may view and which may change the budget, anomaly monitor, cost-allocation tags and trail? Confirm that the ABC Bank engineering role cannot stop or delete the trail or change the budget, and say whether any member-account role needs Cost Explorer read access (ABC-1 AC9 reads cost by tag). | AGENTS.md requires it; without it the architect guesses the permission boundaries and the tester has no denial checks. |
| Q11 | C4 | Effect on member accounts: does the existing Offers Platform account already have CloudTrail trails, budgets or anomaly monitors, and should they be kept, removed or left alone? | An existing trail makes the organization trail a billed second copy (affecting the $2 limit), and removing anything in a member account needs to be named by the story. |
| Q12 | C5 | Are per-account budgets (ABC Bank, Offers Platform) and trail delivery to CloudWatch Logs / CloudTrail Lake out of scope? FND-1 says the tag policy belongs to FND-5, while FND-5 rules it out: which story owns it, or is it dropped? | A reader could reasonably assume either is included, and the tag policy currently belongs to no story. |

## Nice to know
- Default posture is not stated in R2. AC2 ("from Lean to Working") and the roadmap ("Lean by default") imply Lean ($100). Saying so in R2 removes any doubt for AC1.
- The constraints table has no rows for the AGENTS.md items "Access and lock-out" and "No IAM users or long-lived keys". Both look not applicable (nothing here changes sign-in or creates users or keys), but AGENTS.md asks for them to be stated.
- AC2 leaves the budget at Working ($300). Saying that the test sets it back to Lean keeps the real budget at the default.
- AC3 sets the limit below spend, so the 80% and 100% notifications also fire, not just 50%. Not a problem, but the owner will get three emails.
- AC3 temporarily changes a Terraform-managed value. If it is changed outside Terraform, a later `terraform plan` shows drift until it is reset through Terraform.
- If the design protects the logs with a service control policy, the story would then change an organization policy and B5 would apply (verifying access afterwards and how to recover).
- Budget cost type (unblended, net of credits, including tax or not) is not stated. AWS defaults are fine at this scale.
- CloudTrail log file integrity validation is not mentioned. It costs nothing and helps "every action can be traced", but it is not required.
- AGENTS.md coding standards already keep the alert email in an untracked `.tfvars`. An acceptance criterion for this is optional.
- The story is still a draft (`needs-approval`, no GitHub issue yet). It needs approval and an issue before `/story` runs, and its real key comes from the issue number.

## Design detail to confirm
- **"notifications at 50, 80 and 100 percent of actual spend"** (AC1): actual spend instead of forecast. The roadmap only says "alerts at 50%, 80%, and 100%". Keep it as a constraint (with a reason, e.g. avoiding forecast noise), or leave actual vs forecast to the architect.
- **"stores them in S3 in the management account"** (R5): this matches the three-account compromise and AGENTS.md ("Everything here runs in, or is managed from, the management account"). Keep it as a constraint and add that reason.
- **"by changing one Terraform variable"** (R2): the reason is given (switching posture). Keep it.
- **AC6 "creating and deleting a test S3 bucket"**: an example of a test event, allowed by AGENTS.md's testing rules. Fine as is.

## Earlier questions
Not applicable (round 1).
