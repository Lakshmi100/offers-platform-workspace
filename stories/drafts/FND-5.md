# FND-5: Cost and audit guardrails for the organization

**Repo:** `aws-foundations` (new) · **Milestone:** Phase 1: Foundations · **Estimate:** 3 pts
**Labels:** `story`, `needs-approval`, `infra`, `finops`, `foundations`, `dea-domain-3`
**Approver:** Lakshmi100 · **Status:** draft, not yet an issue (draft ID; the real key comes from the issue number)

## User story

**As** the engineer paying for this build,
**I want** to be warned before spending passes my monthly limit, and to know who did what in every account,
**so that** a forgotten resource can't run up a bill unnoticed, and every action can be traced.

## Context

Roadmap FinOps guardrails: "AWS Budgets alerts at 50%, 80%, and 100% of the monthly posture limit, plus Cost Anomaly Detection", posture "Lean by default (~$50–100/month); Working (~$150–300/month)", mandatory cost-allocation tags, and a CloudTrail organization trail (`docs/00-roadmap.md` §1, §4 Phase 1, §6). Phase 1 exit criterion: "a test budget alert fires". ABC-1's cost criterion (AC9) needs the cost-allocation tags activated.

## Requirements

1. A monthly cost budget covers the whole organization, with email alerts at 50%, 80% and 100% of the limit, sent to the engineer's email address.
2. The limit can be switched between the Lean posture ($100) and the Working posture ($300) by changing one Terraform variable.
3. Cost Anomaly Detection watches the organization's spend by service and sends an email alert.
4. `data-product`, `environment`, `owner` and `cost-center` are activated as cost-allocation tags, so Cost Explorer can show cost by tag.
5. An organization CloudTrail trail records management events in all three accounts and stores them in S3 in the management account.
6. Everything is defined in Terraform in the `aws-foundations` repo.

## Constraints

| Area | Constraint |
|---|---|
| Personal data | The alert email address is stored in Terraform variables, not committed in code. |
| Card data (PCI) | Not applicable. |
| Network and access | The CloudTrail bucket is not public, and member accounts cannot delete or change its logs. |
| Encryption | Trail logs are encrypted at rest. |
| Cost | Persistent. Stays within free tiers where possible (one trail's management events are free); total under $2 per month. |
| Tagging | Every taggable resource carries the four cost tags. |
| Downstream compatibility | Not applicable. |

## Acceptance criteria

- [ ] **AC1** `aws budgets describe-budgets` in the management account shows one monthly cost budget with notifications at 50, 80 and 100 percent of actual spend.
- [ ] **AC2** Changing the posture variable from Lean to Working and applying changes the budget limit from $100 to $300, with no other changes in the plan.
- [ ] **AC3** A test alert reaches the engineer's inbox: temporarily setting the limit below current month-to-date spend triggers the 50% notification email within 24 hours. The limit is then reset.
- [ ] **AC4** `aws ce get-anomaly-monitors` and `aws ce get-anomaly-subscriptions` show a service-level monitor with an email subscription.
- [ ] **AC5** `aws ce list-cost-allocation-tags` shows the four tags with status `Active`.
- [ ] **AC6** `aws cloudtrail describe-trails` shows an organization trail that is logging, and a management event done in the ABC Bank account (for example, creating and deleting a test S3 bucket) appears in the trail's S3 bucket within 30 minutes.
- [ ] **AC7** With the ABC Bank administrator role, deleting an object in the trail bucket is denied.
- [ ] **AC8** The PR records the expected monthly cost of this story's resources, under $2.
- [ ] **AC9** `terraform fmt -check` and `terraform validate` pass.

## Out of scope

- A tag policy that blocks untagged resources (tags are checked by each story's acceptance criteria for now)
- Budget actions that stop resources automatically
- Data events in CloudTrail; AWS Config; Security Hub

## Depends on

- FND-1: the organization, the management account, and `aws-foundations` Terraform state.

## Open questions

None.
