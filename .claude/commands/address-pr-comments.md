---
allowed-tools: Bash(gh:*), Bash(git:*), Read, Edit, Glob, Grep
argument-hint: [pr-number]
description: Address PR review comments and update the branch
---

## Address PR Comments Command

Fetch PR comments and help address review feedback.

Current branch:
!`git branch --show-current`

Current status:
!`git status --short`

## Your task

Address comments on PR: $ARGUMENTS

Steps:

1. Fetch PR details and comments (omit PR number to use current branch's PR):
   - `gh pr view` for PR summary
   - `gh pr view --comments` for review comments
2. Summarize the feedback:
   - List each actionable comment with file/line context
   - Separate actionable items from questions/approvals
3. For each actionable comment:
   - Read the relevant file(s)
   - Make the requested changes
   - Explain what you changed
4. After all changes:
   - Stage and commit with message "Address PR feedback"
   - **Never use `--no-verify`** - let pre-commit hooks run
   - Push to the branch
5. Suggest responses for any discussion points
