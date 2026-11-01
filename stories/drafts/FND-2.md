# FND-2: Terraform state storage for the ABC Bank account

**Repo:** `abc-bank` (`infra/`) · **Milestone:** Phase 1: Foundations · **Estimate:** 2 pts
**Labels:** `story`, `needs-approval`, `infra`, `abc-bank`, `dea-domain-2`
**Approver:** Lakshmi100 · **Status:** draft round 2, not yet an issue (draft ID; the real key comes from the issue number)

## User story

**As** the engineer building ABC Bank's infrastructure,
**I want** Terraform state for the ABC Bank account stored remotely, with locking,
**so that** state survives between sessions and laptops, and two runs can't corrupt it.

## Context

Roadmap standard: "Terraform for all infrastructure, with remote state in S3 and locking; one state bucket per account, with separate Terraform roots for long-lived foundations and per-session resources" (`docs/00-roadmap.md` §1). Every Terraform story in `abc-bank` (FND-3, FND-4, ABC-1 onwards) stores its state here.

## Requirements

1. Terraform state for every `abc-bank` Terraform root is stored in S3 in the ABC Bank account, in `us-east-1`.
2. Two Terraform runs against the same state cannot run at once: the second waits or fails with a lock error.
3. Earlier versions of each state file are kept, so a damaged state can be restored.
4. The state storage is created by its own Terraform root, `infra/bootstrap/`, documented in `infra/README.md`, because it has to exist before any other root can use it. Once the bucket exists, the bootstrap's own state is moved into it, so no state is kept only on a laptop.
5. The state storage persists. Destroying any other `abc-bank` Terraform root never removes it.

## Constraints

| Area | Constraint |
|---|---|
| Personal data | State may contain resource identifiers and connection details, not personal data. |
| Card data (PCI) | Not applicable. |
| Network and access | The bucket is never public. Only the ABC Bank administrator and engineering roles (FND-1), plus `OrganizationAccountAccessRole` for recovery, can read or write state. Requests that don't use TLS are refused, so state is encrypted in transit as well as at rest. |
| Encryption | State is encrypted at rest. The ABC Bank customer-managed key (FND-3) is not yet available when state is first created, so the AWS-managed S3 key is acceptable here. |
| Cost | Long-lived root. Storage and request costs stay under $0.50 per month at this project's size; the PR states the expected monthly cost. |
| Tagging | The bucket and any other resource carry the four cost tags. |
| Downstream compatibility | Not applicable. |

## Acceptance criteria

- [ ] **AC1** Following `infra/README.md` from an empty ABC Bank account creates the state storage without errors.
- [ ] **AC2** A throwaway test root (created for this check and deleted after) configured with the documented backend settings runs `terraform init` and `terraform apply` with its state stored in the bucket.
- [ ] **AC2a** `terraform state list` in `infra/bootstrap/` works from a fresh clone: the bootstrap's state is in the bucket, not on a laptop.
- [ ] **AC3** Starting a second `terraform apply` on the same root while one is running fails with a state-lock error.
- [ ] **AC4** After two applies that change state, the bucket holds at least two versions of the state file.
- [ ] **AC5** `aws s3api get-public-access-block` shows all four public-access blocks enabled, and the bucket policy denies requests that don't use TLS.
- [ ] **AC6** `aws s3api get-bucket-encryption` shows encryption at rest enabled.
- [ ] **AC7** The bucket, and any lock store if the design uses one, has the four cost tags with the values in `AGENTS.md`.
- [ ] **AC7a** `aws iam simulate-principal-policy` with the bucket policy shows `s3:GetObject` and `s3:PutObject` on state allowed for the administrator and engineering roles, and denied for any other role in the account apart from `OrganizationAccountAccessRole` and AWS service-linked roles.
- [ ] **AC8** Running `terraform destroy` in the throwaway test root leaves the state bucket and every other root's state file in place.
- [ ] **AC8a** The PR states the bucket's expected monthly cost, under $0.50.
- [ ] **AC9** `terraform fmt -check` and `terraform validate` pass for the bootstrap code.

## Out of scope

- State storage for the management and Offers Platform accounts
- Switching state encryption to the customer-managed key (a later change once FND-3 exists)
- CI access to state (GitHub Actions OIDC)

## Depends on

- FND-1: the ABC Bank account and the administrator and engineering roles.

## Decisions

- Nov 1, 2026: `abc-bank` uses one state bucket with several Terraform roots split by lifecycle (bootstrap, long-lived, session), per `AGENTS.md`.
- **Proposed default, for the approver to confirm:** TLS-only access to the state bucket.

## Open questions

None.
