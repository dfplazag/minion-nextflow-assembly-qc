# Repository structure

```text
minion_nextflow_repo_v2/
├── .github/
│   └── workflows/
│       └── repo-checks.yml
├── .gitignore
├── CHANGELOG.md
├── CONTRIBUTING.md
├── LICENSE
├── README.md
├── main.nf
├── nextflow.config
├── bin/
│   └── join_nanostats_summary.py
├── conf/
│   └── user_paths.template.config
├── docs/
│   ├── publish_to_github.md
│   └── repo_structure.md
└── envs/
    └── environment.yml
```

## Notes

- `main.nf` contains the workflow.
- `nextflow.config` contains default configuration.
- `conf/user_paths.template.config` is the place to add your own working-folder placeholders or personal paths.
- `.github/workflows/repo-checks.yml` is a lightweight CI workflow for repository checks.
