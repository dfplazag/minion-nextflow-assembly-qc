# Contributing

## Recommended editing workflow

1. Create a feature branch.
2. Make small, focused commits.
3. Update `README.md` and `CHANGELOG.md` when behavior changes.
4. Keep paths out of `main.nf` whenever possible.
5. Prefer user config files or CLI parameters for environment-specific paths.

## Path handling policy

Do not hard-code personal file paths in the repository.

Use one of these instead:

- CLI parameters:
  - `--input`
  - `--ref`
  - `--outdir`
- `conf/user_paths.template.config`

## Validation before pushing

At minimum, check:

- `python -m py_compile bin/join_nanostats_summary.py`
- `nextflow config -flat -c nextflow.config`
- that the repository structure still matches the README
