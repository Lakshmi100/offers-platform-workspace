# Story review: FND-4 Private network for the ABC Bank account

Round 1 · 2026-11-01

## Gate

The orchestrator reads this block. Keep it valid JSON and keep the keys exactly.

```json
{
  "key": "FND-4",
  "round": 1,
  "score": 84,
  "threshold": 80,
  "verdict": "READY",
  "blocking": [],
  "criteria": {"C1": 10, "C2": 12, "C3": 21, "C4": 15, "C5": 6, "C6": 10, "C7": 5, "C8": 5},
  "questions": 5
}
```

## Scores

| # | Criterion | Score | Max | Evidence (quoted from the story) | Gaps |
|---|-----------|-------|-----|----------------------------------|------|
| C1 | Intent and context | 10 | 10 | "As the engineer building ABC Bank's systems, I want a private network in the ABC Bank account that RDS and DMS can run in, so that the core-banking database and change data capture never need to be on the internet." Context quotes `docs/00-roadmap.md` §4 Phase 1 and §6 (verified in the roadmap) and names ABC-1 and the later DMS story as consumers. | None. |
| C2 | Requirements | 12 | 20 | R1 "private subnets ... in at least two Availability Zones"; R2 "can reach Amazon S3 without going through the internet"; R3 "Nothing in the private subnets can be reached from the internet, and nothing in them can reach the internet"; R4 "find the VPC and its private subnets by name or tag"; R5 "persists between sessions. Any part of it billed by the hour is not created by this story". | (1) R2 does not say which S3 buckets the private subnets may reach: whatever the endpoint allows is the S3 boundary for a network that will hold personal data (-4). (2) Whether an internet gateway may be attached to the VPC at all is not stated. The constraint says only "no internet gateway route from private subnets", and AC2 checks only routes. ABC-1's access path may want one later (-4). |
| C3 | Acceptance criteria | 21 | 25 | AC1–AC9 are all pass/fail with a command or a check: R1→AC1, R2→AC3, R3→AC2/AC4, R4→AC7, R5→AC6/AC8, tagging→AC5, lint→AC9. | The downstream constraint "The design must leave room for DMS in the same private subnets and for the engineer access path in ABC-1" has no criterion, and "leave room" is not defined well enough to write one (-4). |
| C4 | Constraints | 15 | 15 | Constraints table covers every AGENTS.md item: personal data and PCI "Not applicable: no data"; network "No NAT gateway, no internet gateway route from private subnets, no public subnets"; encryption "Not applicable"; cost "Persistent and free of hourly charges" (with AC6); tagging "four cost tags"; downstream compatibility stated. | None. Teardown and session-cost recording do not apply: R5 and AC6 rule out hourly-billed resources. |
| C5 | Scope boundaries | 6 | 10 | Out of scope: "Interface VPC endpoints ... and anything else billed by the hour", "The engineer access path to RDS (ABC-1)", "Networking in the Offers Platform or management accounts", "VPC flow logs". | (1) Roadmap §6 says "S3 and DynamoDB gateway endpoints", but the story mentions only S3. It does not say whether a DynamoDB gateway endpoint is in or out (-2). (2) It does not say what happens to the account's default VPC in `us-east-1`, which has public subnets and an internet gateway (-2). |
| C6 | Dependencies and inputs | 10 | 10 | "FND-1: the ABC Bank account and the administrator and engineering roles." "FND-2: Terraform state storage." | None. Both exist as draft stories (`workspace-stories/FND-1.md`, `FND-2.md`). No GitHub issues exist yet (`gh issue list -R Lakshmi100/abc-bank --state all` returned none). I found no implied dependency that is missing. |
| C7 | Free of design | 5 | 5 | The story names "S3 gateway endpoint" and "no NAT gateway", with the reason: the roadmap FinOps guardrail and "free of hourly charges". Everything else is stated as an outcome. | None (see "Design detail to confirm"). |
| C8 | Open questions resolved | 5 | 5 | "Open questions: None." | No TBDs or contradictions inside the story. |
| | **Total** | **84** | **100** | | |

## Blocking issues
| # | Issue | Where in the story |
|---|-------|--------------------|
| – | None. B1: no open questions. B2: all ACs are testable. B3: FND-1 and FND-2 exist as stories. B4: nothing forbidden; it honours "Do not create NAT gateways". B5: no hourly-billed resources (R5, AC6). B6: no customer, account, card or transaction data. | – |

## Questions for the story owner
Ordered by points recovered, largest first.

| # | Resolves | Question | Why it matters |
|---|----------|----------|----------------|
| Q1 | C2 | Which S3 buckets should the private subnets be able to reach through the gateway endpoint: any bucket, only buckets in the organization's accounts, or a named list (for example the Offers Platform intake bucket)? | Without an answer the architect has to guess the endpoint policy, which is the S3 boundary for a network that will hold personal data. The tester has no rule to check it against. |
| Q2 | C2 | May an internet gateway be attached to this VPC, now or later (for example by ABC-1's access path), or must the VPC never have one? | AC2 checks only routes. If "never" is the rule, the design and the tests change: an AC would check that no internet gateway is attached, and ABC-1 could not choose a public bastion. |
| Q3 | C3 | What does "leave room for DMS ... and for the engineer access path" require in concrete terms (for example a minimum number of free IP addresses per subnet, or specific VPC settings), and how should it be checked? | As written it cannot be tested, so the tester cannot write a case for it and the architect has to guess the subnet size and settings. |
| Q4 | C5 | Is a DynamoDB gateway endpoint (named in roadmap §6) in scope for this story or out of scope? | It decides whether the design adds a second endpoint and whether an AC checks it. |
| Q5 | C5 | Should this story delete, keep, or leave alone the default VPC in the ABC Bank account's `us-east-1` region? | The default VPC has public subnets and an internet gateway. Readers could disagree on whether "no public endpoints" covers it. Deleting it is a separate piece of Terraform work, and it needs its own test. |

## Nice to know
- The exact name or tag values that other roots use for the lookup (R4, AC7) can be left to the architect. They should be recorded in `design.md` so that ABC-1 and the DMS story use the same ones.
- The VPC CIDR range is not stated. Nothing in the roadmap plans VPC peering with the Offers Platform (DMS writes to S3), so the architect can choose it.
- A later DMS story that reads the RDS password from Secrets Manager will need an interface endpoint, which is billed by the hour, or another path. Under R5 that story creates and destroys it per session. This is noted so that the cost is not a surprise.
- Roadmap Phase 1 exit says "`terraform destroy` removes it cleanly", but R5 says the network persists. The story's position, matching FND-2, FND-3 and ABC-1, is clear. The roadmap wording could be updated.
- The new VPC's default security group (which allows all traffic inside the group by default) is not mentioned. The architect may choose to restrict it.
- AC5 does not say how to check tags. ABC-1 uses the Resource Groups Tagging API, and the same method would keep them consistent.

## Design detail to confirm
- **S3 gateway endpoint instead of a NAT gateway** (R2, AC3, constraints). The reason is stated: roadmap FinOps guardrail "No NAT gateway" and the AGENTS.md boundary. Recommend keeping it as a constraint.
- **"no public subnets"** (constraints). It follows from R3. Keep it.

## Earlier questions
None (round 1).
