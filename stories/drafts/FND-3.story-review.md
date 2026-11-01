# Story review: FND-3 Customer-managed KMS key for ABC Bank data

Round 3 · 2026-11-01

## Gate

The orchestrator reads this block. Keep it valid JSON and keep the keys exactly.

```json
{
  "key": "FND-3",
  "round": 3,
  "score": 88,
  "threshold": 80,
  "verdict": "READY",
  "blocking": [],
  "criteria": {"C1": 10, "C2": 16, "C3": 17, "C4": 15, "C5": 10, "C6": 10, "C7": 5, "C8": 5},
  "questions": 3
}
```

## Scores

| # | Criterion | Score | Max | Evidence (quoted from the story) | Gaps |
|---|-----------|-------|-----|----------------------------------|------|
| C1 | Intent and context | 10 | 10 | "As the ABC Bank data owner, I want the bank's data encrypted with a key the bank controls, so that the bank decides who can read its data, and can show an auditor who used the key." Context cites `docs/00-roadmap.md` §1 (checked: `workspace-docs/00-roadmap.md` line 40, "Customer-managed KMS keys per account and per sensitive zone…") and `docs/01-business-problem.md` §8 (checked: "## 8. Constraints"); names ABC-1 as consumer and FND-5's trail as the audit record. | None. |
| C2 | Requirements | 16 | 20 | R1 scope "core-banking data: the RDS database, its secrets in Secrets Manager, its exported logs, and DMS"; R2 "Automatic yearly key rotation is on"; R3 per-principal rights (administrator "everything…"; engineering "encrypt, decrypt, re-encrypt, generate data keys, describe… create grants only for AWS resources"; services "only when acting for a principal in the ABC Bank account (through grants)"; "CloudWatch Logs: use the key to encrypt log groups in the ABC Bank account in `us-east-1` (core-banking logs that RDS exports), and no other log groups"; break-glass `OrganizationAccountAccessRole`; "Anyone else: no access… stays true over time because FND-1's permissions boundary stops roles created by the engineering role from using the key directly"; "30 days"); R4 persists; R5 lookup by alias. | CloudWatch Logs scope is ambiguous: "log groups in the ABC Bank account in `us-east-1`" reads as any log group in the account, while the parenthetical "(core-banking logs that RDS exports), and no other log groups" reads as only the RDS export log groups (`/aws/rds/...`). The two give different key-policy conditions, and decide whether AC4e's "test CloudWatch log group" must be named like an RDS export group. -4. |
| C3 | Acceptance criteria | 17 | 25 | AC1–AC9 are concrete CLI/Terraform checks with expected results. R1→AC1; R2→AC2; engineering use→AC3, AC4a; engineering denials→AC4; grant restriction→AC4d; administrator→AC4b; CloudWatch Logs allowed path→AC4e; "anyone else"→AC4c, AC5; lasting guarantee→AC4f; tags→AC6 ("with the values in `AGENTS.md`"); R5→AC7; R4→AC8; 30 days→AC8a; cost→AC8b; fmt/validate→AC9. | (a) R3 CloudWatch Logs "and no other log groups": no criterion shows the key cannot be used for a log group outside the allowed set (AC4e checks only the allowed path; AC5 covers `*` principals, not the CloudWatch Logs service principal). -4. (b) AC4f does not say what identity policy the test role has. A role with no `kms:Decrypt` in its own policy is denied regardless of the boundary, so AC4f passes even if FND-1's boundary did not exclude the key; it does not prove "stays true over time". -4. |
| C4 | Constraints | 15 | 15 | All seven AGENTS.md items in the constraints table: personal data ("its policy is the access boundary for that data"), PCI ("Same as personal data"), network ("No key-policy statement grants access to `*` principals without a condition limiting it to the ABC Bank account"), encryption ("This story is the encryption control"), cost ("Persistent: about $1 per month for the key, plus request charges", AC8b), tagging ("carries the four cost tags", AC6 checks the AGENTS.md values), downstream ("key policy must be extendable without replacing the key"). | None. |
| C5 | Scope boundaries | 10 | 10 | "Out of scope: Keys for the Offers Platform account or its lake zones; Cross-account key grants for DMS (a later Phase 2 story); Switching Terraform state encryption to this key"; R1 "Other ABC Bank data (for example `exchange/` files) gets its own key in a later story". | None. |
| C6 | Dependencies and inputs | 10 | 10 | "FND-1: the ABC Bank account, the administrator and engineering roles, and the permissions boundary. FND-2: Terraform state storage. FND-5: the organization CloudTrail trail… FND-3 can be built first". Confirmed in `workspace-stories/`: FND-1 R4 (both roles; engineering "use (not create, delete, disable or change the policy of) the ABC Bank KMS key"; may create roles only with the boundary), R5 (boundary denies "using the ABC Bank core-banking KMS key directly (AWS services still use it through grants, FND-3)"), R7 (`OrganizationAccountAccessRole`), AC5 (engineering allowed `secretsmanager:CreateSecret`, `logs:CreateLogGroup`, `iam:CreateRole` with boundary, used by AC4a/AC4e/AC4f); FND-2 (state; names FND-3); FND-5 R5 (organization trail, read and write management events). All are draft stories; `gh issue list -R Lakshmi100/abc-bank --state all` returns nothing, as expected. | None. |
| C7 | Free of design | 5 | 5 | Design detail is tied to a reason or standard: alias lookup ("without hard-coding its ID or ARN"); account statement kept ("so the key can't become unmanageable"); `aws:PrincipalAccount` "(or equivalent)"; 30 days ("the longest AWS allows"); `kms:GrantIsForAWSResource` in AC4d expresses R3's "create grants only for AWS resources". Proposed defaults scored as stated requirements. | None deducted; see "Design detail to confirm". |
| C8 | Open questions resolved | 5 | 5 | "Open questions: None." R3 now lists `OrganizationAccountAccessRole` and service-linked roles as exceptions, matching AC4c. | None. No TBDs or contradictions found. |
| | **Total** | **88** | **100** | | |

## Blocking issues
| # | Issue | Where in the story |
|---|-------|--------------------|
| | None. B1 (round 2 contradiction) is resolved: R3 "Break-glass" and AC4c now agree. B2–B4 not triggered. B5 not applicable: a KMS key is billed monthly, not by the hour. B6 not applicable: no customer, account, card or transaction data is added or changed (the story still states the key's personal-data role). | |

## Questions for the story owner
Ordered by points recovered, largest first.

| # | Resolves | Question | Why it matters |
|---|----------|----------|----------------|
| Q1 | C2 (4) | Which log groups may CloudWatch Logs encrypt with the key: any log group in the ABC Bank account in `us-east-1`, or only the log groups RDS exports to (`/aws/rds/...`)? | The key policy's CloudWatch Logs condition differs (account-wide log-group ARN vs an RDS-prefixed one), and AC4e's test log group would fail under the narrower reading unless it is named like an RDS export group. The architect and tester would otherwise pick one. |
| Q2 | C3 (4) | What criterion shows "no other log groups" holds, for example "creating a log group outside the allowed set (name or account) with the key fails", or "the key policy's CloudWatch Logs statement is limited by an encryption-context condition to the allowed log groups"? | Without it only the allowed path is tested; a key policy that lets CloudWatch Logs use the key for any log group anywhere would pass. Which check is practical depends on the answer to Q1. |
| Q3 | C3 (4) | In AC4f, should the test role have an identity policy that allows `kms:Decrypt` on the key (so only FND-1's boundary can cause the denial)? | As written, a test role with no permissions is denied anyway, so AC4f passes even if the boundary does not cover the key; it would not prove R3's "stays true over time". |

## Nice to know
- The alias value is still not given ("an alias that names its purpose"). ABC-1 looks the key up by alias, so the design should state the exact alias; it need not be in the story.
- R3's lasting guarantee covers roles created by the engineering role. Roles created by the administrator role (not held by the boundary) could still be given key access through the account statement; FND-1 limits that role to setup and recovery, and AC4c checks the state at delivery.
- AC4a "creating and deleting a small test secret": Secrets Manager deletes with a 7–30 day recovery window by default; deleting without a recovery window leaves nothing behind. The design can say so.
- AC4b checks the administrator's `PutKeyPolicy` and `ScheduleKeyDeletion` but not `DisableKey`; the same simulator call covers it.
- AC4a proves the service path with Secrets Manager only; RDS is proven by ABC-1 AC5 and DMS by the later DMS story.
- AC7 and AC8 do not say which root is used; no session root exists until ABC-1. A throwaway root created and deleted for the check would serve; the design can name it.
- FND-5 R5 records read and write management events with no exclusions, so KMS calls on this key are recorded; neither story has a criterion showing a KMS event in the trail.
- The ACs all run against the real ABC Bank account. AGENTS.md runs real-AWS tests "only when the story says so"; this story has no explicit sentence (FND-1 and ABC-1 do), but the ACs make it clear in practice.
- AGENTS.md's long-lived-root definition of done ("`terraform plan` shows no changes after apply") applies through the DoD; no AC needed.
- The administrator and engineering roles are Identity Center roles whose names carry a generated suffix; the key policy must refer to them without hard-coded IDs (AGENTS.md coding standards). Design matter.
- The title says "for ABC Bank data" while R1 limits the key to core-banking data; R1 is clear, so the title is cosmetic.

## Design detail to confirm
- **Symmetric key** (AC1): RDS, Secrets Manager, DMS and CloudWatch Logs need a symmetric encryption key, so this is likely a real constraint; consider stating that reason.
- **`aws:PrincipalAccount` condition** (AC5, "or equivalent"): ties to the network constraint; "or equivalent" leaves the choice to the architect. Keep.
- **`kms:GrantIsForAWSResource`** (AC4d): the standard way to express R3's "create grants only for AWS resources". Keep.
- **Lookup by alias** (R5, AC7): reason given. Keep.
- **Yearly rotation** (R2): concrete value; AWS also allows custom rotation periods. Keep if yearly is the intended standard.
- **AWS's standard account statement kept** (R3): reason given ("so the key can't become unmanageable"). Keep.
- **Policy simulator as the test method** (AC4, AC4b, AC4c, AC4d, AC4f): avoids calling destructive actions for real; consistent with FND-1's "Checks that something is denied use `aws iam simulate-principal-policy`". Keep.

## Earlier questions

| Round 2 | Status | Where answered |
|---------|--------|----------------|
| B1 Contradiction between R3 "Anyone else" and AC4c | Answered | R3 "Break-glass: `OrganizationAccountAccessRole` (FND-1's recovery path) has full administrator rights by design and so can use the key. AWS service-linked roles act only for their service."; AC4c lists the same exceptions. |
| Q1 CloudWatch Logs use of the key, and its criterion | Answered | R3 "CloudWatch Logs: use the key to encrypt log groups in the ABC Bank account in `us-east-1`…"; AC4e. (Follow-ups: Q1 on which log groups, Q2 on the negative case.) |
| Q2 Exceptions in "Anyone else" vs AC4c | Answered | Same as B1. |
| Q3 Delivery-time check or lasting guarantee | Answered | R3 "This stays true over time because FND-1's permissions boundary stops roles created by the engineering role from using the key directly"; FND-1 R5; AC4f. (Follow-up: Q3 on AC4f's test role.) |
| Q4 Criterion for "create grants only for AWS resources" | Answered | AC4d: `kms:CreateGrant` allowed when `kms:GrantIsForAWSResource` is true, denied when false. |
| Q5 AC6 tag values | Answered | AC6 "with the values in `AGENTS.md`". |

Round 1 questions Q1–Q5 were all answered by round 2 (see `story-review.round2.md`).
