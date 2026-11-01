# Story review: FND-1 AWS organization, accounts and Identity Center access

Round 2 · 2026-11-01

## Gate

The orchestrator reads this block. Keep it valid JSON and keep the keys exactly.

```json
{
  "key": "FND-1",
  "round": 2,
  "score": 63,
  "threshold": 80,
  "verdict": "NEEDS_INFO",
  "blocking": ["B1"],
  "criteria": {"C1": 10, "C2": 8, "C3": 13, "C4": 12, "C5": 10, "C6": 5, "C7": 5, "C8": 0},
  "questions": 8
}
```

## Scores

| # | Criterion | Score | Max | Evidence (quoted from the story) | Gaps |
|---|-----------|-------|-----|----------------------------------|------|
| C1 | Intent and context | 10 | 10 | "As the engineer building the Offers Platform, I want the three AWS accounts in one organization, with sign-in through IAM Identity Center and no IAM users anywhere, so that every later story has an account to build in…"; Context cites `docs/00-roadmap.md` §1 and §4 and explains the Offers Platform account's IAM users today; source line names the draft. | None. |
| C2 | Requirements | 8 | 20 | Req 1 "all features enabled (required by Identity Center and by FND-5's organization trail)"; Req 3 "MFA is required at every sign-in"; Req 4 engineering role "can: run Terraform for session roots: RDS, EC2 (instances, security groups, network interfaces, interface endpoints), DMS, Secrets Manager, CloudWatch Logs, and creating IAM roles for AWS services, with `iam:PassRole` only for roles it created; … It cannot change the organization, billing, Identity Center, IAM users or access keys"; Req 5 "laptop tools use Identity Center CLI profiles (`aws sso login`)"; Req 4 Offers Platform gets only "an administrator role … used for setup and for applying long-lived foundations"; Least privilege row "administrator roles are for setup only". | (a) Offers Platform day-to-day access is undefined: Req 5 moves laptop tools (Terraform, Airflow, Spark) in that account to Identity Center profiles, but the only permission set there is the administrator role, which is "for setup only". Which permission set the replacement profiles use, and what it may do, is not stated (−4). (b) "Creating IAM roles for AWS services": no rule for what permissions those roles may carry, or whether the role may also update and delete them and create instance profiles. Without a limit, the engineering role can create a role with full permissions, pass it to an EC2 instance it launches, and so bypass "cannot change … IAM users or access keys" (−4). (c) The listed actions do not cover what the role's stated users need: Req 4 includes EC2 instances and interface endpoints (ABC-1's private access path) but not starting a Session Manager session; ABC-1's checks also read the Resource Groups Tagging API and `iam list-users`. Because the role is "exactly those in requirement 4", the architect must guess whether these are in (−4). |
| C3 | Acceptance criteria | 13 | 25 | AC1–AC14. AC5 "creating and deleting a security group in `us-east-1` succeeds, and `aws ce get-cost-and-usage` … succeeds"; AC6 "`aws organizations list-accounts` is denied, and `aws iam simulate-principal-policy` shows `iam:CreateUser`, `iam:CreateAccessKey`, `kms:ScheduleKeyDeletion` and `kms:PutKeyPolicy` as denied"; Out of scope "until then each story's criteria check tags". | All criteria are pass/fail with concrete commands; AC3 and AC11 use MANUAL lines as `AGENTS.md` allows. (a) Req 4 allowed capabilities have no criterion apart from security groups and Cost Explorer: nothing checks RDS, DMS, Secrets Manager, CloudWatch Logs, IAM role creation, KMS use, state bucket access, `rds-db:connect`, or that `iam:PassRole` is limited to roles the engineering role created (−4). (b) Req 4 "cannot change the organization, billing, Identity Center": `organizations list-accounts` is denied from a member account for every role whatever its policy, so AC6 does not test the role, and no billing or Identity Center action is checked (−4). (c) Tagging constraint has no criterion, although the story's own Out of scope says each story's criteria check tags (−4). |
| C4 | Constraints | 12 | 15 | Constraints table covers access and lock-out (Req 6, AC11), least privilege, no IAM users or keys, cost "under $0.50 per month", tagging, audit "No organization trail yet (FND-5). Trusted access for CloudTrail is enabled here", effect on member accounts (billing, default SCP, IAM users, `OrganizationAccountAccessRole`), region. | Every `AGENTS.md` checklist item is addressed. (a) Personal data is not addressed: the Identity Center user's name and email and the account email addresses end up in Terraform state in the management account's bucket; the story does not say who may read that state or whether the bucket requires encryption and TLS (as FND-2 does), or that this is not applicable (−3). |
| C5 | Scope boundaries | 10 | 10 | Out of scope: OUs and non-default SCPs; tag policy ("a later `aws-foundations` story"); FND-5 guardrails; member-account state (FND-2, later); GitHub Actions OIDC roles; v1/v2 pipeline changes beyond credentials. | None. Round 1's tag-policy and OU/SCP gaps are closed. |
| C6 | Dependencies and inputs | 5 | 10 | "Depends on: None in other stories. The manual steps in requirement 8 are part of this story and done by the owner."; Context "nothing exists yet except the Offers Platform account". | The Offers Platform account is stated as existing (story Context and roadmap §1 "existing account"); not checkable from the review, accepted on the owner's statement. The management account is now created by this story. (a) Implied, not listed: AC5 needs Cost Explorer enabled for the organization, which FND-5 Req 8 claims as its own manual step ("enabling Cost Explorer for the first time"). Either FND-1 depends on FND-5 or FND-1 must enable it (−5). |
| C7 | Free of design | 5 | 5 | "all features (required by Identity Center and by FND-5's organization trail)"; "stored in S3 … with locking and version history, created by a documented bootstrap step"; "`OrganizationAccountAccessRole`"; "Identity Center CLI profiles (`aws sso login`)". | Design details carry reasons (roadmap §1, FND-5, recovery path referenced by FND-2 and FND-3). Policy structure, groups vs direct assignment and lock mechanism are left to the architect. No deduction. |
| C8 | Open questions resolved | 0 | 5 | "Open questions: None." | Contradiction: Least privilege row "administrator roles are for setup only" vs Req 5, which moves day-to-day laptop tools in the Offers Platform account to Identity Center profiles where only an administrator role exists (Req 4). Also "Depends on: None in other stories" vs AC5 needing Cost Explorer, which FND-5 enables (−5). |
| | **Total** | **63** | **100** | | |

## Blocking issues
| # | Issue | Where in the story |
|---|-------|--------------------|
| B1 | Contradiction: day-to-day laptop tools in the Offers Platform account must use Identity Center profiles, but the only permission set there is the administrator role, which is "for setup only". | Req 4, Req 5, Constraints "Least privilege" |

B5 is met (access checked by AC3, AC4, AC10, AC11; recovery in Req 6). B6 is met (state bucket "under $0.50 per month").

## Questions for the story owner
Ordered by points recovered, largest first.

| # | Resolves | Question | Why it matters |
|---|----------|----------|----------------|
| Q1 | C8, C2, B1 | In the Offers Platform account, which Identity Center permission set do the replacement CLI profiles for Terraform, Airflow and Spark use: a new day-to-day role (and if so, what may it do), or the administrator role (and then the Least privilege row must allow that)? | AC8's "replacement profile" has no defined permissions; the architect would invent a permission set or break the least-privilege rule. |
| Q2 | C6, C8 | AC5 needs Cost Explorer enabled, which FND-5 lists as its manual step: does FND-1 enable Cost Explorer itself (adding it to Req 8's manual steps), or does FND-1 depend on FND-5 and AC5 run only after it? | Decides story order and whether `tests/FND-1.sh` AC5 can pass when FND-1 is done. |
| Q3 | C2 | What limit applies to IAM roles the engineering role creates (for example: they may not allow IAM user or access-key actions, or must carry a permissions boundary), may the engineering role also update and delete those roles and create instance profiles, or is the escalation risk accepted? | Without a limit the engineering role can grant itself anything in the ABC Bank account through a role it creates, defeating "cannot change … IAM users or access keys". |
| Q4 | C2 | Must the engineering role also be able to start Session Manager sessions (for ABC-1's access path), read the Resource Groups Tagging API and read IAM (`iam list-users`) for ABC-1's checks, or does ABC-1 use another path and role for these? | The role is "exactly" Req 4's list; ABC-1 fails if these are missing, and adding them unasked breaks the rule. |
| Q5 | C3 | Which criterion proves the engineering role's allowed actions (RDS, DMS, Secrets Manager, CloudWatch Logs, IAM role creation, KMS use, state bucket, `rds-db:connect`) and the `iam:PassRole` limit: a list of `simulate-principal-policy` actions here, or are some left to FND-2, FND-3 and ABC-1? | The tester otherwise picks the actions; the PassRole limit is the key least-privilege rule and has no check. |
| Q6 | C3 | Which billing and Identity Center actions must be shown denied for the engineering role (for example by `simulate-principal-policy`), given that `organizations list-accounts` is denied from any member-account role regardless of policy? | AC6 currently cannot fail, so it does not prove "cannot change the organization, billing, Identity Center". |
| Q7 | C3 | Which resources in this story must carry the four cost tags (state bucket, any lock store, the ABC Bank account, permission sets…), and should an acceptance criterion check them? | The Out of scope line says each story's criteria check tags; FND-1 has none. |
| Q8 | C4 | Is personal data in Terraform state (Identity Center user name and email, account emails) a concern: who may read the management state bucket, and must it require encryption and TLS like FND-2, or is this not applicable? | Changes the bucket policy and adds checks; `AGENTS.md` keeps these values out of git but they still land in state. |

## Nice to know
- AC5 creates a security group in `us-east-1`; FND-4 deletes the ABC Bank default VPC, so re-running `tests/FND-1.sh` after FND-4 needs a VPC to target.
- Allowed MFA types and what happens for a user with no registered MFA device are not stated; defaults are fine for one user.
- Enabling the Identity Center organization instance and its MFA setting may be console-only; Req 8's rule ("steps AWS only allows by hand") covers them, but its list names only two steps, so the README should list whatever proves manual.
- No criterion that the PR states the state bucket's monthly cost (FND-2 to FND-5 have one); the $0.50 figure already meets B6.
- Member-account root users (ABC Bank, Offers Platform): MFA and passwords are not mentioned; AC7 covers their access keys only if the credential report is read in each account, which "including for the management account's root user" leaves unclear.
- What to do if something breaks during the one-session key deactivation (reactivate and fix) is not stated; it is the obvious response.
- The engineering role's policy refers to the state bucket and KMS key that FND-2 and FND-3 create later; how they are identified (name or alias convention, or the resource policies in FND-2 and FND-3) is for the architect.
- AC12 says "`aws-foundations` state is in the management account's bucket"; naming the bootstrap root explicitly would tie it to Req 9's last sentence.
- `AGENTS.md` requires the first story to add the `Makefile` (`make test`, `make lint`) and `tests/FND-1.sh`; the story need not repeat it.
- Session duration for the roles is not stated; defaults are fine.
- `gh issue list -R Lakshmi100/aws-foundations --state all` returns no issues, as expected for a draft.

## Design detail to confirm
- `OrganizationAccountAccessRole` created in the invited Offers Platform account: keep as a constraint (AWS's name for the role, used by the recovery path and referenced by FND-2 and FND-3).
- S3 state with locking, version history and a bootstrap whose state moves into the bucket: keep (roadmap §1, same pattern as FND-2).
- Identity Center CLI profiles via `aws sso login` as the replacement for laptop keys: keep (roadmap "human access through IAM Identity Center only").

## Earlier questions
| # | Round 1 question (short) | Status |
|---|--------------------------|--------|
| Q1 | Offers Platform IAM users: remove, replace or leave? | Answered: replaced and removed (Req 5, Context, Decisions). |
| Q2 | How the owner accepts the invitation | Answered: manual step from inside the Offers Platform account, in `README.md` (Req 8). |
| Q3 | Recovery path | Answered: management root with MFA; `OrganizationAccountAccessRole` in both member accounts (Req 6, AC10, AC11). |
| Q4 | Monthly cost of state bucket | Answered: under $0.50 per month (Constraints "Cost"). |
| Q5 | Which calls AC6 must show denied | Partly answered: IAM and KMS actions named; billing and Identity Center still unchecked (new Q6). |
| Q6 | MFA mode, MFA types, manual AC3 | Answered: every sign-in, AC3 MANUAL. MFA types not stated (now under Nice to know). |
| Q7 | Engineering role's exact actions | Mostly answered (Req 4 list); remaining gaps are new Q3 and Q4. |
| Q8 | All features or consolidated billing only | Answered: all features (Req 1, AC1). |
| Q9 | Tag values and a tag criterion | Values answered (`AGENTS.md` coding standards); criterion still missing (new Q7). |
| Q10 | Effect on CloudTrail trail | Answered: no trail until FND-5; trusted access enabled (Req 7, AC9). |
| Q11 | Effect on the Offers Platform account when it joins | Answered (Constraints "Effect on member accounts"). |
| Q12 | Who owns the tag policy | Answered: a later `aws-foundations` story; out of scope here. |
| Q13 | OUs and SCPs in or out | Answered: out of scope except AWS's default SCP. |
| Q14 | Management account sign-up: prerequisite or story step | Answered: manual step in this story (Req 8, Depends on). |
| Q15 | Confirm the accounts exist | Answered by the owner's statement: management account is created here; Offers Platform account exists (Context, roadmap §1). Not checkable from the review. |
