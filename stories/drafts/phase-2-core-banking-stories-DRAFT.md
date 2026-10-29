# Phase 2 Stories (DRAFT, pending approval)

**Milestone:** Phase 2: ABC Bank source (core banking on RDS Postgres)
**Repo:** `abc-bank`
**Status:** Draft. Each story becomes a GitHub Issue in `abc-bank` (Story template, label `needs-approval`) only after the approver signs off on it.
**Approver (every story):** Lakshmi100
**Default labels:** `abc-bank`, plus the work type and exam domain listed per story

Every story that creates hourly-billed resources ends with a teardown check (roadmap §6).

---

## ABC-1: Provision the core-banking RDS Postgres instance with Terraform

**Type:** Story · **Labels:** `infra`, `finops`, `dea-domain-2` · **Estimate:** 5 pts (~6 h)
**Depends on:** Phase 1 foundations (ABC Bank account, VPC, KMS keys, Terraform state)

**As** the ABC Bank data owner, **I want** a Postgres database in the ABC Bank AWS account, built from Terraform, **so that** the bank's core-banking data has a home that DMS can later read changes from.

**Scope**
- Terraform module in `infra/` for RDS Postgres (single-AZ, small burstable instance, e.g. `db.t4g.micro`/`small`) in private subnets, us-east-1
- Storage encrypted with the ABC Bank customer-managed KMS key
- Parameter group ready for CDC now, so DMS doesn't force a rebuild later: `rds.logical_replication = 1`
- Master password managed by Secrets Manager (`manage_master_user_password`), no password in code or state outputs
- Access from your workstation via SSM port forwarding or a temporary allow-listed IP, no public endpoint left open
- Mandatory tags: `data-product`, `environment`, `owner`, `cost-center`

**Acceptance criteria**
- [ ] `terraform apply` creates the instance; `terraform destroy` removes it cleanly (no leftover snapshots unless intended)
- [ ] You can connect with `psql` and create a database `core_banking`
- [ ] `SHOW rds.logical_replication;` returns `on`
- [ ] Encryption shows the customer-managed key, not the AWS-managed one
- [ ] All resources carry the four cost tags
- [ ] **Teardown check:** instance destroyed at session end; cost of the session noted

---

## ABC-2: Create the `customers` table

**Type:** Story · **Labels:** `pipeline`, `dea-domain-2` · **Estimate:** 3 pts (~3 h)
**Depends on:** ABC-1

**As** the platform team, **I want** a customers table that looks like a real bank's, **so that** the platform has realistic personal data to tokenize and track over time (Type 2 history downstream).

**Proposed columns** *(for review)*
| Column | Type | Notes |
|---|---|---|
| `customer_id` | `bigint` PK (identity) | Primary key is required for DMS CDC updates/deletes |
| `first_name`, `last_name` | `text` | PII |
| `email`, `phone` | `text` | PII |
| `date_of_birth` | `date` | PII |
| `ssn_last4` | `char(4)` | PII; no full SSN stored even synthetically |
| `address_line1`, `city`, `state`, `postal_code` | `text` | PII; changes drive Type 2 history |
| `income_band` | `text` (check constraint) | Changes drive Type 2 history |
| `persona` | `text` | Which of the 20 personas generated this customer |
| `customer_since` | `date` | |
| `status` | `text` (`active`/`closed`) | |
| `created_at`, `updated_at` | `timestamptz` | `updated_at` maintained by trigger |

**Scope**
- Migration file in `core-banking/migrations/` (plain SQL, numbered; tool choice to confirm: plain SQL vs. Flyway vs. Alembic)
- A short data dictionary in `docs/` marking which columns are PII

**Acceptance criteria**
- [ ] Migration runs on an empty database and can be re-run safely
- [ ] Every PII column is flagged in the data dictionary
- [ ] Updating a row changes `updated_at` automatically
- [ ] Table has a primary key (DMS prerequisite)

---

## ABC-3: Create the `transactions` table

**Type:** Story · **Labels:** `pipeline`, `dea-domain-2` · **Estimate:** 5 pts (~5 h)
**Depends on:** ABC-2

**As** the platform team, **I want** a card transactions table linked to customers, **so that** the platform can profile spend and later match purchases to offers.

**Proposed columns** *(for review)*
| Column | Type | Notes |
|---|---|---|
| `transaction_id` | `bigint` PK | |
| `customer_id` | `bigint` FK → `customers` | |
| `card_last4` | `char(4)` | Full card number never stored (PCI) |
| `merchant_name` | `text` | Becomes FK to `merchants` in a later story |
| `merchant_category` | `text` | MCC-style category |
| `amount` | `numeric(12,2)` | Never float, so settlement reconciles to the cent |
| `currency` | `char(3)` default `USD` | |
| `transaction_ts` | `timestamptz` | |
| `posted_date` | `date` | Lets us simulate late-arriving transactions (7-day restatement) |
| `channel` | `text` (`in_store`/`online`) | |
| `status` | `text` (`posted`/`reversed`) | |
| `created_at`, `updated_at` | `timestamptz` | |

**Scope**
- Migration in `core-banking/migrations/`
- Indexes on `customer_id` and `transaction_ts`
- Decision recorded on monthly range partitioning by `transaction_ts` (needed around SF5000 / ~200M rows a month; may be overkill for SF10)

**Acceptance criteria**
- [ ] Insert with an unknown `customer_id` is rejected
- [ ] `amount` is `numeric`, and a negative/zero amount is rejected unless `status = reversed`
- [ ] Partitioning decision written down (short ADR or note in the story)
- [ ] Table has a primary key (DMS prerequisite)

---

## ABC-4: Scale-factor generator for customers and transactions

**Type:** Story · **Labels:** `pipeline`, `dea-domain-1` · **Estimate:** 8 pts (~8 h)
**Depends on:** ABC-2, ABC-3

**As** the platform team, **I want** a synthetic data generator driven by a scale factor, **so that** we can load small data for development and large data for the scale test with the same code.

**Scope**
- Python generator in `data-generator/`, reusing the 20 personas from v2
- SF1 = 1,000 customers and ~1.6M transactions over 24 months; volume scales linearly
- Deterministic with a seed, so runs are repeatable
- Writes CSV and bulk-loads with `COPY` (not row-by-row inserts)
- Optionally emits a small "late" batch (posted 1–7 days after `transaction_ts`)

**Acceptance criteria**
- [ ] `--scale-factor 1 --seed 42` produces the same output twice
- [ ] SF1 row counts within ±5% of 1,000 customers / 1.6M transactions
- [ ] Every transaction references an existing customer
- [ ] Spend by category per persona looks plausible (quick summary printed after a run)
- [ ] Unit tests for the scale math and persona assignment

---

## ABC-5: Load and validate SF10 in RDS

**Type:** Story · **Labels:** `pipeline`, `finops`, `dea-domain-3` · **Estimate:** 3 pts (~3 h)
**Depends on:** ABC-1 to ABC-4

**As** the platform team, **I want** SF10 data loaded and checked in RDS, **so that** Phase 2's DMS work starts from a known-good source.

**Scope**
- Load SF10 (~10,000 customers, ~16M transactions) with the generator
- A validation SQL script in `core-banking/checks/`: row counts, orphan check, null checks on required columns, date range, amount totals by month
- Record load time, database size, and session cost

**Acceptance criteria**
- [ ] Validation script passes with zero orphans and zero unexpected nulls
- [ ] Load time, size on disk, and cost written in the story's comments
- [ ] A manual customer update (e.g. address change) works and bumps `updated_at`, ready for the DMS CDC story
- [ ] **Teardown check:** instance destroyed after validation; cost recorded

---

## Open questions for the approver
1. ~~Jira vs. GitHub Issues~~ **Decided Oct 28: GitHub Issues.**
2. **Transactions → cards/accounts.** The roadmap schema has customers, accounts, cards, merchants, transactions. This draft links transactions directly to customers and keeps merchant as text, so the first two tables stand alone. OK to add `accounts`/`cards`/`merchants` as follow-up stories?
3. **Migration tool:** plain numbered SQL, Flyway, or Alembic?
4. **Partitioning** of `transactions`: decide now or defer to the Phase 6 scale test?
