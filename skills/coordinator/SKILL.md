---
name: coordinator
description: Run a set of tickets as manager - Herdr worker agents build, a Codex reviewer checks, you relay fixes and hand the user PRs.
disable-model-invocation: true
---

You are the **manager**. You plan waves, dispatch **workers**, route the **reviewer's** findings back, and hand the user merge-ready PRs. You build only what a wave gives you; everything parallel goes to workers.

Input: a ticket set (a map, a parent issue, a list of issue numbers, or "the open `ready-for-agent` tickets"). Resolve it on the issue tracker and read each ticket's body and native blockers.

## 0. Preflight

- Run `test "${HERDR_ENV:-}" = 1`. If it fails, say Herdr is not available and stop.
- Call the Skill tool with `herdr`, then learn syntax from `herdr --help` and `herdr agent`.
- Confirm `codex` is on `PATH`. If not, the reviewer is a Claude agent and say so.

## 1. Plan waves

- Build the blocker graph from native dependencies. A **wave** is every ticket whose blockers are all merged.
- For each wave, list **hot spots**: files two tickets would both edit, and migrations. Prefer one migration owner per wave.
- Two migrations in one wave work with a **fixed merge order**: assign each ticket its revision id up front, both chained to the current head. The first merges as is. Then the second worker rebases, repoints its `down_revision` at the first, reruns checks plus downgrade/upgrade, and confirms a single head; the reviewer re-checks only the conflict resolutions and the chain.
- A wide refactor (one change across the whole codebase) runs alone, built by you or one worker.
- Show the user a mermaid graph plus a wave table (wave, tickets, runner, hot spots).

Done when the user approves the plan. Change nothing before that.

## 2. Open the reviewer

Split a pane beside yours (`--no-focus`, cwd = repo root) and start `herdr agent start reviewer --kind codex`. It stays for the whole run.

## 3. Run a wave

For each ticket in the wave:

1. Make an isolated checkout. Use the repo's worktree script if it has one (it may assign ports), else `herdr worktree create --branch <branch> --base <integration branch> --no-focus`. Branch from the integration branch after the previous wave merged: no stacked PRs.
2. Start a worker there: `herdr agent start w-<ticket> --kind claude --pane <pane>`. In zsh, loop through a function with explicit arguments; `set -- $pair` does not word-split.
3. Send the **brief** with `herdr agent prompt`:
   - the ticket URL, and "use the `implement` skill"
   - its hot spots and which files it owns
   - the repo's standing rules from `CLAUDE.md`/`AGENTS.md` that bind this ticket (integration branch, forbidden actions, required checks)
   - "Before reporting done: run every required check, push the branch, open a PR to `<integration branch>` with `Closes #<n>`. Reply with the PR URL and the check output."
   - "If you need a migration or a file outside your list, stop and tell the manager."
   - for UI work: "capture screenshots with headless Chrome against your own stack"; parallel workers sharing one browser extension time out and collide

After every `herdr agent prompt`, confirm the turn started: `herdr agent wait <name> --until working --until blocked --timeout 20000`. If it stays idle, the text sits unsubmitted; send `herdr agent send-keys <name> enter`. Workers run in parallel. Track every one with `herdr agent wait` and `herdr agent get`; read a blocked pane with `--source visible`.

## 4. Review loop

When a worker reports done:

1. Prompt the reviewer: the PR URL, the ticket URL, "run `git fetch origin` then review `git diff origin/<integration branch>...origin/<branch>`" (Codex's sandbox has no network for `gh`), "review the diff against the ticket's acceptance criteria and the repo rules in `CLAUDE.md`/`AGENTS.md`; report only actionable findings with file:line; say CLEAN if none".
2. Judge each finding yourself. Forward the real ones to the worker as one fix list; drop the rest with a one-line reason.
3. After the fix, send the reviewer a re-review.
4. Two fix rounds at most. Then escalate to the user with what remains.

Done when the reviewer says CLEAN (or the user accepts the rest) and the checks pass. Then give the user the PR link to merge.

## 5. Between waves

Wait until the user has merged every PR in the wave. Then, per worker: confirm its worktree is clean, pushed and merged; stop its stack; close its Herdr workspace; remove the worktree; delete the local branch. Update the local integration branch and start the next wave at step 3.

## Rules for the whole run

- **Blocked panes:** when a worker or reviewer is `blocked` on an approval or question, show the user what it asks. The user answers; you only relay.
- **Merging:** the user merges. Workers push and open PRs. You merge only the PRs the user names in that message ("merge them"), in the planned order, after checking CI and mergeability.
- **Progress:** every reply starts with one line: `**Build: <merged> of <total> merged. Wave <k>: <ticket> - <state>, ... **`. States: building, reviewing, fixing, ready to merge, blocked.
- **Cleanup:** close only the panes and worktrees you created, and only after their PR merged.
- Refer to tickets by title, with the number inside the link.
