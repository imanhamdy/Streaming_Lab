Branch protection recommendations for `develop`

This file documents recommended branch-protection settings and example commands to apply them to `develop` for the Streaming_Lab repository.

Recommended policy (summary):
- Protect `develop` (already protected in practice) and require:
  - Required status checks (CI) to pass and be up-to-date before merge
  - At least 1 approving review (2 for infra changes)
  - Dismiss stale reviews when new commits are pushed
  - Require branches to be up-to-date with `develop` before merging
  - Enforce linear history (optional)
  - Disallow force pushes and branch deletion
  - Enforce for admins (optional but recommended)

Required status checks (examples): replace these names with the workflow/job names used in your CI.
- `build` or `ci/build`
- `test` or `ci/test`
- `lint` or `ci/lint`

Example: apply protection via GitHub REST API (replace `GITHUB_TOKEN` with a token having `repo` scope).

```bash
export OWNER=imanhamdy
export REPO=Streaming_Lab
export GITHUB_TOKEN=ghp_xxx

curl -sS -X PUT \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/$OWNER/$REPO/branches/develop/protection \
  -d '{
    "required_status_checks": {
      "strict": true,
      "contexts": ["ci/build", "ci/test", "ci/lint"]
    },
    "enforce_admins": true,
    "required_pull_request_reviews": {
      "dismiss_stale_reviews": true,
      "require_code_owner_reviews": false,
      "required_approving_review_count": 1
    },
    "restrictions": null,
    "required_linear_history": true,
    "allow_force_pushes": false,
    "allow_deletions": false
  }'
```

Example: using `gh` CLI to set a couple of checks (requires `gh` >= 2.0 and authenticated):

```bash
gh api --method PUT /repos/$OWNER/$REPO/branches/develop/protection \
  -f required_status_checks='{"strict":true,"contexts":["ci/build","ci/test","ci/lint"]}' \
  -f enforce_admins=true \
  -f required_pull_request_reviews='{"dismiss_stale_reviews":true,"required_approving_review_count":1}' \
  -f required_linear_history=true \
  -f allow_force_pushes=false \
  -f allow_deletions=false
```

Notes & next steps:
- Replace `ci/build`, `ci/test`, `ci/lint` with the actual check names that appear in PR status checks after running your workflows.
- If you want CODEOWNER-based auto-review, add a `CODEOWNERS` file under `.github/` or `docs/` to define owners per path.
- Consider enabling `require_code_owner_reviews` for critical paths (`infra/`, `security/`).
- If you use protected release processes, require more approvals for merges to `main` than to `develop`.

If you want, I can:
- Generate a `CODEOWNERS` template for the repo,
- Draft a sample GitHub Actions `ci.yml` workflow (build/test/lint) to produce the required checks,
- Or produce the exact `curl`/`gh` command tailored to the real workflow names (I can read them if you want me to inspect `.github/workflows/`).
