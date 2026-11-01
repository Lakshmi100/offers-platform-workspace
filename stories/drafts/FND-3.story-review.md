# Story review: FND-3 Customer-managed KMS key for ABC Bank data

Round 1 · 2026-11-01

## Gate

The orchestrator reads this block. Keep it valid JSON and keep the keys exactly.

```json
{
  "key": "FND-3",
  "round": 1,
  "score": 73,
  "threshold": 80,
  "verdict": "NEEDS_INFO",
  "blocking": [],
  "criteria": {"C1": 10, "C2": 12, "C3": 17, "C4": 12, "C5": 7, "C6": 5, "C7": 5, "C8": 5},
  "questions": 5
}
```

## Scores

| # | Criterion | Score | Max | Evidence (quoted from the story) | Gaps |
|---|-----------|-------|-----|----------------------------------|------|
| C1 | Intent and context | 10 | 10 | "As the ABC Bank data owner, I want the bank's data encrypted with a key the bank controls, so that the bank decides who can read its data, and can show an auditor who used the key." Context cites `docs/00-roadmap.md` §1 (checked: "Customer-managed KMS keys per account and per sensitive zone, with cross-account key policies") and `docs/01-business-problem.md` §8 (checked: "evidence of encryption and data deletion"); names ABC-1 as the consumer. | None. |
| C2 | Requirements | 12 | 20 | R1 key in ABC Bank account, `us-east-1`, alias naming its purpose; R2 "Automatic yearly key rotation is on"; R3 "lets the ABC Bank administrator role manage the key, and lets the ABC Bank engineering role and the AWS services Phase 2 uses (RDS, Secrets Manager, DMS) use it for encryption and decryption. No other principal can use it."; R4 "Destroying any other `abc-bank` Terraform root never schedules it for deletion"; R5 lookup by alias. | (a) R3 "use it for encryption and decryption" for RDS, Secrets Manager and DMS is vague: which KMS operations are allowed (RDS and DMS need more than Encrypt/Decrypt, e.g. data-key generation and grants), and how the services get access (through the engineering role limited to those services, through service-linked roles, or through service principals). -4. (b) R3 "manage" and "No other principal can use it" are undefined: whether the administrator role may also encrypt/decrypt, whether "manage" includes disabling and scheduling deletion, and whether the usual account-level statement that lets IAM policies grant access is allowed (it would let other principals in the account use the key) or forbidden (it risks a key no one can manage). -4. |
| C3 | Acceptance criteria | 17 | 25 | AC1–AC9 are concrete CLI or Terraform checks with expected results (e.g. AC2 "returns `KeyRotationEnabled: true`", AC4 "`schedule-key-deletion` and `put-key-policy` are denied", AC8 "leaves the key `Enabled`"). R1→AC1, R2→AC2, R3 (engineering role)→AC3, AC4, AC5, R4→AC8, R5→AC7, tagging→AC6. | (a) R3, AWS services (RDS, Secrets Manager, DMS) able to use the key: no criterion. -4. (b) R3, administrator role can manage the key, and "No other principal can use it": no criterion (AC5 only checks `"Principal": "*"` statements; nothing shows a principal other than the two roles and the services is denied, or that the administrator can change the policy). -4. |
| C4 | Constraints | 12 | 15 | All seven AGENTS.md items are in the constraints table: personal data ("its policy is the access boundary for that data"), PCI ("Same as personal data"), network and access (no unconditioned `*` principals), encryption ("This story is the encryption control"), cost ("Persistent: about $1 per month"), tagging ("four cost tags"), downstream ("key policy must be extendable without replacing the key"). | Cost / delivery: the story makes the key persistent, while AGENTS.md's definition of done says that for stories that create AWS resources "`terraform destroy` was run, nothing billable is left, and the session's cost is in the PR". The key is billable and cannot be destroyed (and KMS deletion takes at least 7 days). The story does not say how the PR meets that rule or whether a cost record is required. -3. |
| C5 | Scope boundaries | 7 | 10 | "Out of scope: Keys for the Offers Platform account or its lake zones; Cross-account key grants for DMS (a later Phase 2 story); Switching Terraform state encryption to this key". | Partly ambiguous: the title says "for ABC Bank data" and the "so that" covers "its data", but R1 says the alias names "core-banking data", and the roadmap calls for keys "per sensitive zone". A reader could disagree on whether this one key also covers other ABC Bank data in the account (e.g. the `exchange/` file buckets) or whether those get their own keys later. -3. |
| C6 | Dependencies and inputs | 5 | 10 | "FND-1: the ABC Bank account and the administrator and engineering roles. FND-2: Terraform state storage." Both confirmed as draft stories in `workspace-stories/` (FND-1 R4 defines the administrator and engineering roles; FND-2 R1 defines `abc-bank` state storage). No GitHub issues exist yet (`gh issue list` empty), as expected for drafts. | Implied, not listed: "can show an auditor who used the key" needs KMS calls recorded somewhere an auditor can read them. The organization CloudTrail trail is FND-5 (draft, confirmed); the story neither lists FND-5 nor puts audit logging in or out of scope, and no AC covers it. -5. |
| C7 | Free of design | 5 | 5 | Design detail present but each item is tied to a stated constraint or standard: lookup by alias ("without hard-coding its ID or ARN", AGENTS.md "no hard-coded account IDs"); `aws:PrincipalAccount` condition (AC5, from the network constraint); "symmetric" (AC1). | None deducted; see "Design detail to confirm". |
| C8 | Open questions resolved | 5 | 5 | "Open questions: None." No TBDs found. | None within the story (the AGENTS.md definition-of-done conflict is scored under C4). |
| | **Total** | **73** | **100** | | |

## Blocking issues
| # | Issue | Where in the story |
|---|-------|--------------------|
| | None. B1–B4 not triggered. B5 not applicable: a KMS key is billed monthly, not by the hour. B6 not applicable: no customer, account, card or transaction data is added or changed (the story still states its personal-data role). | |

## Questions for the story owner
Ordered by points recovered, largest first.

| # | Resolves | Question | Why it matters |
|---|----------|----------|----------------|
| Q1 | C2 (4), C3 (4) | How should RDS, Secrets Manager and DMS be allowed to use the key, and with which operations? Options: (1) the engineering role may use the key only when the call comes through those services; (2) the services' service-linked roles are named in the policy; (3) both. Which operations does "use for encryption and decryption" cover (only Encrypt/Decrypt, or also data-key generation, re-encryption, describe and grant creation, which RDS and DMS need)? And what criterion proves it, e.g. "with the engineering role, creating an encrypted RDS instance / Secrets Manager secret with this key succeeds"? | If the architect reads "encryption and decryption" literally, ABC-1 cannot create its encrypted database; if read broadly, the policy may allow more than you intend. The tester has no criterion for the service part of R3. |
| Q2 | C2 (4), C3 (4) | What exactly can the administrator role do: manage only, or also encrypt/decrypt? Can it disable the key and schedule deletion? Is the standard account-level statement that lets IAM policies in the ABC Bank account grant key access allowed, or must the policy name only the two roles and the services? Which criteria should show the administrator can update the key policy and that another principal in the account is denied? | "No other principal can use it" and the account-level statement conflict: one keeps the key recoverable, the other keeps access tight. The architect would otherwise pick one, and the tester cannot check the "no other principal" rule. |
| Q3 | C6 (5) | Is "show an auditor who used the key" delivered by FND-5's organization CloudTrail trail (then add FND-5 to "Depends on" and say audit logging is out of scope here), or is it part of this story (then add a requirement and a criterion, e.g. "an Encrypt call by the engineering role appears in CloudTrail within N minutes")? | The audit outcome is in the "so that" but nothing delivers or tests it; it also decides whether this story must wait for FND-5. |
| Q4 | C4 (3) | AGENTS.md's definition of done requires `terraform destroy` with nothing billable left for stories that create AWS resources, but this key must persist. How should the PR satisfy this: a stated exception for persistent foundation resources (and if so, recorded where), a monthly cost estimate instead of a session cost, or something else? | Without an answer the reviewer will flag the PR against the definition of done, or the implementer may destroy the key (a 7–30 day pending deletion that blocks ABC-1). |
| Q5 | C5 (3) | Does this one key protect all ABC Bank data in the account (core-banking database, its secrets, DMS, and later the `exchange/` file buckets), or only core-banking data, with other data getting separate keys in later stories? | Decides the alias, which services and principals the policy must allow, and whether later stories reuse this key or create their own. |

## Nice to know
- The alias value is not given ("an alias that names its purpose (core-banking data)"). ABC-1 looks the key up by this alias, so the design should state the exact alias; no need to put it in the story.
- No deletion waiting period (7–30 days) is stated for the case where the key is ever deleted on purpose; R4 already prevents accidental deletion from other roots.
- The criteria all run against the real ABC Bank account. AGENTS.md says real-AWS tests run "only when the story says so"; the ACs make this clear in practice, but one sentence saying so would remove any doubt.
- The downstream constraint ("extendable without replacing the key") has no criterion; KMS key policies can always be replaced in place, so there is little to test.
- `docs/01-business-problem.md` §8 talks about the Offers Platform being subject to the bank's vendor-risk reviews; the story cites it as the bank's own requirement for encryption evidence. The motivation still holds.
- Multi-Region keys are not mentioned; `us-east-1` only is implied, consistent with AGENTS.md.

## Design detail to confirm
- **Symmetric key** (AC1): RDS, Secrets Manager and DMS need a symmetric encryption key, so this is likely a real constraint; consider stating that reason.
- **`aws:PrincipalAccount` condition** (AC5, "or equivalent"): ties to the network constraint; the "or equivalent" already leaves the choice to the architect. Keep as is.
- **Lookup by alias** (R5, AC7): reason given ("without hard-coding its ID or ARN"). Keep.
- **Yearly rotation** (R2): a concrete value; AWS also allows custom rotation periods. Keep if yearly is the intended standard.

## Earlier questions
Not applicable (round 1).
