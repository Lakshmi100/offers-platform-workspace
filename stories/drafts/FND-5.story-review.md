# Story review: FND-5 Cost and audit guardrails for the organization

Round 3 · 2026-11-01

## Gate

The orchestrator reads this block. Keep it valid JSON and keep the keys exactly.

```json
{
  "key": "FND-5",
  "round": 3,
  "score": 95,
  "threshold": 80,
  "verdict": "READY",
  "blocking": [],
  "criteria": {"C1": 10, "C2": 20, "C3": 20, "C4": 15, "C5": 10, "C6": 10, "C7": 5, "C8": 5},
  "questions": 1
}
```

## Scores

| # | Criterion | Score | Max | Evidence (quoted from the story) | Gaps |
|---|-----------|-------|-----|----------------------------------|------|
| C1 | Intent and context | 10 | 10 | "As the engineer paying for this build, I want to be warned before spending passes my monthly limit, and to know who did what in every account, so that a forgotten resource can't run up a bill unnoticed, and every action can be traced." Context quotes `docs/00-roadmap.md` §1, §4, §6 (matches `workspace-docs/00-roadmap.md` lines 32, 111, 184) and now says "ABC-1's cost criterion (AC10)", which matches `workspace-stories/ABC-1.md` AC10. FND-3's auditor need matches `workspace-stories/FND-3.md` line 11. | None. |
| C2 | Requirements | 20 | 20 | R1 "one monthly cost budget for the whole organization (unblended cost) ... 50%, 80% and 100%"; R2 "$100 (Lean) by default and $300 (Working) ... Switching back returns it to $100"; R3 "daily email summary, to the same engineer's email address as the budget, when an anomaly's cost impact is $10 or more"; R5 "in all regions, with log file validation on ... kept for 90 days, then deleted"; R6 "Earlier versions of log objects are kept for 30 days after they are replaced or deleted ... expired delete markers are cleaned up"; R7 "Remove an existing trail only if it records nothing but management events, has no other destination (CloudWatch Logs, SNS) and nothing reads its bucket ... Keep any other trail, budget or monitor". | None. Round 2's two gaps (noncurrent-version retention; definition of a removable trail) are now stated with concrete values. |
| C3 | Acceptance criteria | 20 | 25 | AC1–AC14 cover R1–R8. AC4 now checks the subscriber; AC6 checks read and write events; AC7 names "the ABC Bank administrator role"; AC8 waits "at least two hours"; AC9 checks "earlier versions 30 days after they are replaced"; AC10 now checks "`IsOrganizationTrail: true` and a `HomeRegion`/ARN in the management account" and "no organization budget" in ABC Bank. AC11: "`aws cloudtrail describe-trails` in that account shows no trail of its own that duplicates management events." | (a) AC11 does not match R7 in one case. R7 keeps a trail that records management events *plus* something else (data events, Insights, another destination, or a reader of its bucket). Such a kept trail still records a second copy of management events, so a literal reading of AC11 ("no trail of its own that duplicates management events") makes it FAIL even though R7 was followed. The tester must guess whether AC11 means "no trail of the removable kind in R7" or "no trail recording management events at all" (-5). |
| C4 | Constraints | 15 | 15 | Constraints table: Access and lock-out "Not applicable: no Identity Center, permission-set or organization-policy changes"; Least privilege "Only the management account's administrator role can change ... Member-account roles cannot reach them, because they live in the management account ... No service control policy is added."; No IAM users "None created."; Cost "under $2 per month in total" with the reason for S3-managed keys; Tagging; Audit; Effect on member accounts; Personal data ".tfvars". | None. (The cost of a trail kept under R7 is raised with the AC11 question, not deducted twice.) |
| C5 | Scope boundaries | 10 | 10 | Out of scope: tag policy ("a later `aws-foundations` story"), per-account budgets, budget actions, data events, CloudWatch Logs / CloudTrail Lake, AWS Config, Security Hub, customer-managed KMS key. | None. |
| C6 | Dependencies and inputs | 10 | 10 | "FND-1: the organization (all features), the management account, CloudTrail trusted access, and `aws-foundations` Terraform state." R4 "Cost Explorer itself is enabled by FND-1"; "FND-1's state bucket is the first" tagged billed resource. Alert email in `.tfvars`. | None. Confirmed in `workspace-stories/FND-1.md`: R1 all features "required by ... FND-5's organization trail"; R8 / AC12 CloudTrail trusted access and Cost Explorer enabled; R10 state bucket; R4 Administrator role in each account (used by AC7, AC10). FND-1 is another story (draft), so B3 does not apply. `gh issue list -R Lakshmi100/aws-foundations --state all` returns no issues, as expected for drafts. |
| C7 | Free of design | 5 | 5 | "one Terraform variable" (posture switch); "S3-managed keys (no KMS key cost)"; "`guardrails/` root" (`AGENTS.md` layout); AC3 "temporarily set (through Terraform) to $0.01" (no drift afterwards); AC9 "versioning on" (serves R6's recoverability). | No deduction; see Design detail to confirm. |
| C8 | Open questions resolved | 5 | 5 | "Open questions: None." Proposed defaults are the owner's stated choices ("trail in all regions; logs kept 90 days, then deleted; S3-managed encryption for logs; anomaly alerts daily at $10 impact; unblended cost for the budget"). | None. The AC11 / R7 mismatch is a wording ambiguity (the Effect row uses "Duplicate trails ... (requirement 7)" for the R7 set, so a consistent reading exists); scored under C3, not as a contradiction. |
| | **Total** | **95** | **100** | | |

## Blocking issues
| # | Issue | Where in the story |
|---|-------|--------------------|
| | None. B1: no open questions; AC11 vs R7 is ambiguous wording with a consistent reading, not a contradiction. B2: every criterion can be run. B3: FND-1 is another story. B4: nothing forbidden; changes in the Offers Platform account are named by R7. B5: no Identity Center, permission-set or organization-policy change (AC10 no longer implies a deny; "No service control policy is added"). B6: recurring cost stated, "under $2 per month". | |

## Questions for the story owner
Ordered by points recovered, largest first.

| # | Resolves | Question | Why it matters |
|---|----------|----------|----------------|
| Q1 | C3 | If the Offers Platform account has a trail that R7 keeps (it records management events plus data events or Insights, has another destination, or something reads its bucket), what should AC11 expect: PASS because only R7's removable kind of trail must be gone, or FAIL because no trail there may record management events? And is that kept trail's billed second copy of management events counted in the "under $2 per month"? | As written, AC11 FAILs whenever R7 correctly keeps such a trail, so the tester cannot write a reliable PASS/FAIL line. The cost answer decides what AC13 and the PR's cost figure include. |

## Nice to know
- AC9 does not check R6's "expired delete markers are cleaned up"; the tester can add it from R6.
- AC10 "`HomeRegion`/ARN in the management account": `HomeRegion` is a region, not an account; the management account ID is in `TrailARN`. Since the ABC Bank account is new, "no organization budget" in practice means `describe-budgets` there returns none (or none with the organization budget's name).
- AC5: a tag shows up for activation only after AWS has seen it on a billed resource (up to about 24 hours), and activation can take up to 24 hours to show `Active`. Apply order and test timing should allow for that.
- R7 "nothing reads its bucket": the story does not say what evidence counts (for example, bucket policy and access logs, or the owner's word); the README entry is where it gets recorded.
- AC12 names no command; the Resource Groups Tagging API (as in ABC-1 AC7) or each service's tag call both work.
- AC3 with a $0.01 limit will send three emails (50, 80 and 100 percent); any one arriving passes.
- `aws ce` API calls in `tests/FND-5.sh` are billed per request (about $0.01 each); negligible.
- The story is still a draft (`needs-approval`, no GitHub issue). It needs approval and an issue before `/story` runs, and its real key comes from the issue number.

## Design detail to confirm
- **AC9 "versioning on"**: the mechanism for R6's "recoverable for that long" (S3 Object Lock would be another). Now consistent with R6's 30-day earlier-version rule; keep as a constraint or let the architect choose.
- **AC3 "temporarily set (through Terraform) to $0.01"**: test method with its reason (no drift afterwards). Fine.
- **R1 "unblended cost"**, **"S3-managed keys"**, **R2 "one Terraform variable"**, **R8 "`guardrails/` root"**: stated choices with reasons. Keep.

## Earlier questions
Round 2 (`story-review.round2.md`, score 87, READY):

| # | Round 2 question (short) | Answered? |
|---|--------------------------|-----------|
| Q1 | AC10: account boundary or explicit deny; what counts as "read-only" in `describe-trails`? | Yes. Account boundary only ("No service control policy is added"); AC10 now checks `IsOrganizationTrail: true` with the management account in the ARN, and no organization budget in ABC Bank. No simulator check remains. |
| Q2 | How long are earlier versions of logs kept? | Yes. R6: 30 days after replaced or deleted; expired delete markers cleaned up; AC9 checks the 30-day rule. |
| Q3 | What happens to a mixed-use trail in Offers Platform? | Yes for the requirement: R7 removes only a trail that records nothing but management events, has no other destination and no reader; all others are kept. Follow-up on how AC11 treats a kept trail (round 3 Q1). |

Round 2 nice-to-know items addressed: ABC-1 reference corrected to AC10; anomaly email recipient stated (R3) and checked (AC4); Cost Explorer enabling moved to FND-1 (R4, confirmed in FND-1 R8 / AC12); AC8 waits two hours; AC7 names the ABC Bank administrator role; AC6 checks read and write events. Still open: draft status; `aws ce` request cost.
