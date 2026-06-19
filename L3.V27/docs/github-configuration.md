# GitHub configuration required outside the repository

The workflow files alone cannot change repository security settings, so make the
following settings in the GitHub web interface and record screenshots for the
mini-report.

1. **Actions permissions:** allow workflows to read repository contents and to
   write packages. The `image` job uses the automatic `GITHUB_TOKEN` only for
   GHCR.
2. **Package visibility:** make `ghcr.io/<owner>/mywebapp` public after the first
   successful build, or configure a pull credential on the target node. Do not
   commit personal access tokens.
3. **Branch protection for `main`:** require the `lint` and `tests` checks before
   merging a pull request. This setting is a GitHub repository setting, not a
   YAML file.
4. **Secrets:** create `TARGET_HOST`, `TARGET_USER`, `TARGET_SSH_KEY`,
   `POSTGRES_PASSWORD`, `APP_DB_PASSWORD`. `TARGET_USER` is normally `deployer`.
5. **Self-hosted runner:** register a temporary, separate Ubuntu 24.04 VM with
   label `lab3-runner`. The deploy job is intentionally reachable only from
   annotated tag pushes; it never runs for a pull request.

GitHub warns that self-hosted runners are risky for public repositories. Keeping
the runner temporary and using it only for tag-based deployments reduces the
exposure but does not turn it into a permanent public runner.
