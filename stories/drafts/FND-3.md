# FND-3: Customer-managed KMS key for ABC Bank data

**Repo:** `abc-bank` (`infra/`) · **Milestone:** Phase 1: Foundations · **Estimate:** 2 pts
**Labels:** `story`, `needs-approval`, `infra`, `abc-bank`, `dea-domain-4`
**Approver:** Lakshmi100 · **Status:** draft round 2, not yet an issue (draft ID; the real key comes from the issue number)

## User story

**As** the ABC Bank data owner,
**I want** the bank's data encrypted with a key the bank controls,
**so that** the bank decides who can read its data, and can show an auditor who used the key.

## Context

Roadmap standard: "Customer-managed KMS keys per account and per sensitive zone, with cross-account key policies" (`docs/00-roadmap.md` §1). ABC-1 encrypts the core-banking database with this key. Evidence of encryption and of key use matters when the bank and the platform go through vendor-risk reviews (`docs/01-business-problem.md` §8); the record of who used the key comes from FND-5's organization CloudTrail trail.

## Requirements

1. A customer-managed KMS key exists in the ABC Bank account in `us-east-1`, with an alias that names its purpose. It protects **core-banking data**: the RDS database, its secrets in Secrets Manager, its exported logs, and DMS. Other ABC Bank data (for example `exchange/` files) gets its own key in a later story.
2. Automatic yearly key rotation is on.
3. Who can do what with the key:
   - **Administrator role:** everything, including changing the key policy, disabling the key and scheduling its deletion.
   - **Engineering role:** use the key for encryption (encrypt, decrypt, re-encrypt, generate data keys, describe), and let RDS, Secrets Manager and DMS use it on its behalf (create grants only for AWS resources). It cannot change the policy, disable the key or schedule deletion.
   - **RDS, Secrets Manager and DMS:** use the key only when acting for a principal in the ABC Bank account.
   - **Anyone else:** no access. The key policy keeps AWS's standard statement that lets the ABC Bank account's IAM policies grant access, so the key can't become unmanageable; no IAM policy other than the two roles' grants access to it.
   - A deliberate deletion waits **30 days**, the longest AWS allows.
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
- [ ] **AC4** For the ABC Bank engineering role, `aws iam simulate-principal-policy` (with the key policy as resource policy) shows `kms:ScheduleKeyDeletion`, `kms:DisableKey` and `kms:PutKeyPolicy` on the key as denied. These are never tested by calling them for real.
- [ ] **AC4a** With the ABC Bank engineering role, creating and deleting a small test secret in Secrets Manager encrypted with the key succeeds (proves AWS services can use the key on the role's behalf).
- [ ] **AC4b** With the ABC Bank administrator role, `aws kms get-key-policy` succeeds, and the policy simulator shows `kms:PutKeyPolicy` and `kms:ScheduleKeyDeletion` allowed.
- [ ] **AC4c** Apart from the administrator role, the engineering role, `OrganizationAccountAccessRole` (the break-glass path from FND-1) and AWS service-linked roles, no IAM role in the ABC Bank account is allowed `kms:Decrypt` on the key (checked with `aws iam simulate-principal-policy` for each role).
- [ ] **AC5** The key policy has no statement that allows `"Principal": "*"` without an `aws:PrincipalAccount` (or equivalent) condition for the ABC Bank account.
- [ ] **AC6** The key carries the four cost tags with non-empty values.
- [ ] **AC7** A Terraform root that looks the key up by alias plans without errors.
- [ ] **AC8** Running `terraform destroy` in a session root leaves the key `Enabled`.
- [ ] **AC8a** The key's deletion window is set to 30 days in Terraform.
- [ ] **AC8b** The PR states the key's monthly cost (about $1 plus requests).
- [ ] **AC9** `terraform fmt -check` and `terraform validate` pass.

## Out of scope

- Keys for the Offers Platform account or its lake zones
- Cross-account key grants for DMS (a later Phase 2 story)
- Switching Terraform state encryption to this key

## Depends on

- FND-1: the ABC Bank account and the administrator and engineering roles.
- FND-2: Terraform state storage.
- FND-5: the organization CloudTrail trail, which records who used the key. FND-3 can be built first; the audit record exists once FND-5 is done.

## Decisions

- **Proposed defaults, for the approver to confirm:** one key for core-banking data only; 30-day deletion window; AWS's standard account statement kept in the key policy.

## Open questions

None.
