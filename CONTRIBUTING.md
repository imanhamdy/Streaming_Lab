Contributing to Streaming_Lab

Thank you for contributing! This document describes the preferred workflow, branch naming, commit message conventions, and PR checklist to keep collaboration smooth.

## Branching

- Base branches: `develop` (integration) and `main` (production). Both are protected.
- Short-lived branches only:
  - Features: `feature/<short-desc>`
  - Bugfixes: `bugfix/<short-desc>`
  - Hotfixes (from `main`): `hotfix/<short-desc>`

Create branches from `develop` and open PRs into `develop`.

## Commit messages

Use Conventional Commit style:

```
<type>(<scope>): <short description>

Optional longer description.
```

Common types: `feat`, `fix`, `docs`, `chore`, `ci`, `refactor`.

## Pull Request process

1. Rebase on `develop` or merge `develop` into your branch before opening a PR.
2. Push your branch and open a PR targeting `develop`.
3. Use a Draft PR for WIP; convert to ready when reviewable.
4. PR requirements:
   - CI checks green
   - At least 1 approval (2 for risky infra changes)
   - Branch is up-to-date with `develop` (use the 'Update branch' button or rebase locally)
5. Merge strategy: use **Squash and merge** to keep `develop` history concise (or `Rebase and merge` if you prefer linear history). Apply one strategy consistently.

## PR Checklist (add to PR description)

- [ ] Linked to an issue / short description provided
- [ ] Tests added or manual verification steps provided
- [ ] CI passed
- [ ] Branch rebased on `develop` and up-to-date
- [ ] At least one reviewer assigned

## Working with long-lived feature branches

If you are working on an existing long-lived `feature/*` branch, keep changes split into small PRs where possible, rebase frequently onto `develop`, and use feature flags to keep incomplete work from affecting deployments. See `docs/GITFLOW.md` for details.

## Running tests & linters

Run the project's test suite and linters locally before opening a PR. If no test scripts exist, include manual test steps in the PR description.

## Contact

If you're unsure about the process, tag a maintainer in the repository or open an issue describing your question.
