# FND-1: AWS organization, accounts and Identity Center access

**Repo:** `aws-foundations` · **Milestone:** Phase 1: Foundations · **Estimate:** 8 pts
**Labels:** `story`, `needs-approval`, `infra`, `foundations`, `dea-domain-4`
**Approver:** Lakshmi100 · **Status:** draft round 2, not yet an issue (draft ID; the real key comes from the issue number)

## User story

**As** the engineer building the Offers Platform,
**I want** the three AWS accounts in one organization, with sign-in through IAM Identity Center and no IAM users anywhere,
**so that** every later story has an account to build in and a way for people and tools to get into it without long-lived keys.

## Context

Roadmap decision: three accounts, "Management + Shared Services" (new), "ABC Bank" (new) and "Offers Platform" (existing), and "human access through IAM Identity Center only; no IAM users" (`docs/00-roadmap.md` §1, Phase 1 in §4). Spike 1 was not carried out, so nothing exists yet except the Offers Platform account. That account has IAM users and access keys in use today, most likely by laptop tools (AWS CLI, Terraform, local Airflow, Spark) reading keys from `~/.aws`. The v1/v2 code itself holds no keys, and Snowflake already reaches S3 through an IAM role.

## Requirements

1. An AWS Organization with **all features** enabled (required by Identity Center and by FND-5's organization trail), with the Management + Shared Services account as its management account and consolidated billing.
2. The ABC Bank account is created in the organization; the existing Offers Platform account is invited and joins it.
3. IAM Identity Center is enabled with one user for the engineer. MFA is required **at every sign-in**.
4. Through Identity Center the engineer gets:
   - an **administrator** role in each of the three accounts, used for setup and for applying long-lived foundations (FND-2, FND-3, FND-4, FND-5);
   - a **day-to-day engineering** role in the ABC Bank account for session work from ABC-1 on. It can:
     - run Terraform for session roots: RDS, EC2 (instances, security groups, network interfaces, interface endpoints), DMS, Secrets Manager, CloudWatch Logs, and creating IAM roles for AWS services, with `iam:PassRole` only for roles it created;
     - use (not create, delete or change the policy of) the ABC Bank KMS key;
     - read and write the ABC Bank Terraform state bucket;
     - connect to RDS with IAM database authentication (`rds-db:connect`);
     - read Cost Explorer data for the ABC Bank account.
     
     It cannot change the organization, billing, Identity Center, IAM users or access keys.
5. **No IAM users remain in any of the three accounts.** In the Offers Platform account, before deleting anything:
   - list every IAM user and access key, with when each key was last used and for what (IAM credential report and access-key last-used data);
   - replace each use: people sign in through Identity Center; laptop tools use Identity Center CLI profiles (`aws sso login`); any AWS-side workload uses an IAM role;
   - record each user, what used it, and its replacement in `README.md`;
   - then deactivate the keys, wait one working session to confirm nothing breaks, and delete the keys and users.
6. **Recovery path:** if Identity Center or a permission set breaks, the owner can still get in:
   - management account: the root user, with MFA, used only for recovery;
   - member accounts: from the management account's administrator role, assume `OrganizationAccountAccessRole` in each member account. AWS creates it in accounts made inside the organization; for the invited Offers Platform account it is created by this story.
   
   The steps are written in `README.md`.
7. CloudTrail trusted access is enabled for the organization, so FND-5 can create the organization trail without changing this story's code.
8. Everything is defined in Terraform in `aws-foundations`, except steps AWS only allows by hand, which `README.md` lists for the owner: signing up the management account and setting its root MFA, and accepting the invitation from inside the Offers Platform account.
9. Terraform state for `aws-foundations` is stored in S3 in the management account, with locking and version history, created by a documented bootstrap step. The bootstrap's own state is moved into that bucket once it exists, so no state is kept only on a laptop.

## Constraints

| Area | Constraint |
|---|---|
| Access and lock-out | Recovery path as in requirement 6, checked by AC11 before the story is done. |
| Least privilege | The engineering role's permissions are exactly those in requirement 4; administrator roles are for setup only. |
| No IAM users or long-lived keys | None in any account when the story is done (requirement 5). The management root user has MFA and no access keys. |
| Cost | Persistent. The only billable resource is the state bucket, under $0.50 per month. Organizations, Identity Center and the role assignments are free. |
| Tagging | Taggable resources carry the four cost tags with the values in `AGENTS.md`. |
| Audit | No organization trail yet (FND-5). Trusted access for CloudTrail is enabled here (requirement 7). |
| Effect on member accounts | **Offers Platform:** billing moves to the management account; AWS's default "allow everything" service control policy is attached, so nothing is restricted; its IAM users are replaced and removed (requirement 5); `OrganizationAccountAccessRole` is added. **ABC Bank:** created new. |
| Region | Identity Center and Terraform use `us-east-1`. |

## Acceptance criteria

- [ ] **AC1** From the management account, `aws organizations describe-organization` shows `FeatureSet: ALL` and this account as the management account.
- [ ] **AC2** `aws organizations list-accounts` lists exactly the three accounts, all `ACTIVE`.
- [ ] **AC3** Signing in through the Identity Center portal asks for MFA every time (MANUAL: sign out, sign in, confirm the MFA prompt).
- [ ] **AC4** From the portal, the engineer can open the administrator role in each of the three accounts (`aws sts get-caller-identity` with each role's CLI profile returns the expected account).
- [ ] **AC5** With the ABC Bank engineering role: creating and deleting a security group in `us-east-1` succeeds, and `aws ce get-cost-and-usage` for the last 7 days succeeds.
- [ ] **AC6** With the ABC Bank engineering role, `aws organizations list-accounts` is denied, and `aws iam simulate-principal-policy` shows `iam:CreateUser`, `iam:CreateAccessKey`, `kms:ScheduleKeyDeletion` and `kms:PutKeyPolicy` as denied. Destructive actions are never tested by calling them for real.
- [ ] **AC7** `aws iam list-users` returns no users in any of the three accounts, and the IAM credential report shows no active access keys, including for the management account's root user.
- [ ] **AC8** `README.md` lists every IAM user that existed in the Offers Platform account, what used it, and its replacement. With the replacement profile, `aws s3 ls` on the v2 pipeline's buckets succeeds.
- [ ] **AC9** `aws organizations list-aws-service-access-for-organization` includes `cloudtrail.amazonaws.com`.
- [ ] **AC10** From the management account's administrator role, `aws sts assume-role` into `OrganizationAccountAccessRole` succeeds for both member accounts.
- [ ] **AC11** `README.md` has the recovery steps, and following them for one member account works (the AC10 check counts for the member-account path; MANUAL: confirm root sign-in with MFA works for the management account).
- [ ] **AC12** `aws-foundations` state is in the management account's bucket: from a fresh clone, `terraform init` and `terraform state list` work; the bucket has versioning on and all public access blocked; a second concurrent `terraform apply` fails with a state-lock error.
- [ ] **AC13** `terraform plan` in every `aws-foundations` root shows no changes after apply.
- [ ] **AC14** `terraform fmt -check` and `terraform validate` pass.

## Out of scope

- Organizational units, and service control policies other than AWS's default
- A tag policy (a later `aws-foundations` story; until then each story's criteria check tags)
- CloudTrail organization trail, budgets, anomaly detection, cost-allocation tags (FND-5)
- Terraform state storage in the member accounts (FND-2 for ABC Bank; Offers Platform later)
- GitHub Actions OIDC roles
- Changes to the v1/v2 pipeline beyond switching its credentials (requirement 5)

## Depends on

- None in other stories. The manual steps in requirement 8 are part of this story and done by the owner.

## Decisions

- Nov 1, 2026: Spike 1 was not carried out, so this story creates everything.
- Nov 1, 2026: management-account Terraform lives in `aws-foundations`.
- Nov 1, 2026: the Offers Platform account's IAM users are replaced and removed in this story, not exempted.
- Nov 1, 2026: the engineer connects to RDS with IAM database authentication through the engineering role (decided for ABC-1; it shapes requirement 4).
- **Proposed defaults, for the approver to confirm:** MFA at every sign-in; one working session with keys deactivated before deleting them.

## Open questions

None.
