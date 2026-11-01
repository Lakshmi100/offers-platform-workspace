# FND-1: AWS organization, accounts and Identity Center access

**Repo:** `aws-foundations` (new) · **Milestone:** Phase 1: Foundations · **Estimate:** 5 pts
**Labels:** `story`, `needs-approval`, `infra`, `foundations`, `dea-domain-4`
**Approver:** Lakshmi100 · **Status:** draft, not yet an issue (draft ID; the real key comes from the issue number)

## User story

**As** the engineer building the Offers Platform,
**I want** the three AWS accounts in one organization, with sign-in through IAM Identity Center,
**so that** every later story has an account to build in and a way for people to get into it without IAM users or long-lived keys.

## Context

Roadmap decision: three accounts, "Management + Shared Services" (new), "ABC Bank" (new) and "Offers Platform" (existing), and "human access through IAM Identity Center only; no IAM users" (`docs/00-roadmap.md` §1, Phase 1 in §4). Spike 1 was not carried out, so nothing exists yet: this story creates everything from scratch. Organization-level infrastructure lives in its own repo, `aws-foundations`, because it is shared by every project in the organization, not only the Offers Platform.

## Requirements

1. An AWS Organization exists, with the Management + Shared Services account as its management account and consolidated billing.
2. The ABC Bank account and the Offers Platform account are members of the organization.
3. IAM Identity Center is enabled, with one user for the engineer, protected by MFA.
4. The engineer can sign in through Identity Center and get:
   - an **administrator** role in each of the three accounts, for setup work;
   - a **day-to-day engineering** role in the ABC Bank account that can do what Phase 2 needs (run Terraform for RDS, networking, KMS use, S3 state, DMS; connect to RDS) and nothing that touches the organization, billing or Identity Center.
5. Everything this story manages is defined in Terraform in the `aws-foundations` repo, except steps AWS only allows by hand (e.g. signing up the management account), which are written down in its `README.md`.
6. Terraform state for `aws-foundations` is stored in S3 in the management account, with locking and version history, created by a small bootstrap step documented in the `README.md`.

## Constraints

| Area | Constraint |
|---|---|
| Personal data | Not applicable: no data. |
| Card data (PCI) | Not applicable. |
| Network and access | No IAM users and no access keys in any account, except the management account's root user, which has MFA and is not used day to day. |
| Encryption | Not applicable (no data stores in this story). |
| Cost | Persistent: these resources stay between sessions. The story adds no billable resource beyond what AWS Organizations and Identity Center include at no charge. |
| Tagging | Taggable resources carry `data-product`, `environment`, `owner`, `cost-center`. |
| Region | Identity Center and the Terraform provider use `us-east-1`. |

## Acceptance criteria

- [ ] **AC1** `aws organizations list-accounts`, run from the management account, lists exactly the three accounts, all `ACTIVE`.
- [ ] **AC2** `aws organizations describe-organization` shows the Management + Shared Services account as the management account.
- [ ] **AC3** Signing in through the Identity Center portal requires MFA.
- [ ] **AC4** From the portal, the engineer can open the administrator role in each of the three accounts.
- [ ] **AC5** With the ABC Bank engineering role, the engineer can create and delete an S3 bucket and a security group in `us-east-1` in the ABC Bank account.
- [ ] **AC6** With the ABC Bank engineering role, `aws organizations list-accounts` and any Identity Center change are denied.
- [ ] **AC7** `aws iam list-users` returns no users in any of the three accounts, and no account has active access keys (IAM credential report).
- [ ] **AC8** `terraform plan` in `aws-foundations` shows no changes after apply (everything this story manages is in code).
- [ ] **AC10** `aws-foundations` state is in the management account's S3 bucket: `terraform state list` works from a fresh clone after `terraform init`, the bucket has versioning on and all public access blocked, and a second concurrent `terraform apply` fails with a state-lock error.
- [ ] **AC9** `terraform fmt -check` and `terraform validate` pass.

## Out of scope

- CloudTrail organization trail, budgets, anomaly detection, tag policy (FND-5)
- Terraform state storage in the member accounts (FND-2 for ABC Bank; Offers Platform in a later story)
- GitHub Actions OIDC roles
- Any resources inside the ABC Bank or Offers Platform accounts other than Identity Center role assignments

## Depends on

- The management account exists (the owner signs up for it by hand).
- The Offers Platform account exists (it does today).
- The `aws-foundations` repo exists, with the SDLC Factory installed.

## Decisions (Nov 1, 2026)

- Spike 1 was not carried out: nothing exists yet, so this story creates everything.
- Management-account Terraform lives in a new `aws-foundations` repo, not in `customer-spend-analytics`.

## Open questions

None.
