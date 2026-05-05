---
allowed-tools: Bash(gh:*), Bash(git:*), Read, Edit, Glob, Grep
argument-hint: [pr-number]
description: Address PR review comments and update the branch
---

## Address PR Comments Command

Fetch PR comments. Help address review feedback.

Current branch:
!`git branch --show-current`

Current status:
!`git status --short`

## Your task

Address comments on PR: $ARGUMENTS

Steps:

1. Fetch PR details + comments (omit PR number → use current branch PR):
   - `gh pr view` for PR summary
   - `gh pr view --comments` for review comments
2. Summarize feedback:
   - List each actionable comment with file/line context
   - Separate actionable items from questions/approvals
3. For each actionable comment:
   - Read relevant file(s)
   - Make requested changes
   - Explain what changed
4. After all changes:
   - Stage + commit with message "Address PR feedback"
   - **Never use `--no-verify`** — let pre-commit hooks run
   - Push to branch
5. Suggest responses for discussion points