# FND-2: Terraform state storage for the ABC Bank account

**Repo:** `abc-bank` (`infra/`) · **Milestone:** Phase 1: Foundations · **Estimate:** 2 pts
**Labels:** `story`, `needs-approval`, `infra`, `abc-bank`, `dea-domain-2`
**Approver:** Lakshmi100 · **Status:** draft, not yet an issue (draft ID; the real key comes from the issue number)

## User story

**As** the engineer building ABC Bank's infrastructure,
**I want** Terraform state for the ABC Bank account stored remotely, with locking,
**so that** state survives between sessions and laptops, and two runs can't corrupt it.

## Context

Roadmap standard: "Terraform for all infrastructure, with remote state in S3 and locking; one state per account" (`docs/00-roadmap.md` §1). Every Terraform story in `abc-bank` (FND-3, FND-4, ABC-1 onwards) stores its state here.

## Requirements

1. Terraform state for every `abc-bank` Terraform root is stored in S3 in the ABC Bank account, in `us-east-1`.
2. Two Terraform runs against the same state cannot run at once: the second waits or fails with a lock error.
3. Earlier versions of each state file are kept, so a damaged state can be restored.
4. The state storage itself is created by a small bootstrap step that is documented in `infra/README.md`, because it has to exist before any other Terraform can use it.
5. The state storage persists. Destroying any other `abc-bank` Terraform root never removes it.

## Constraints

| Area | Constraint |
|---|---|
| Personal data | State may contain resource identifiers and connection details, not personal data. |
| Card data (PCI) | Not applicable. |
| Network and access | The bucket is never public; only the ABC Bank administrator and engineering roles (FND-1) can read or write state. |
| Encryption | State is encrypted at rest. The ABC Bank customer-managed key (FND-3) is not yet available when state is first created, so the AWS-managed S3 key is acceptable here. |
| Cost | Persistent. Storage and request costs stay under $0.50 per month at this project's size. |
| Tagging | The bucket and any other resource carry the four cost tags. |
| Downstream compatibility | Not applicable. |

## Acceptance criteria

- [ ] **AC1** Following `infra/README.md` from an empty ABC Bank account creates the state storage without errors.
- [ ] **AC2** A Terraform root configured with the documented backend settings runs `terraform init` and `terraform apply` with its state stored in the bucket.
- [ ] **AC3** Starting a second `terraform apply` on the same root while one is running fails with a state-lock error.
- [ ] **AC4** After two applies that change state, the bucket holds at least two versions of the state file.
- [ ] **AC5** `aws s3api get-public-access-block` shows all four public-access blocks enabled, and the bucket policy denies requests that don't use TLS.
- [ ] **AC6** `aws s3api get-bucket-encryption` shows encryption at rest enabled.
- [ ] **AC7** The bucket has all four cost tags with non-empty values.
- [ ] **AC8** Running `terraform destroy` in a test root that uses this backend leaves the state bucket and its other state files in place.
- [ ] **AC9** `terraform fmt -check` and `terraform validate` pass for the bootstrap code.

## Out of scope

- State storage for the management and Offers Platform accounts
- Switching state encryption to the customer-managed key (a later change once FND-3 exists)
- CI access to state (GitHub Actions OIDC)

## Depends on

- FND-1: the ABC Bank account and the administrator and engineering roles.

## Open questions

None.
