# MinION isolate assembly + QC + reference comparison

This repository contains a **Nextflow DSL2** workflow for demultiplexed MinION isolate reads. It runs read QC, read filtering, draft assembly, polishing, assembly statistics, and QUAST reference comparison with Circos plots.

The workflow was adapted from a Galaxy workflow and validated against the original Galaxy run. For the benchmarked inputs, both workflows produced matching outputs, including the Raven draft assemblies.

## Who This Is For

This workflow is useful if you have:

- demultiplexed MinION FASTQ or FASTQ.GZ reads
- one isolate or sample per FASTQ file
- a reference FASTA for spike-in, control, or assembly comparison
- a local Linux, WSL, or macOS environment with Nextflow and Conda/Mamba

The workflow was validated using an *E. coli* BL21 spike-in/control reference, but you can provide any appropriate reference FASTA with `--ref`.

## What The Workflow Does

- raw-read QC with **NanoPlot**
- read filtering with **NanoFilt**
- post-filter QC with **NanoPlot**
- joined NanoStats summary tables across all samples before and after filtering
- draft assembly with **Raven**
- draft assembly summary statistics with **assembly-stats**
- polishing with **Medaka**
- polished assembly summary statistics with **assembly-stats**
- assembly evaluation against a supplied reference FASTA with **QUAST**
- QUAST **Circos** plot generation for each sample

## Quick Start

```bash
git clone https://github.com/dfplazag/minion-nextflow-assembly-qc.git
cd minion-nextflow-assembly-qc

mamba env create -f envs/environment.yml
mamba activate minion-nf

mkdir -p data refs results

nextflow run main.nf \
  --input "data/*.fastq.gz" \
  --ref "refs/BL21_reference.fasta" \
  --outdir results
```

Use `"data/*.fastq"` instead of `"data/*.fastq.gz"` if your reads are not compressed.

## Inputs

| Parameter | What it means | Example |
| --- | --- | --- |
| `--input` | FASTQ or FASTQ.GZ input glob for demultiplexed MinION reads | `"data/*.fastq.gz"` |
| `--ref` | Reference FASTA for spike-in, control, or assembly comparison | `refs/BL21_reference.fasta` |
| `--outdir` | Output folder for published results | `results` |

The reference FASTA is required because QUAST uses it for assembly comparison and Circos plot generation.

## Recommended Folder Layout

For routine local use, keep active workflow runs in the Linux/WSL filesystem and archive final outputs elsewhere after the run finishes.

```text
minion-nextflow-assembly-qc/
|-- data/      # FASTQ/FASTQ.GZ files copied into the working folder
|-- refs/      # reference FASTA, for example BL21_reference.fasta
|-- results/   # published workflow outputs
|-- work/      # Nextflow intermediate work directory
|-- main.nf
|-- nextflow.config
`-- envs/
```

For WSL users, avoid running directly from Windows-mounted paths such as `C:\...`, `/mnt/c/...`, Google Drive, or OneDrive when possible. These paths can be slower and more fragile for bioinformatics tools. A good pattern is:

1. clone or copy the repository into a Linux-side folder
2. copy FASTQ files into `data/`
3. copy the reference genome into `refs/`
4. run the workflow
5. copy `results/` back to Google Drive, OneDrive, or another shared folder for storage

## Outputs At A Glance

| Folder | Contents |
| --- | --- |
| `results/prefilter_qc/` | Raw-read NanoPlot reports and NanoStats files |
| `results/prefilter_qc_summary/` | Joined pre-filter NanoStats summary table |
| `results/filtered_reads/` | Filtered FASTQ.GZ files and NanoFilt logs |
| `results/postfilter_qc/` | Post-filter NanoPlot reports and NanoStats files |
| `results/postfilter_qc_summary/` | Joined post-filter NanoStats summary table |
| `results/raven/` | Raven draft assemblies and GFA files |
| `results/assembly_stats/` | Draft and polished assembly statistics |
| `results/medaka/` | Medaka polished consensus output directories |
| `results/quast/` | QUAST reports, HTML summaries, and Circos plots |

Important QUAST files include:

- `report.tsv`
- `report.html`
- `circos/circos.png`
- `circos/legend.txt`

## Important Notes

### Validation Status

Benchmarking against the original Galaxy workflow confirmed that both workflows produce the exact same results for the validated run. The earlier Raven parity investigation is resolved.

For future regression checks, the most useful files to compare are:

- `results/raven/*.raven.fasta`
- `results/raven/*.raven.gfa`
- `results/medaka/*/consensus.fasta`
- `results/quast/*/report.tsv`
- `results/quast/*/circos/circos.png`

### Medaka Model

The default Medaka model is set in `main.nf`:

```groovy
params.medaka_model = 'r941_min_sup_g507'
```

Check that this model matches your sequencing chemistry and basecalling model. If needed, override it at runtime:

```bash
nextflow run main.nf \
  --input "data/*.fastq.gz" \
  --ref "refs/BL21_reference.fasta" \
  --outdir results \
  --medaka_model <model_name>
```

### What This Workflow Does Not Do

This workflow does not:

- basecall raw signal files
- demultiplex POD5 or FAST5 files
- download reference genomes automatically
- choose the Medaka model automatically

Start with demultiplexed FASTQ or FASTQ.GZ files and provide the reference FASTA yourself.

## Workflow Diagram

```mermaid
flowchart LR
    A[Input FASTQ files] --> B[NANOPLOT_PREFILTER]
    B --> C[JOIN_NANOSTATS_PREFILTER]
    A --> D[NANOFILT]
    D --> E[NANOPLOT_POSTFILTER]
    E --> F[JOIN_NANOSTATS_POSTFILTER]
    D --> G[RAVEN_ASSEMBLY]
    G --> H[DRAFT_ASSEMBLY_STATS]
    D --> I[MEDAKA_CONSENSUS]
    G --> I
    I --> J[POLISHED_ASSEMBLY_STATS]
    I --> K[QUAST_ASSEMBLY_QC + CIRCOS]
    D --> K
    L[Reference FASTA] --> K
```

## Prerequisites

This repository assumes you already have:

- WSL/Ubuntu on Windows, Linux, or macOS
- Java
- Nextflow
- Mamba or Conda

The workflow tools are listed in `envs/environment.yml`.

Create the environment:

```bash
mamba env create -f envs/environment.yml
mamba activate minion-nf
```

If the environment already exists and you want to update it:

```bash
mamba env update -f envs/environment.yml --prune
mamba activate minion-nf
```

## Running The Workflow

The simplest approach is to pass paths on the command line:

```bash
nextflow run main.nf \
  --input "data/*.fastq.gz" \
  --ref "refs/BL21_reference.fasta" \
  --outdir results
```

You can resume a failed or interrupted run without recomputing successful steps:

```bash
nextflow run main.nf \
  --input "data/*.fastq.gz" \
  --ref "refs/BL21_reference.fasta" \
  --outdir results \
  -resume
```

You can also use a local config file for user-specific paths. Copy the template:

```bash
cp conf/user_paths.template.config conf/user_paths.config
```

Then edit `conf/user_paths.config`:

```groovy
params {
  input  = '/home/yourname/minion-nextflow-assembly-qc/data/*.fastq.gz'
  ref    = '/home/yourname/minion-nextflow-assembly-qc/refs/BL21_reference.fasta'
  outdir = '/home/yourname/minion-nextflow-assembly-qc/results'
}
```

Run with:

```bash
nextflow run main.nf -c conf/user_paths.config
```

For most users, command-line parameters are clearer and easier to share in notes.

## Windows + WSL + Google Drive Workflow

This pattern is recommended for Windows users who store sequencing data in Google Drive or another Windows-side folder.

### 1. Choose A Linux-Side Project Directory

```bash
mkdir -p ~/minion-nextflow-assembly-qc
cd ~/minion-nextflow-assembly-qc
```

### 2. Clone The Repository

```bash
git clone https://github.com/dfplazag/minion-nextflow-assembly-qc.git .
```

### 3. Create Working Folders

```bash
mkdir -p data refs results
```

### 4. Copy FASTQ Files Into `data/`

Example for gzipped reads stored in Google Drive:

```bash
cp "/mnt/c/Users/<WINDOWS_USERNAME>/My Drive/<PROJECT_ROOT>/data"/*.fastq.gz data/
```

Example for uncompressed reads:

```bash
cp "/mnt/c/Users/<WINDOWS_USERNAME>/My Drive/<PROJECT_ROOT>/data"/*.fastq data/
```

### 5. Copy The Reference FASTA Into `refs/`

```bash
cp "/mnt/c/Users/<WINDOWS_USERNAME>/My Drive/<PROJECT_ROOT>/refs/BL21_reference.fasta" refs/
```

### 6. Verify Inputs

```bash
ls -lh data
ls -lh refs
```

### 7. Run The Workflow

```bash
mamba activate minion-nf

nextflow run main.nf \
  --input "data/*.fastq.gz" \
  --ref "refs/BL21_reference.fasta" \
  --outdir results
```

### 8. Export Final Results Back To Google Drive

```bash
mkdir -p "/mnt/c/Users/<WINDOWS_USERNAME>/My Drive/<PROJECT_ROOT>/Nextflow_results"
cp -r results/* "/mnt/c/Users/<WINDOWS_USERNAME>/My Drive/<PROJECT_ROOT>/Nextflow_results/"
cp -v .nextflow.log "/mnt/c/Users/<WINDOWS_USERNAME>/My Drive/<PROJECT_ROOT>/Nextflow_results/" 2>/dev/null || true
```

## Inspecting Results Quickly

List all published files:

```bash
find results -type f
```

Open the Linux project folder from Windows Explorer:

```bash
explorer.exe .
```

Open only the results folder:

```bash
explorer.exe results
```

The same folder is also available from Windows at a path like:

```text
\\wsl$\Ubuntu\home\yourname\minion-nextflow-assembly-qc\results
```

## Using This Repo With AI Coding Apps

Open the repository from the project root in the OpenAI Codex app or Claude Code. Use the app to inspect commands, run checks, and troubleshoot failures, while keeping large sequencing data out of Git history.

Useful prompts:

```text
Inspect this repository and tell me the exact Nextflow command to run. My reads are in data/*.fastq.gz, the reference genome is refs/BL21_reference.fasta, and outputs should go to results/.
```

```text
Run the workflow from this repository, explain any failure in plain language, and use -resume after fixing the issue.
```

```text
After the workflow finishes, summarize the main output folders, confirm that QUAST report.tsv files exist, and confirm that QUAST Circos plots were created under results/quast/.
```

Tips:

- Ask the AI app to inspect the repository before editing `main.nf`.
- Paste absolute paths when your data are outside the repository.
- Keep raw FASTQ files, reference FASTA files, `work/`, and `results/` out of Git unless you intentionally want to publish them.
- When comparing against Galaxy, ask the AI app to compare Raven FASTA/GFA, Medaka consensus FASTA, QUAST reports, and Circos plots sample by sample.

## Troubleshooting

### The Workflow Stops And Says A Process Failed

Check the Nextflow log:

```bash
tail -n 100 .nextflow.log
```

Then inspect the process work directory mentioned in the error.

### I Want To See The Exact Command Nextflow Ran

In the relevant `work/<hash>/` directory:

```bash
cat .command.sh
cat .command.out
cat .command.err
```

### I Want To Continue Without Recomputing Successful Steps

Use `-resume`:

```bash
nextflow run main.nf \
  --input "data/*.fastq.gz" \
  --ref "refs/BL21_reference.fasta" \
  --outdir results \
  -resume
```

### I Want To Start Again From Scratch

This removes local workflow outputs and intermediate files, so use it carefully:

```bash
rm -rf work results .nextflow*
```

Then rerun the workflow.

## Repository Contents

```text
minion-nextflow-assembly-qc/
|-- .github/workflows/repo-checks.yml
|-- bin/
|   `-- join_nanostats_summary.py
|-- conf/
|   `-- user_paths.template.config
|-- docs/
|   |-- publish_to_github.md
|   `-- repo_structure.md
|-- envs/
|   `-- environment.yml
|-- CHANGELOG.md
|-- CONTRIBUTING.md
|-- LICENSE
|-- README.md
|-- main.nf
`-- nextflow.config
```

Useful supporting files:

- `envs/environment.yml`: Conda/Mamba environment definition
- `conf/user_paths.template.config`: optional template for local paths
- `CHANGELOG.md`: release history
- `CONTRIBUTING.md`: contribution guidance
- `docs/publish_to_github.md`: maintainer-oriented publishing notes
- `.github/workflows/repo-checks.yml`: lightweight repository checks

## License And Feedback

This repository is released under the MIT license.

Issues, suggestions, and example use cases from other MinION users are welcome through GitHub issues or pull requests.
