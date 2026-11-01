# Story drafts

Stories are drafted here, reviewed by the SDLC Factory's story reviewer, and
then opened as GitHub Issues with the `needs-approval` label. **Once a story
is an issue, the issue is the source of truth**; the draft and its reviews
stay here as history.

Draft IDs are temporary. The real key comes from the issue number in the
story's repo (GitHub numbers issues and pull requests together), so a draft
ID can differ from, or even collide with, a real key.

## Opened as issues (Nov 1, 2026)

| Draft ID | Story key | Issue | Title | Final readiness |
|---|---|---|---|---|
| FND-1 | FND-3 | [Lakshmi100/aws-foundations#3](https://github.com/Lakshmi100/aws-foundations/issues/3) | AWS organization, accounts and Identity Center access | 87 READY |
| FND-5 | FND-4 | [Lakshmi100/aws-foundations#4](https://github.com/Lakshmi100/aws-foundations/issues/4) | Cost and audit guardrails for the organization | 95 READY |
| FND-2 | ABC-3 | [Lakshmi100/abc-bank#3](https://github.com/Lakshmi100/abc-bank/issues/3) | Terraform state storage for the ABC Bank account | 96 READY |
| FND-3 | ABC-4 | [Lakshmi100/abc-bank#4](https://github.com/Lakshmi100/abc-bank/issues/4) | Customer-managed KMS key for ABC Bank data | 88 READY |
| FND-4 | ABC-5 | [Lakshmi100/abc-bank#5](https://github.com/Lakshmi100/abc-bank/issues/5) | Private network for the ABC Bank account | 96 READY |
| ABC-1 | ABC-6 | [Lakshmi100/abc-bank#6](https://github.com/Lakshmi100/abc-bank/issues/6) | Core-banking Postgres database in the ABC Bank account | 97 READY |

Each draft's reviews are `<draft ID>.story-review.md` (latest) and
`<draft ID>.story-review.roundN.md` (earlier rounds). The final fixes after
the last review round were small and were not re-reviewed.

## Still drafts

- `phase-2-core-banking-stories-DRAFT.md`: the remaining Phase 2 stories
  (customers table, transactions table, data generator, SF10 load), in the
  old format. To be rewritten one file per story and reviewed before they
  become issues.
