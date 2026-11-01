# FND-4: Private network for the ABC Bank account

**Repo:** `abc-bank` (`infra/`) · **Milestone:** Phase 1: Foundations · **Estimate:** 3 pts
**Labels:** `story`, `needs-approval`, `infra`, `finops`, `abc-bank`, `dea-domain-4`
**Approver:** Lakshmi100 · **Status:** draft, not yet an issue (draft ID; the real key comes from the issue number)

## User story

**As** the engineer building ABC Bank's systems,
**I want** a private network in the ABC Bank account that RDS and DMS can run in,
**so that** the core-banking database and change data capture never need to be on the internet.

## Context

Roadmap: "Networking for the ABC Bank account (RDS and DMS) using S3 gateway endpoints instead of a NAT gateway", and the FinOps guardrail "No NAT gateway" (`docs/00-roadmap.md` §4 Phase 1 and §6). ABC-1 places the database in this network; a later Phase 2 story places DMS in it.

## Requirements

1. A VPC exists in the ABC Bank account in `us-east-1`, with private subnets that meet the subnet requirements of RDS and DMS (RDS needs subnets in at least two Availability Zones).
2. Resources in the private subnets can reach Amazon S3 without going through the internet.
3. Nothing in the private subnets can be reached from the internet, and nothing in them can reach the internet.
4. Other `abc-bank` Terraform roots can find the VPC and its private subnets by name or tag, without hard-coding IDs.
5. The network persists between sessions. Any part of it billed by the hour is not created by this story; stories that need such parts (for example, ABC-1's engineer access path) create and destroy them per session.

## Constraints

| Area | Constraint |
|---|---|
| Personal data | Not applicable: no data. The network is the boundary for the personal data stored from ABC-2 on. |
| Card data (PCI) | Same as personal data. |
| Network and access | No NAT gateway, no internet gateway route from private subnets, no public subnets. |
| Encryption | Not applicable. |
| Cost | Persistent and free of hourly charges: VPC, subnets, route tables, S3 gateway endpoint. |
| Tagging | Every resource carries the four cost tags. |
| Downstream compatibility | The design must leave room for DMS in the same private subnets and for the engineer access path in ABC-1. |

## Acceptance criteria

- [ ] **AC1** `aws ec2 describe-subnets` shows at least two private subnets in the VPC, in at least two different Availability Zones.
- [ ] **AC2** No route table associated with the VPC's subnets has a route to an internet gateway or a NAT gateway; `aws ec2 describe-nat-gateways` for the VPC returns none.
- [ ] **AC3** An S3 gateway endpoint is attached to the private subnets' route tables.
- [ ] **AC4** No subnet in the VPC has `MapPublicIpOnLaunch: true`.
- [ ] **AC5** Every resource the story creates has the four cost tags with non-empty values.
- [ ] **AC6** None of the resources this story creates appears in AWS pricing as billed by the hour (the PR lists each resource type and its pricing).
- [ ] **AC7** A Terraform root that looks up the VPC and private subnets by name or tag plans without errors.
- [ ] **AC8** Running `terraform destroy` in another `abc-bank` root leaves the VPC, subnets and endpoint in place.
- [ ] **AC9** `terraform fmt -check` and `terraform validate` pass.

## Out of scope

- Interface VPC endpoints (e.g. for Systems Manager) and anything else billed by the hour
- The engineer access path to RDS (ABC-1)
- Networking in the Offers Platform or management accounts
- VPC flow logs

## Depends on

- FND-1: the ABC Bank account and the administrator and engineering roles.
- FND-2: Terraform state storage.

## Open questions

None.
