# Publishing this repository to GitHub

This guide explains how to create the repository in your GitHub account and push the local files.

## Option A: easiest method for a new empty GitHub repository

1. Sign in to GitHub in your browser.
2. Click the **+** icon in the upper-right corner.
3. Click **New repository**.
4. Enter a repository name, for example:
   - `minion-nextflow-assembly-qc`
5. Add an optional description.
6. Choose **Public** or **Private**.
7. Do **not** initialize with README, `.gitignore`, or license if you plan to push this prepared repository as-is.
8. Click **Create repository**.

## Then from WSL/Linux

```bash
cd /path/to/minion_nextflow_repo_v2
git init
git branch -M main
git add .
git commit -m "Initial commit: Nextflow workflow repository"
git remote add origin https://github.com/YOUR-USERNAME/YOUR-REPOSITORY.git
git push -u origin main
```

## Option B: upload through the GitHub web interface

This works for small repositories, but command-line Git is better for version history.

1. Create the repository on GitHub.
2. Open it.
3. Click **uploading an existing file** or **Add file**.
4. Drag the repository files and folders into the browser.
5. Commit the upload.

## Recommended practice

Use the command-line Git method if possible.
