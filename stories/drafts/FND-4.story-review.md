# Story review: FND-4 Private network for the ABC Bank account

Round 2 · 2026-11-01

## Gate

The orchestrator reads this block. Keep it valid JSON and keep the keys exactly.

```json
{
  "key": "FND-4",
  "round": 2,
  "score": 96,
  "threshold": 80,
  "verdict": "READY",
  "blocking": [],
  "criteria": {"C1": 10, "C2": 16, "C3": 25, "C4": 15, "C5": 10, "C6": 10, "C7": 5, "C8": 5},
  "questions": 1
}
```

## Scores

| # | Criterion | Score | Max | Evidence (quoted from the story) | Gaps |
|---|-----------|-------|-----|----------------------------------|------|
| C1 | Intent and context | 10 | 10 | "As the engineer building ABC Bank's systems, I want a private network in the ABC Bank account that RDS and DMS can run in, so that the core-banking database and change data capture never need to be on the internet." Context quotes `docs/00-roadmap.md` §4 Phase 1 and §6 (verified: roadmap lines "Networking for the ABC Bank account (RDS and DMS) using S3 gateway endpoints instead of a NAT gateway" and "No NAT gateway"). Names ABC-1 and the later DMS story as consumers. | None. |
| C2 | Requirements | 16 | 20 | R1 "private subnets that meet the subnet requirements of RDS and DMS (RDS needs subnets in at least two Availability Zones)"; R2 "only S3 buckets that belong to this AWS organization"; R3 "No internet gateway is ever attached to this VPC, including by later stories"; R3a "default security group has no rules"; R3b "at least 200 free IP addresses after this story"; R3c "default VPC in `us-east-1` is deleted"; R4 "find the VPC and its private subnets by name or tag"; R5 "Any part of it billed by the hour is not created by this story". | (1) R3 "including by later stories" does not say what this story must deliver for it: a preventive control (something that denies attaching an internet gateway to this VPC), or a rule recorded for later stories to honour and check (as ABC-1's AC9 does). The two lead to different designs and tests, and a preventive control may belong in another repo (`aws-foundations`, where FND-1 keeps SCPs out of scope) (-4). |
| C3 | Acceptance criteria | 25 | 25 | R1→AC1, AC4; R2→AC3; R3→AC2, AC3a, AC4; R3a→AC3b; R3b→AC3c; R3c→AC3d; R4→AC7; R5→AC6, AC8, AC8a; tagging→AC5; lint→AC9. Each names a command or a concrete check with a threshold ("at least 200 available IP addresses", "returns no VPC", "no inbound and no outbound rules"). | None that cost points. The round-1 gap ("leave room" had no criterion) is closed by R3b and AC3c. The future-facing part of R3 cannot be tested in this story; that is covered by the C2 question. |
| C4 | Constraints | 15 | 15 | Personal data "Not applicable: no data. The network is the boundary for the personal data stored from ABC-2 on."; PCI "Same as personal data."; Network "No NAT gateway, no internet gateway route from private subnets, no public subnets."; Encryption "Not applicable."; Cost "Persistent and free of hourly charges" with AC6 and AC8a "$0"; Tagging "four cost tags" with AC5; Downstream "leave room for DMS ... and for the engineer access path", made concrete by R3b. | None. Teardown and session cost do not apply: R5 and AC6 rule out hourly-billed resources, and AC8a states the monthly cost as AGENTS.md asks of long-lived roots. |
| C5 | Scope boundaries | 10 | 10 | Out of scope: interface endpoints "and anything else billed by the hour", "The engineer access path to RDS (ABC-1)", other accounts' networking, "VPC flow logs", "A DynamoDB gateway endpoint (nothing in Phase 2 uses DynamoDB)", "Default VPCs in other regions". | None. Both round-1 gaps (DynamoDB endpoint, default VPC) are now explicit. |
| C6 | Dependencies and inputs | 10 | 10 | "FND-1: the ABC Bank account and the administrator and engineering roles." "FND-2: Terraform state storage." | None. Both exist as draft stories (`workspace-stories/FND-1.md`, `workspace-stories/FND-2.md`); `gh issue list -R Lakshmi100/abc-bank --state all` returns no issues yet. The organization ID that R2 and AC3 need comes from FND-1's organization, which is listed. The default VPC that R3c deletes is created by AWS with the account (FND-1); nothing in FND-2, FND-3 or ABC-1 uses it (see "Nice to know" for FND-1's AC5). |
| C7 | Free of design | 5 | 5 | "S3 gateway endpoint" and "no NAT gateway" carry their reason (roadmap FinOps guardrail, "free of hourly charges"). AC3 names `aws:ResourceOrgID`, the mechanism behind R2's stated rule. | None that cost points (see "Design detail to confirm"). |
| C8 | Open questions resolved | 5 | 5 | "Open questions: None." The "Proposed defaults, for the approver to confirm" are scored as the owner's stated requirements (R2, R3a, R3b). | No TBDs or contradictions inside the story. |
| | **Total** | **96** | **100** | | |

## Blocking issues
| # | Issue | Where in the story |
|---|-------|--------------------|
| – | None. B1: no open questions or contradictions; proposed defaults are stated choices. B2: every AC is testable. B3: FND-1 and FND-2 exist as stories. B4: nothing forbidden; it honours "Do not create NAT gateways", and deleting the default VPC is named by the story (R3c). B5: no hourly-billed resources (R5, AC6). B6: no customer, account, card or transaction data. | – |

## Questions for the story owner
Ordered by points recovered, largest first.

| # | Resolves | Question | Why it matters |
|---|----------|----------|----------------|
| Q1 | C2 | For "No internet gateway is ever attached to this VPC, including by later stories" (R3): must this story put a control in place that stops one being attached (and if so, in this repo or in `aws-foundations`), or is it a rule that later stories must follow and check themselves, with this story checking only today's state (AC3a)? | A preventive control is extra design and its own test (an attempt to attach an internet gateway is denied); a recorded rule needs neither. Without an answer the architect and tester guess, and a guardrail could land in a repo this story does not cover. |

## Nice to know
Points that would not change the design, the tests or the delivery. No
points deducted; not counted in "questions".

- **Cross-story, for ABC-1's owner:** ABC-1 AC9 checks that "no NAT gateway or internet gateway exists in the ABC Bank account". FND-4 deletes only the `us-east-1` default VPC and puts "Default VPCs in other regions" out of scope, and every other region's default VPC has an internet gateway. As written, ABC-1 AC9 would fail. ABC-1 should limit that check to `us-east-1` (or to its own resources), unless the owner wants FND-4's scope widened.
- **Effect of R2 on later stories:** an S3 policy limited to the organization's buckets also blocks AWS-owned buckets, for example the Amazon Linux package repositories and SSM Agent updates. Test instances in later stories would not be able to install packages through the endpoint. That is consistent with R2; later stories that need it would have to change the policy.
- **FND-1 AC5** ("creating and deleting a security group in `us-east-1` succeeds") uses the default VPC when no VPC is named. After FND-4 it only works with `--vpc-id`. This matters only if FND-1's checks are re-run.
- **AWS-created defaults:** the VPC's default security group, main route table and default network ACL are made by AWS, not "created" by the story. AGENTS.md says "every AWS resource carries the four cost tags", so the architect should bring them under Terraform and tag them. AC5 should be read that way.
- **AC5 method:** the Resource Groups Tagging API lists only resources that have or once had tags, so an untagged resource does not show up. The test should take the list of resources from Terraform state and check each one.
- **AC7 and AC8** need a Terraform root to run in, and none exists yet. As in FND-2 (AC2, AC8), a throwaway test root created for the check and deleted afterwards would do. The design should say which.
- **How the default VPC is deleted** (in Terraform or as a documented one-off step) is left to the architect. Record it in `infra/README.md`. `aws ec2 create-default-vpc` reverses it.
- The VPC CIDR and subnet sizes are left to the architect. At least 200 free addresses per subnet means /24 or larger, because AWS reserves 5 addresses per subnet. The lookup names or tags (R4) should be recorded in `design.md` so that ABC-1 and the DMS story use the same ones.
- Roadmap §6 still says "S3 and DynamoDB gateway endpoints", and the Phase 1 exit criterion still says "`terraform destroy` removes it cleanly". The story's position is clear, but the roadmap wording could be updated.

## Design detail to confirm
Design choices found in the story. For each, keep it as a constraint (and add
the reason to the story) or remove it and leave it to the architect.

- **S3 gateway endpoint instead of a NAT gateway** (R2, AC3, constraints). Reason stated: roadmap FinOps guardrail and the AGENTS.md boundary. Recommend keeping it.
- **`aws:ResourceOrgID` in AC3**. This is how R2's rule ("only S3 buckets that belong to this AWS organization") is enforced. Other ways include listing account IDs with `aws:ResourceAccount`. Keep it if the organization-wide condition is intended (it covers accounts added later). Otherwise, reword AC3 to check the outcome and leave the mechanism to the architect.
- **"no public subnets"** (constraints). It follows from R3. Keep it.

## Earlier questions
On a re-review: each earlier question and whether the story now answers it.

| # | Round-1 question | Status | Where |
|---|------------------|--------|-------|
| Q1 | Which S3 buckets the private subnets can reach | Answered | R2 "only S3 buckets that belong to this AWS organization"; AC3; Decisions (proposed default) |
| Q2 | May an internet gateway be attached to the VPC, now or later | Answered | R3 "No internet gateway is ever attached to this VPC, including by later stories"; AC3a. Follow-up on how it is enforced: round-2 Q1 |
| Q3 | What "leave room for DMS and the access path" means, and how to check it | Answered | R3b "at least 200 free IP addresses"; AC3c |
| Q4 | DynamoDB gateway endpoint in or out of scope | Answered | Out of scope: "A DynamoDB gateway endpoint (nothing in Phase 2 uses DynamoDB)" |
| Q5 | What happens to the `us-east-1` default VPC | Answered | R3c, AC3d, Decisions "Nov 1, 2026: the default VPC in `us-east-1` is deleted"; other regions out of scope |

Round-1 "nice to know" items also picked up: the default security group (R3a, AC3b) and the tag-check method (AC5).
