# FND-5: Cost and audit guardrails for the organization

**Repo:** `aws-foundations` · **Milestone:** Phase 1: Foundations · **Estimate:** 5 pts
**Labels:** `story`, `needs-approval`, `infra`, `finops`, `foundations`, `dea-domain-3`
**Approver:** Lakshmi100 · **Status:** draft round 3, not yet an issue (draft ID; the real key comes from the issue number)

## User story

**As** the engineer paying for this build,
**I want** to be warned before spending passes my monthly limit, and to know who did what in every account,
**so that** a forgotten resource can't run up a bill unnoticed, and every action can be traced.

## Context

Roadmap FinOps guardrails: "AWS Budgets alerts at 50%, 80%, and 100% of the monthly posture limit, plus Cost Anomaly Detection", posture "Lean by default (~$50–100/month); Working (~$150–300/month)", mandatory cost-allocation tags, and a CloudTrail organization trail (`docs/00-roadmap.md` §1, §4 Phase 1, §6). Phase 1 exit criterion: "a test budget alert fires". ABC-1's cost criterion (AC10) needs the cost-allocation tags active. FND-3's "show an auditor who used the key" comes from this trail.

## Requirements

1. **Budget:** one monthly cost budget for the whole organization (unblended cost), with email alerts when *actual* spend reaches 50%, 80% and 100% of the limit.
2. **Posture:** the limit is $100 (Lean) by default and $300 (Working) when one Terraform variable is switched. Switching back returns it to $100.
3. **Anomaly detection:** Cost Anomaly Detection watches spend by AWS service across the organization and sends a daily email summary, to the same engineer's email address as the budget, when an anomaly's cost impact is $10 or more.
4. **Cost-allocation tags:** `data-product`, `environment`, `owner` and `cost-center` are active cost-allocation tags (Cost Explorer itself is enabled by FND-1). AWS can activate a tag only after it has seen it on a billed resource; FND-1's state bucket is the first one.
5. **Audit trail:** an organization CloudTrail trail records management events (read and write) in all three accounts, **in all regions**, with log file validation on. Logs are stored in an S3 bucket in the management account, kept for **90 days**, then deleted.
6. **Log protection:** the trail and its bucket can be changed only by the management account's administrator role. The bucket is never public. Earlier versions of log objects are kept for 30 days after they are replaced or deleted, so overwriting or deleting a log leaves the original recoverable for that long; expired delete markers are cleaned up.
7. **Existing setup in the Offers Platform account:** before the organization trail is created, list any trails, budgets and anomaly monitors already in that account. Remove an existing trail only if it records nothing but management events, has no other destination (CloudWatch Logs, SNS) and nothing reads its bucket; a second copy of management events is billed. Keep any other trail, budget or monitor, and list everything found, and what was done with it, in `README.md`.
8. Everything is defined in Terraform in the `aws-foundations` `guardrails/` root.

## Constraints

| Area | Constraint |
|---|---|
| Access and lock-out | Not applicable: no Identity Center, permission-set or organization-policy changes. CloudTrail trusted access is enabled by FND-1. |
| Least privilege | Only the management account's administrator role can change the budget, the anomaly monitor, the trail or its bucket. Member-account roles cannot reach them, because they live in the management account and AWS lets only that account change an organization trail. No service control policy is added. |
| No IAM users or long-lived keys | None created. |
| Cost | Persistent. One trail's management events are free; S3 storage for 90 days of logs and the budget stay **under $2 per month** in total. Logs are encrypted with S3-managed keys (no KMS key cost). |
| Tagging | The trail, its bucket, the budget and the anomaly monitor carry the four cost tags with the values in `AGENTS.md`. |
| Audit | This story creates the audit trail. |
| Effect on member accounts | Their management events are recorded in the management account. Duplicate trails in the Offers Platform account are removed (requirement 7). Member accounts can see their own costs in Cost Explorer. |
| Personal data | The alert email address goes in the untracked `.tfvars` file. |

## Acceptance criteria

- [ ] **AC1** `aws budgets describe-budgets` shows one monthly cost budget with a $100 limit and notifications at 50, 80 and 100 percent of actual spend, each with the engineer's email as subscriber.
- [ ] **AC2** Switching the posture variable to Working and running `terraform plan` shows only the limit changing to $300. Switching back and applying returns it to $100.
- [ ] **AC3** A test alert reaches the inbox: with the limit temporarily set (through Terraform) to $0.01 and month-to-date spend above $0.00, a budget alert email arrives within 24 hours. The limit is then set back through Terraform, and `terraform plan` shows no changes. (MANUAL: check the inbox. If month-to-date spend is $0.00, wait until it isn't.)
- [ ] **AC4** `aws ce get-anomaly-monitors` shows a service-level monitor, and `aws ce get-anomaly-subscriptions` shows a daily email subscription to the engineer's address with a $10 threshold.
- [ ] **AC5** `aws ce list-cost-allocation-tags` shows all four tags as `Active`.
- [ ] **AC6** `aws cloudtrail describe-trails` shows an organization trail that is multi-region with log file validation on and records read and write management events, and `get-trail-status` shows it logging.
- [ ] **AC7** With the ABC Bank administrator role, creating and deleting a test S3 bucket produces events in the trail's bucket within 30 minutes. The test bucket is deleted.
- [ ] **AC8** At least two hours after the trail starts logging, `aws cloudtrail validate-logs` for the previous hour reports the log files as valid.
- [ ] **AC9** The trail bucket has versioning on, all public access blocked, encryption at rest, and lifecycle rules that delete current objects after 90 days and earlier versions 30 days after they are replaced.
- [ ] **AC10** From the ABC Bank administrator role, `aws cloudtrail describe-trails --include-shadow-trails` shows the organization trail with `IsOrganizationTrail: true` and a `HomeRegion`/ARN in the management account, and `aws budgets describe-budgets` in the ABC Bank account shows no organization budget: both live only in the management account.
- [ ] **AC11** `README.md` lists what was found in the Offers Platform account and what was done with each item (requirement 7). `aws cloudtrail describe-trails` in that account shows no trail of its own that records *only* management events with no other destination; any trail kept under requirement 7 is listed in `README.md`, and its monthly cost counts toward the $2 limit.
- [ ] **AC12** The trail, trail bucket, budget and anomaly monitor have the four cost tags with the values in `AGENTS.md`.
- [ ] **AC13** The PR records the expected monthly cost, under $2.
- [ ] **AC14** `terraform plan` in `guardrails/` shows no changes after apply; `terraform fmt -check` and `terraform validate` pass.

## Out of scope

- A tag policy that blocks untagged resources (a later `aws-foundations` story)
- Budgets per account; budget actions that stop resources automatically
- Data events in CloudTrail; delivery to CloudWatch Logs or CloudTrail Lake; AWS Config; Security Hub
- Encrypting trail logs with a customer-managed KMS key

## Depends on

- FND-1: the organization (all features), the management account, CloudTrail trusted access, and `aws-foundations` Terraform state.

## Decisions

- Nov 1, 2026: management-account Terraform lives in `aws-foundations`.
- **Proposed defaults, for the approver to confirm:** trail in all regions; logs kept 90 days, then deleted; S3-managed encryption for logs; anomaly alerts daily at $10 impact; unblended cost for the budget.

## Open questions

None.
