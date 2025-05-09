process PURECN_COVERAGE {
    tag "$meta.id"
    label 'process_low'
    stageInMode "link"

    // WARN: Version information not provided by tool on CLI. Please update version string below when bumping container versions.
    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/17/171d9cdb3db28ca8a63d87dd514a97e92af353f35b8f2173173a3dc3bb801516/data':
        'community.wave.seqera.io/library/bioconductor-dnacopy_bioconductor-org.hs.eg.db_bioconductor-purecn_bioconductor-txdb.hsapiens.ucsc.hg19.knowngene_pruned:cc846801cfba58d6' }"


    input:
    tuple val(meta), path(bam), path(bai)
    path intervals

    output:
    tuple val(meta), path("*.txt.gz")      , emit: txt
    //Not generated when --skip-gc-norm is set
    tuple val(meta), path("*.png")         , emit: png         , optional: true
    tuple val(meta), path("*_loess_qc.txt"), emit: loess_qc_txt, optional: true
    tuple val(meta), path("*_loess.txt.gz"), emit: loess_txt   , optional: true
    path "versions.yml"                    , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def VERSION = '2.12.0' // WARN: Version information not provided by tool on CLI. Please update this string when bumping container versions.

    if (task.stageInMode != 'link') {
        error "purecn/coverage can not handle staging files with symlinks. Please change the stageInmode option to 'Link'"
    }

    """
    library_path=\$(Rscript -e 'cat(.libPaths(), sep = "\\n")')
    Rscript "\$library_path"/PureCN/extdata/Coverage.R \\
        --out-dir ./ \\
        --bam ${bam} \\
        --bai ${bai} \\
        --intervals ${intervals} \\
        $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        purecn: ${VERSION}
    END_VERSIONS
    """

    stub:
    def args         = task.ext.args                   ?: ''
    def prefix       = task.ext.prefix                 ?: "${meta.id}"
    def png          = args.contains("--skip-gc-norm") ? "" : "touch ${prefix}.png"
    def loess_qc_txt = args.contains("--skip-gc-norm") ? "" : "touch ${prefix}_loess_qc.txt"
    def loess_txt    = args.contains("--skip-gc-norm") ? "" : "echo | gzip > ${prefix}_loess.txt.gz"
    def VERSION = '2.12.0' // WARN: Version information not provided by tool on CLI. Please update this string when bumping container versions.

    if (task.stageInMode != 'link') {
        error "purecn/coverage can not handle staging files with symlinks. Please change the stageInmode option to 'Link'"
    }

    """
    echo | gzip > ${prefix}.txt.gz
    touch ${prefix}.bed
    ${png}
    ${loess_qc_txt}
    ${loess_txt}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        purecn: ${VERSION}
    END_VERSIONS
    """
}
