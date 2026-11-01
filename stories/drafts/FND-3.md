# FND-3: Customer-managed KMS key for ABC Bank data

**Repo:** `abc-bank` (`infra/`) · **Milestone:** Phase 1: Foundations · **Estimate:** 2 pts
**Labels:** `story`, `needs-approval`, `infra`, `abc-bank`, `dea-domain-4`
**Approver:** Lakshmi100 · **Status:** draft, not yet an issue (draft ID; the real key comes from the issue number)

## User story

**As** the ABC Bank data owner,
**I want** the bank's data encrypted with a key the bank controls,
**so that** the bank decides who can read its data, and can show an auditor who used the key.

## Context

Roadmap standard: "Customer-managed KMS keys per account and per sensitive zone, with cross-account key policies" (`docs/00-roadmap.md` §1). ABC-1 encrypts the core-banking database with this key. The business problem doc requires evidence of encryption for the bank's vendor-risk reviews (`docs/01-business-problem.md` §8).

## Requirements

1. A customer-managed KMS key exists in the ABC Bank account in `us-east-1`, with an alias that names its purpose (core-banking data).
2. Automatic yearly key rotation is on.
3. The key policy lets the ABC Bank administrator role manage the key, and lets the ABC Bank engineering role and the AWS services Phase 2 uses (RDS, Secrets Manager, DMS) use it for encryption and decryption. No other principal can use it.
4. The key persists. Destroying any other `abc-bank` Terraform root never schedules it for deletion.
5. Other Terraform roots in `abc-bank` can find the key by its alias, without hard-coding its ID or ARN.

## Constraints

| Area | Constraint |
|---|---|
| Personal data | The key will protect personal data from ABC-2 on; its policy is the access boundary for that data. |
| Card data (PCI) | Same as personal data. |
| Network and access | No key-policy statement grants access to `*` principals without a condition limiting it to the ABC Bank account. |
| Encryption | This story is the encryption control. |
| Cost | Persistent: about $1 per month for the key, plus request charges. |
| Tagging | The key carries the four cost tags. |
| Downstream compatibility | Cross-account grants for the Offers Platform (DMS writing to the platform's intake) are not part of this story, but the key policy must be extendable without replacing the key. |

## Acceptance criteria

- [ ] **AC1** `aws kms describe-key` on the alias shows a customer-managed, enabled, symmetric key in the ABC Bank account in `us-east-1`.
- [ ] **AC2** `aws kms get-key-rotation-status` returns `KeyRotationEnabled: true`.
- [ ] **AC3** With the ABC Bank engineering role, `aws kms encrypt` and `aws kms decrypt` of a test string with the key succeed.
- [ ] **AC4** With the ABC Bank engineering role, `aws kms schedule-key-deletion` and `aws kms put-key-policy` are denied.
- [ ] **AC5** The key policy has no statement that allows `"Principal": "*"` without an `aws:PrincipalAccount` (or equivalent) condition for the ABC Bank account.
- [ ] **AC6** The key carries the four cost tags with non-empty values.
- [ ] **AC7** A Terraform root that looks the key up by alias plans without errors.
- [ ] **AC8** Running `terraform destroy` in another `abc-bank` root leaves the key `Enabled`.
- [ ] **AC9** `terraform fmt -check` and `terraform validate` pass.

## Out of scope

- Keys for the Offers Platform account or its lake zones
- Cross-account key grants for DMS (a later Phase 2 story)
- Switching Terraform state encryption to this key

## Depends on

- FND-1: the ABC Bank account and the administrator and engineering roles.
- FND-2: Terraform state storage.

## Open questions

None.
