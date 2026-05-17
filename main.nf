nextflow.enable.dsl=2

/*
  MinION isolate assembly + QC + reference-aware QUAST
  Repository version prepared for GitHub distribution.

  Notes
  -----
  - This workflow is path-agnostic by design. Prefer supplying paths with CLI
    parameters or a user-specific config file instead of editing this script.
  - The Medaka model is currently pinned to a user-selected model that matched
    the observed MinION setup during development.
  - Raven parameters reflect the Galaxy workflow prototype and are kept explicit
    here for traceability. Benchmarking against the Galaxy workflow confirmed
    result parity for the validated inputs.
*/

params.input            = 'data/*.fastq.gz'
params.ref              = null
params.outdir           = 'results'
params.nanofilt_q       = 10
params.nanofilt_minlen  = 1000
params.medaka_model     = 'r941_min_sup_g507'

/* Raven parameters from the Galaxy workflow */
params.raven_frequency        = 0.001
params.raven_gap              = -4
params.raven_identity         = 0.0
params.raven_kmax_overlaps    = 32
params.raven_kmer_len         = 15
params.raven_match            = 3
params.raven_min_unitig_size  = 9999
params.raven_mismatch         = -5
params.raven_polishing_rounds = 2
params.raven_window_len       = 5

/* QUAST parameters */
params.quast_threads = 4

// ----------------------------
// Validation helpers
// ----------------------------

def check_params() {
    if( !params.ref ) {
        error "Please provide a reference FASTA with --ref or in a user config file."
    }
}

// ----------------------------
// Processes
// ----------------------------

process NANOPLOT_PREFILTER {
    tag "$sample_id"
    publishDir "${params.outdir}/prefilter_qc", mode: 'copy'

    input:
    tuple val(sample_id), path(reads)

    output:
    tuple val(sample_id), path(reads), emit: passthrough
    path("${sample_id}.prefilter.html"), emit: html
    path("${sample_id}.prefilter_nanostats.txt"), emit: stats

    script:
    """
    set -euo pipefail
    mkdir -p nanoplot_out

    NanoPlot \
      --fastq ${reads} \
      --outdir nanoplot_out \
      --prefix ${sample_id}.prefilter \
      --tsv_stats \
      --loglength

    html_file=\$(find nanoplot_out -maxdepth 1 -type f -name "*.html" | head -n 1)
    stats_file=\$(find nanoplot_out -maxdepth 1 -type f -name "*NanoStats.txt" | head -n 1)

    if [ -z "\$html_file" ] || [ -z "\$stats_file" ]; then
        echo "NanoPlot prefilter output missing"
        ls -R nanoplot_out
        exit 1
    fi

    cp "\$html_file" ${sample_id}.prefilter.html
    cp "\$stats_file" ${sample_id}.prefilter_nanostats.txt
    """
}

process JOIN_NANOSTATS_PREFILTER {
    publishDir "${params.outdir}/prefilter_qc_summary", mode: 'copy'

    input:
    path(stats_files)

    output:
    path('prefilter_nanostats_summary.tsv')

    script:
    """
    set -euo pipefail
    python ${projectDir}/bin/join_nanostats_summary.py \
      --pattern '*.prefilter_nanostats.txt' \
      --output prefilter_nanostats_summary.tsv
    """
}

process NANOFILT {
    tag "$sample_id"
    publishDir "${params.outdir}/filtered_reads", mode: 'copy'

    input:
    tuple val(sample_id), path(reads)

    output:
    tuple val(sample_id), path("${sample_id}.filtered.fastq.gz"), emit: reads
    path("${sample_id}.nanofilt.log"), emit: log

    script:
    def cat_cmd = reads.name.endsWith('.gz') ? 'zcat' : 'cat'
    """
    set -euo pipefail
    ${cat_cmd} ${reads} | \
      NanoFilt -q ${params.nanofilt_q} -l ${params.nanofilt_minlen} \
      2> ${sample_id}.nanofilt.log | gzip > ${sample_id}.filtered.fastq.gz
    """
}

process NANOPLOT_POSTFILTER {
    tag "$sample_id"
    publishDir "${params.outdir}/postfilter_qc", mode: 'copy'

    input:
    tuple val(sample_id), path(reads)

    output:
    tuple val(sample_id), path(reads), emit: passthrough
    path("${sample_id}.postfilter.html"), emit: html
    path("${sample_id}.postfilter_nanostats.txt"), emit: stats

    script:
    """
    set -euo pipefail
    mkdir -p nanoplot_out

    NanoPlot \
      --fastq ${reads} \
      --outdir nanoplot_out \
      --prefix ${sample_id}.postfilter \
      --tsv_stats

    html_file=\$(find nanoplot_out -maxdepth 1 -type f -name "*.html" | head -n 1)
    stats_file=\$(find nanoplot_out -maxdepth 1 -type f -name "*NanoStats.txt" | head -n 1)

    if [ -z "\$html_file" ] || [ -z "\$stats_file" ]; then
        echo "NanoPlot postfilter output missing"
        ls -R nanoplot_out
        exit 1
    fi

    cp "\$html_file" ${sample_id}.postfilter.html
    cp "\$stats_file" ${sample_id}.postfilter_nanostats.txt
    """
}

process JOIN_NANOSTATS_POSTFILTER {
    publishDir "${params.outdir}/postfilter_qc_summary", mode: 'copy'

    input:
    path(stats_files)

    output:
    path('postfilter_nanostats_summary.tsv')

    script:
    """
    set -euo pipefail
    python ${projectDir}/bin/join_nanostats_summary.py \
      --pattern '*.postfilter_nanostats.txt' \
      --output postfilter_nanostats_summary.tsv
    """
}

process RAVEN_ASSEMBLY {
    tag "$sample_id"
    publishDir "${params.outdir}/raven", mode: 'copy'
    cpus 4

    input:
    tuple val(sample_id), path(reads)

    output:
    tuple val(sample_id), path("${sample_id}.raven.fasta"), emit: fasta
    tuple val(sample_id), path("${sample_id}.raven.gfa"), emit: gfa

    script:
    """
    set -euo pipefail

    raven \
      --threads ${task.cpus} \
      --graphical-fragment-assembly ${sample_id}.raven.gfa \
      --frequency ${params.raven_frequency} \
      --gap ${params.raven_gap} \
      --identity ${params.raven_identity} \
      --kMaxNumOverlaps ${params.raven_kmax_overlaps} \
      --kmer-len ${params.raven_kmer_len} \
      --match ${params.raven_match} \
      --min-unitig-size ${params.raven_min_unitig_size} \
      --mismatch ${params.raven_mismatch} \
      --polishing-rounds ${params.raven_polishing_rounds} \
      --window-len ${params.raven_window_len} \
      ${reads} > ${sample_id}.raven.fasta

    test -s ${sample_id}.raven.fasta
    test -s ${sample_id}.raven.gfa
    """
}

process DRAFT_ASSEMBLY_STATS {
    tag "$sample_id"
    publishDir "${params.outdir}/assembly_stats", mode: 'copy'

    input:
    tuple val(sample_id), path(fasta)

    output:
    path("${sample_id}.draft.assembly_stats.tsv"), emit: tsv

    script:
    """
    set -euo pipefail
    assembly-stats -t ${fasta} > ${sample_id}.draft.assembly_stats.tsv
    test -s ${sample_id}.draft.assembly_stats.tsv
    """
}

process MEDAKA_CONSENSUS {
    tag "$sample_id"
    publishDir "${params.outdir}/medaka", mode: 'copy'
    cpus 4

    input:
    tuple val(sample_id), path(reads), path(draft)

    output:
    tuple val(sample_id), path("${sample_id}.medaka/consensus.fasta"), emit: consensus
    path("${sample_id}.medaka"), emit: medaka_dir

    script:
    """
    set -euo pipefail

    medaka_consensus \
      -i ${reads} \
      -d ${draft} \
      -o ${sample_id}.medaka \
      -t ${task.cpus} \
      -m ${params.medaka_model}

    test -s ${sample_id}.medaka/consensus.fasta
    """
}

process POLISHED_ASSEMBLY_STATS {
    tag "$sample_id"
    publishDir "${params.outdir}/assembly_stats", mode: 'copy'

    input:
    tuple val(sample_id), path(fasta)

    output:
    path("${sample_id}.polished.assembly_stats.tsv"), emit: tsv

    script:
    """
    set -euo pipefail
    assembly-stats -t ${fasta} > ${sample_id}.polished.assembly_stats.tsv
    test -s ${sample_id}.polished.assembly_stats.tsv
    """
}

process QUAST_ASSEMBLY_QC {
    tag "$sample_id"
    publishDir "${params.outdir}/quast", mode: 'copy'
    cpus 4

    input:
    tuple val(sample_id), path(assembly), path(reads), path(ref)

    output:
    path("${sample_id}.quast/report.tsv"), emit: tsv
    path("${sample_id}.quast/report.html"), emit: html
    path("${sample_id}.quast"), emit: quast_dir

    script:
    """
    set -euo pipefail

    quast.py \
      ${assembly} \
      -o ${sample_id}.quast \
      -r ${ref} \
      --nanopore ${reads} \
      --circos \
      --threads ${task.cpus}

    test -s ${sample_id}.quast/report.tsv
    test -s ${sample_id}.quast/report.html
    test -s ${sample_id}.quast/circos/circos.png
    """
}

// ----------------------------
// Workflow graph
// ----------------------------

workflow {
    check_params()

    def ref_file = file(params.ref, checkIfExists: true)

    reads_ch = Channel
        .fromPath(params.input, checkIfExists: true)
        .map { f ->
            def sid = f.baseName.replaceFirst(/\.fastq$/, '').replaceFirst(/\.fq$/, '')
            sid = sid.replaceFirst(/\.gz$/, '')
            tuple(sid, f)
        }

    pre_qc             = NANOPLOT_PREFILTER(reads_ch)
    prefilter_summary  = JOIN_NANOSTATS_PREFILTER(pre_qc.stats.collect())

    filt               = NANOFILT(reads_ch)
    post_qc            = NANOPLOT_POSTFILTER(filt.reads)
    postfilter_summary = JOIN_NANOSTATS_POSTFILTER(post_qc.stats.collect())

    raven              = RAVEN_ASSEMBLY(filt.reads)
    draft_qc           = DRAFT_ASSEMBLY_STATS(raven.fasta)

    medaka_in          = filt.reads.join(raven.fasta)
    medaka             = MEDAKA_CONSENSUS(medaka_in)

    polished_qc        = POLISHED_ASSEMBLY_STATS(medaka.consensus)

    quast_in           = medaka.consensus
                           .join(filt.reads)
                           .map { sid, assembly, reads -> tuple(sid, assembly, reads, ref_file) }

    quast              = QUAST_ASSEMBLY_QC(quast_in)
}
