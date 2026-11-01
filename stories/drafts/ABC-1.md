# ABC-1: Core-banking Postgres database in the ABC Bank account

**Repo:** `abc-bank` · **Milestone:** Phase 2: ABC Bank source · **Estimate:** 5 pts
**Labels:** `story`, `needs-approval`, `infra`, `finops`, `abc-bank`, `dea-domain-2`
**Approver:** Lakshmi100 · **Status:** draft, not yet an issue

## User story

**As** the ABC Bank data owner,
**I want** a Postgres database for core banking in the ABC Bank AWS account, built from code,
**so that** the bank's customer and transaction data has a home that the Offers Platform can later receive changes from through DMS.

## Context

The roadmap's source-system decision is "ABC Bank core banking on RDS Postgres;
change data capture with DMS" (`docs/00-roadmap.md` §1 and Phase 2 in §4).
This is the first Phase 2 story; ABC-2 to ABC-5 (tables, generator, data load)
build on it. The database is a development environment for a portfolio build,
not production.

## Requirements

1. A managed PostgreSQL database (Amazon RDS) exists in the ABC Bank account,
   in `us-east-1`, defined entirely in Terraform under `infra/`.
2. It contains an empty database named `core_banking`.
3. It is ready for DMS change data capture (inserts, updates and deletes) from
   the start, so that adding CDC later does not require rebuilding it.
4. An engineer can connect to it with `psql` from their laptop for development,
   while the database is never reachable from the internet.
5. One command creates everything this story needs, and one command removes it.
6. It is sized for development and for loading scale factor 10 (about 10,000
   customers and 16 million transactions, a few GB), not for production load.
7. The admin password is generated and stored by AWS. It never appears in the
   repo, in Terraform outputs, or in plan output.

## Constraints

| Area | Constraint |
|---|---|
| Personal data | No data in this story. From ABC-2 on the database holds (synthetic) personal data, so encryption and access rules apply from creation. |
| Card data (PCI) | Not applicable: no tables or data in this story. |
| Network and access | No public endpoint. Access through IAM Identity Center–based roles only; no IAM users, no long-lived access keys, no SSH keys, no NAT gateway. |
| Encryption | Storage and backups encrypted with the ABC Bank customer-managed KMS key. |
| Cost | Billed by the hour, so it is created per working session and destroyed after. A 3-hour session, including any access path, costs under $1. |
| Tagging | Every resource carries `data-product`, `environment`, `owner`, `cost-center`. |
| Downstream compatibility | Must meet AWS DMS's prerequisites for a PostgreSQL CDC source (supported engine version, logical replication). |

## Acceptance criteria

- [ ] **AC1** In an ABC Bank account that has the Phase 1 foundations, `terraform apply` in the ABC Bank Terraform root completes without errors.
- [ ] **AC2** After apply, an engineer on their laptop connects with `psql` to `core_banking` and `select version();` returns a PostgreSQL version that AWS DMS supports as a CDC source.
- [ ] **AC3** `SHOW wal_level;` returns `logical`.
- [ ] **AC4** `aws rds describe-db-instances` shows `PubliclyAccessible: false`, and no security group attached to the database allows inbound traffic from `0.0.0.0/0` or `::/0`.
- [ ] **AC5** `aws rds describe-db-instances` shows storage encrypted with the ABC Bank customer-managed KMS key, not the AWS-managed `aws/rds` key.
- [ ] **AC6** Searching the repo, `terraform output`, and the saved plan output for the admin password finds nothing.
- [ ] **AC7** Every resource the story creates has all four cost tags with non-empty values (checked with the Resource Groups Tagging API).
- [ ] **AC8** `terraform destroy` completes without errors. Afterwards, no RDS instance, RDS snapshot or EC2 instance with this story's tags remains.
- [ ] **AC9** The PR records the session's cost (from Cost Explorer by tag, or an estimate if the data is not available yet) and it is under $1.
- [ ] **AC10** `terraform fmt -check` and `terraform validate` pass.

## Out of scope

- Tables and schema (ABC-2, ABC-3); the data generator and data loading (ABC-4, ABC-5)
- DMS endpoints and tasks (a later Phase 2 story)
- High availability (Multi-AZ), read replicas, backup tuning, production sizing
- Deploying from GitHub Actions
- The Phase 1 foundations themselves (VPC, KMS key, Terraform remote state, Identity Center)

## Depends on

- FND-1: the ABC Bank account, and the Identity Center administrator and engineering roles.
- FND-2: Terraform state storage for the ABC Bank account.
- FND-3: the ABC Bank customer-managed KMS key (looked up by alias).
- FND-4: the private network (VPC and private subnets, looked up by name or tag).
- FND-5: cost-allocation tags activated, so AC9 can read the session's cost by tag.

The FND resources persist between sessions. ABC-1's Terraform is separate from
them: its `terraform destroy` removes only what ABC-1 creates.

## Open questions

None.
