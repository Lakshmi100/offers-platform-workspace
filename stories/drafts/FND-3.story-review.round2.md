# Story review: FND-3 Customer-managed KMS key for ABC Bank data

Round 2 · 2026-11-01

## Gate

The orchestrator reads this block. Keep it valid JSON and keep the keys exactly.

```json
{
  "key": "FND-3",
  "round": 2,
  "score": 76,
  "threshold": 80,
  "verdict": "NEEDS_INFO",
  "blocking": ["B1"],
  "criteria": {"C1": 10, "C2": 12, "C3": 17, "C4": 12, "C5": 10, "C6": 10, "C7": 5, "C8": 0},
  "questions": 5
}
```

## Scores

| # | Criterion | Score | Max | Evidence (quoted from the story) | Gaps |
|---|-----------|-------|-----|----------------------------------|------|
| C1 | Intent and context | 10 | 10 | "As the ABC Bank data owner, I want the bank's data encrypted with a key the bank controls, so that the bank decides who can read its data, and can show an auditor who used the key." Context cites `docs/00-roadmap.md` §1 (checked in `workspace-docs/00-roadmap.md` line 40) and `docs/01-business-problem.md` §8 (checked, line 196); names ABC-1 as consumer and FND-5 as the source of the audit record. | None. |
| C2 | Requirements | 12 | 20 | R1 "It protects core-banking data: the RDS database, its secrets in Secrets Manager, its exported logs, and DMS. Other ABC Bank data (for example `exchange/` files) gets its own key in a later story." R3 lists exact operations for the engineering role ("encrypt, decrypt, re-encrypt, generate data keys, describe", "create grants only for AWS resources"), administrator "everything", "RDS, Secrets Manager and DMS: use the key only when acting for a principal in the ABC Bank account", "Anyone else: no access", "keeps AWS's standard statement…", "30 days". R2 yearly rotation; R4 persists; R5 lookup by alias. | (a) R1 says the key protects core-banking "exported logs", but R3 lets only "RDS, Secrets Manager and DMS" use the key and says "Anyone else: no access". Encrypting a CloudWatch Logs log group needs the CloudWatch Logs service itself to use the key (it does not act through grants on a caller's behalf), so as written the exported logs cannot use this key, and ABC-1 AC5 requires that they do. -4. (b) "no IAM policy other than the two roles' grants access to it": with the account statement kept, the key policy cannot enforce this on its own, and FND-1 R4 lets the engineering role create IAM roles for AWS services. Is this a state checked once at delivery (AC4c) or a lasting guarantee the key policy must enforce (for example an explicit deny for other principals)? The two lead to different key policies. -4. |
| C3 | Acceptance criteria | 17 | 25 | AC1–AC9 are concrete CLI/Terraform checks with expected results. R1→AC1; R2→AC2; R3 engineering→AC3, AC4, AC4a; administrator→AC4b; "anyone else"→AC4c, AC5; 30 days→AC8a; R4→AC8; R5→AC7; cost→AC8b; tags→AC6. | (a) R1 "its exported logs": no criterion shows a CloudWatch Logs log group can be encrypted with the key. -4. (b) R3 engineering role "create grants only for AWS resources": no criterion shows a grant that is not for an AWS resource is denied (AC4 checks only `ScheduleKeyDeletion`, `DisableKey`, `PutKeyPolicy`; AC4a checks the allowed path). -4. |
| C4 | Constraints | 12 | 15 | All seven AGENTS.md items in the constraints table: personal data ("its policy is the access boundary for that data"), PCI ("Same as personal data"), network ("No key-policy statement grants access to `*` principals without a condition…"), encryption ("This story is the encryption control"), cost ("Persistent: about $1 per month… plus request charges", AC8b), tagging ("carries the four cost tags"), downstream ("key policy must be extendable without replacing the key"). | Tagging: AGENTS.md requires the four tags "with the values under Coding standards" (`data-product = abc-bank`, `environment = dev`, `owner = Lakshmi100`, `cost-center = offers-platform-portfolio`). AC6 accepts "non-empty values", so a key with wrong tag values passes; FND-2 AC7 and ABC-1 AC7 check "the values in `AGENTS.md`". -3. |
| C5 | Scope boundaries | 10 | 10 | "Out of scope: Keys for the Offers Platform account or its lake zones; Cross-account key grants for DMS (a later Phase 2 story); Switching Terraform state encryption to this key"; R1 "Other ABC Bank data (for example `exchange/` files) gets its own key in a later story"; audit trail delivered by FND-5. | None. |
| C6 | Dependencies and inputs | 10 | 10 | "FND-1: the ABC Bank account and the administrator and engineering roles. FND-2: Terraform state storage. FND-5: the organization CloudTrail trail… FND-3 can be built first". All three confirmed as draft stories in `workspace-stories/`: FND-1 R4 defines both roles (engineering may "use (not create, delete or change the policy of) the ABC Bank KMS key") and R6 the `OrganizationAccountAccessRole` used in AC4c; FND-2 R1 defines `abc-bank` state; FND-5 R5 defines the organization trail and its context names FND-3. No GitHub issues yet (`gh issue list -R Lakshmi100/abc-bank --state all` empty), as expected for drafts. | None. |
| C7 | Free of design | 5 | 5 | Design detail is tied to a stated reason or standard: alias lookup ("without hard-coding its ID or ARN"); account statement kept ("so the key can't become unmanageable"); `aws:PrincipalAccount` "(or equivalent)" from the network constraint; 30 days ("the longest AWS allows", a proposed default scored as a requirement). | None deducted; see "Design detail to confirm". |
| C8 | Open questions resolved | 0 | 5 | "Open questions: None." | Contradiction: R3 "Anyone else: no access… no IAM policy other than the two roles' grants access to it" vs AC4c, which allows `OrganizationAccountAccessRole` ("the break-glass path from FND-1") and AWS service-linked roles to have `kms:Decrypt`. `OrganizationAccountAccessRole` has administrator permissions, so with the account statement kept it can use the key, which R3 forbids. -5. |
| | **Total** | **76** | **100** | | |

## Blocking issues
| # | Issue | Where in the story |
|---|-------|--------------------|
| B1 | Contradiction: R3 says no principal other than the administrator role, the engineering role and RDS/Secrets Manager/DMS has access, while AC4c accepts `OrganizationAccountAccessRole` and AWS service-linked roles having `kms:Decrypt`. | Requirement 3 "Anyone else"; AC4c |
| | B2–B4 not triggered. B5 not applicable: a KMS key is billed monthly, not by the hour. B6 not applicable: no customer, account, card or transaction data is added or changed (the story still states the key's personal-data role). | |

## Questions for the story owner
Ordered by points recovered, largest first.

| # | Resolves | Question | Why it matters |
|---|----------|----------|----------------|
| Q1 | C2 (4), C3 (4) | R1 says the key protects core-banking "exported logs", but R3 lets only RDS, Secrets Manager and DMS use it. Should the CloudWatch Logs service also be allowed to use the key (limited to ABC Bank log groups), or are exported logs out of this key's scope? If allowed, what criterion proves it, e.g. "creating and deleting a test log group encrypted with the key succeeds with the engineering role"? | ABC-1 AC5 requires its exported log group to use this key. If the key policy follows R3 literally, ABC-1 fails; the architect would have to guess whether to add a CloudWatch Logs statement, and the tester has no check. |
| Q2 | B1, C8 (5) | Should R3's "Anyone else: no access" list the same exceptions as AC4c (`OrganizationAccountAccessRole` as break-glass, and AWS service-linked roles), or must `OrganizationAccountAccessRole` be kept away from the key (then AC4c changes)? | The requirement and the criterion disagree; the architect would otherwise choose between keeping the break-glass path to the key and an explicit deny that removes it. |
| Q3 | C2 (4) | Is "no IAM policy other than the two roles' grants access to it" checked once when the story is delivered (AC4c), or must the key itself keep it true later, for example when the engineering role creates IAM roles for AWS services (FND-1 R4)? | A delivery-time check needs only the standard account statement; a lasting guarantee needs the key policy (or FND-1's permissions) to deny other principals. These are different designs and different tests. |
| Q4 | C3 (4) | What criterion shows the engineering role can create grants only for AWS resources, e.g. "the policy simulator shows `kms:CreateGrant` denied for the engineering role when `kms:GrantIsForAWSResource` is false"? | Without it the tester can check only the allowed path (AC4a), and a policy that lets the engineering role grant key use to any principal would pass. |
| Q5 | C4 (3) | Should AC6 check the four tags have the exact values in `AGENTS.md` (`data-product = abc-bank`, `environment = dev`, `owner = Lakshmi100`, `cost-center = offers-platform-portfolio`) rather than "non-empty values"? | The tagging standard fixes the values, and cost reporting by tag depends on them; as written, wrong values pass. |

## Nice to know
- The alias value is still not given ("an alias that names its purpose"). ABC-1 looks the key up by alias, so the design should state the exact alias; it need not be in the story.
- AC4a proves the service path with Secrets Manager only. RDS and DMS use the same grant mechanism; RDS is proven by ABC-1 AC5 and DMS by the later DMS story.
- AC7 and AC8 do not say which root is used; no session root exists until ABC-1. A throwaway root created and deleted for the check (as FND-2 AC2 does) would serve; the design can name it.
- AC4b checks the administrator's `PutKeyPolicy` and `ScheduleKeyDeletion` but not `DisableKey`; the same simulator call covers it.
- KMS cryptographic calls are CloudTrail management events, so FND-5's management-event trail records key use as long as it does not exclude KMS events; FND-5 does not mention this either way.
- The ACs all run against the real ABC Bank account. AGENTS.md runs real-AWS tests "only when the story says so"; ABC-1 has an explicit sentence, this story does not. The ACs make it clear in practice.
- AGENTS.md's long-lived-root definition of done ("`terraform plan` shows no changes after apply") applies through the DoD; no AC needed.
- The administrator and engineering roles are Identity Center roles whose names carry a generated suffix; the key policy must refer to them without hard-coded IDs (AGENTS.md coding standards). Design matter.
- The title says "for ABC Bank data" while R1 limits the key to core-banking data; R1 is clear, so the title is cosmetic.

## Design detail to confirm
- **Symmetric key** (AC1): RDS, Secrets Manager, DMS and CloudWatch Logs need a symmetric encryption key, so this is likely a real constraint; consider stating that reason.
- **`aws:PrincipalAccount` condition** (AC5, "or equivalent"): ties to the network constraint; "or equivalent" leaves the choice to the architect. Keep.
- **Lookup by alias** (R5, AC7): reason given. Keep.
- **Yearly rotation** (R2): concrete value; AWS also allows custom rotation periods. Keep if yearly is the intended standard.
- **AWS's standard account statement kept** (R3): reason given ("so the key can't become unmanageable"). Keep; see Q3 for its interaction with "no other IAM policy".
- **Policy simulator as the test method** (AC4, AC4b, AC4c): a test approach that avoids calling destructive actions for real; consistent with FND-1 AC6. Keep.

## Earlier questions

| Round 1 | Status | Where answered |
|---------|--------|----------------|
| Q1 How RDS, Secrets Manager and DMS use the key, which operations, which criterion | Answered | R3 lists the engineering role's operations, "create grants only for AWS resources", and services "only when acting for a principal in the ABC Bank account"; AC4a. (New follow-ups: Q1 on CloudWatch Logs, Q4 on the grant restriction.) |
| Q2 What the administrator can do; account-level statement; criteria for admin and "no other principal" | Answered | R3 administrator "everything, including changing the key policy, disabling the key and scheduling its deletion"; account statement kept; AC4b, AC4c. (New follow-ups: Q2 contradiction with AC4c, Q3.) |
| Q3 Audit via FND-5 or in this story | Answered | FND-5 added to "Depends on"; context: "the record of who used the key comes from FND-5's organization CloudTrail trail"; "FND-3 can be built first". |
| Q4 Definition of done vs a persistent key | Answered | AGENTS.md now separates long-lived roots (PR states monthly cost; plan shows no changes) from session roots; story: cost "Persistent: about $1 per month", AC8b. |
| Q5 One key for all ABC Bank data or core-banking only | Answered | R1: "It protects core-banking data… Other ABC Bank data (for example `exchange/` files) gets its own key in a later story." |
