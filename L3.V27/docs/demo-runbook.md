# Demonstration runbook for Laboratory work 3

Use this document only after the code is already pushed to GitHub.

1. In GitHub settings enable Actions permissions for package publishing and set
   branch protection on `main`: require `lint` and `tests` before merge.
2. Start a temporary Ubuntu 24.04 target VM and run
   `sudo L3.V27/deploy/target-bootstrap.sh`.
3. Start a separate temporary Ubuntu 24.04 runner VM, run
   `sudo L3.V27/runner/install-runner-dependencies.sh`, then register the
   runner manually with the short-lived token from GitHub. Use label
   `lab3-runner`.
4. Set all GitHub Secrets listed in `github-configuration.md`; use the same
   database password value for `POSTGRES_PASSWORD` and `APP_DB_PASSWORD`.
5. Create a small documentation branch and PR. Wait for `lint` and `tests`,
   merge, record the success screenshot.
6. Create a separate failing branch following the mini-report. Record the
   blocked PR; do not merge it.
7. Create an annotated tag and push it. Record the CD jobs and download the
   coverage artifact.
8. Run one controlled verification failure, restore the configuration, then
   execute successful verification again.
9. Stop or remove the runner VM after the demonstration.
