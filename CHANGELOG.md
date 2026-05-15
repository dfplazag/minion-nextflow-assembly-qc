# Changelog

All notable changes to this repository will be documented in this file.

The format follows a simple Keep-a-Changelog style.

## [0.3.0] - 2026-05-15

### Added
- QUAST now runs with `--circos` and checks that `circos/circos.png` is produced for each sample.

### Changed
- README now documents Circos plots as part of the QUAST output.
- README validation status now reflects benchmarked parity with the original Galaxy workflow.

### Notes
- Benchmarking confirmed that the Galaxy and Nextflow workflows produce the exact same results for the validated run.

## [0.2.0] - 2026-05-03

### Added
- GitHub-ready repository packaging with a top-level `LICENSE`.
- `CHANGELOG.md` for release tracking.
- `.github/workflows/repo-checks.yml` for lightweight automated repository checks.
- `docs/publish_to_github.md` with step-by-step GitHub publishing instructions.
- `CONTRIBUTING.md` with guidance for edits and pull requests.

### Changed
- Repository structure prepared for direct upload to GitHub.
- README expanded to emphasize WSL/Linux working folders versus Google Drive archive folders.
- Workflow kept path-agnostic through CLI params and `conf/user_paths.template.config`.

### Notes
- Raven parity with Galaxy is still under investigation.
- Medaka model remains pinned to `r941_min_sup_g507` in the current repository version.

## [0.1.0] - 2026-05-03

### Added
- Initial GitHub-ready Nextflow workflow repository.
- `main.nf`, `nextflow.config`, `envs/environment.yml`, helper scripts, and documentation.
